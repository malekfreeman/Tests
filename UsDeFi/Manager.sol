/**
 * @title Fee Manager
 * @dev FeeManager contract
 *
 * @author - <AUREUM VICTORIA GROUP>
 * for the Securus Foundation
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./MinterRole.sol";
import "./IDontTrigger.sol";
import "./IWhitelist.sol";
import "./IBlacklist.sol";
import "./ISecurusProxy.sol";
import "./IZeroFee.sol";
import "./IReferrals.sol";
import "./SafeMath.sol";

contract Manager is Ownable {
    using SafeMath for uint256;

    /**
     * @dev outputs the external contracts.
     */
    IWhitelist public whitelist;
    IBlacklist public blacklist;
    IDontTrigger public dontTrigger;
    IZeroFee public zeroFee;
    IReferrals public referrals;
    ISecurusProxy public securusProxy;
    address public newSecurusProxyContract;

    /**
     * @dev outputs the proxy trigger variables.
     */
    bool public securusProxyTrigger; // is the proxy active or disabled
    uint256 public nextProxyTrigger; // After how many blocks you can trigger the Proxy again
    uint256 public nextProxyTriggerBlock; // can trigger Proxy when next block.timestamp is bigger than nextProxyTriggerBlock
    uint256 public proxyTriggerAmount; // can trigger Proxy when send Amount is bigger than this proxyTriggerAmount

    /**
     * @dev outputs the proxy Timelock variables.
     */
    uint256 public proxyBlockTimelock; // the timelock in blocks you have to wait after updating the proxy to set a new proxy contract on active
    uint256 public lastProxyTimelockBlock; // the last timelock block after the new proxy contract can be activated

    /**
     * @dev outputs the fee variables.
     */
    uint256 public fee;
    uint256 public refLevel1Fee;
    uint256 public refLevel2Fee;
    uint256 public refLevel3Fee;
    address public feeReceiver;
    address public basicRef;

    /**
     * @dev outputs the `freeMintSupply` variable.
     */
    uint256 public freeMintSupply;

    /**
     * @dev set the {fee} for transfers.
     *
     * how many fees should be taken from a transaction.
     *
     * Requirements:
     *
     * - only `owner` can update the `fee`
     * - fee can only be lower than 10%
     *
     */
    function setFee(uint256 _fee) public onlyOwner {
        require(_fee <= 1000, "too high");
        fee = _fee;
    }

    /**
     * @dev set the {fee} for ref level 1.
     *
     * how many ref level 1 fees should be taken from a fee.
     *
     * Requirements:
     *
     * - only `owner` can update the `fee`
     * - fee can only be lower than 100%
     *
     */
    function setRefLevel1Fee(uint256 _refLevel1Fee) public onlyOwner {
        require(_refLevel1Fee.add(refLevel2Fee).add(refLevel3Fee) <= 100, "too high");
        refLevel1Fee = _refLevel1Fee;
    }

    /**
     * @dev set the {fee} for ref level 2.
     *
     * how many ref level 2 fees should be taken from a fee.
     *
     * Requirements:
     *
     * - only `owner` can update the `fee`
     * - fee can only be lower than 100%
     *
     */
    function setRefLevel2Fee(uint256 _refLevel2Fee) public onlyOwner {
        require(_refLevel2Fee.add(refLevel1Fee).add(refLevel3Fee) <= 100, "too high");
        refLevel2Fee = _refLevel2Fee;
    }

    /**
     * @dev set the {fee} for ref level 3.
     *
     * how many ref level 3 fees should be taken from a fee.
     *
     * Requirements:
     *
     * - only `owner` can update the `fee`
     * - fee can only be lower than 100%
     *
     */
    function setRefLevel3Fee(uint256 _refLevel3Fee) public onlyOwner {
        require(_refLevel3Fee.add(refLevel1Fee).add(refLevel2Fee) <= 100 , "too high");
        refLevel3Fee = _refLevel3Fee;
    }

    /**
     * @dev set the {fee} for ref level 3.
     *
     * how many ref level 3 fees should be taken from a fee.
     *
     * Requirements:
     *
     * - only `owner` can update the `fee`
     * - fee can only be lower than 10%
     *
     */
    function setBasicRef(address _basicRef) public onlyOwner {
        basicRef = _basicRef;
    }

    /**
     * @dev set the {feeReceiver} for transfers.
     *
     * The `owner` decides which address the fee should get.
     *
     * Requirements:
     *
     * - only `owner` can update the `feeReceiver`
     */
    function setfeeReceiver(address _feeReceiver) public onlyOwner {
        feeReceiver = _feeReceiver;
    }

    /**
     * @dev set the {securusProxyTrigger} for transfers.
     *
     * The `owner` decides whether the `securusProxyTrigger` is activated or deactivated.
     *
     * Requirements:
     *
     * - only `owner` can update the `securusProxyTrigger`
     */
    function setSecurusProxyTrigger(bool _securusProxyTrigger)
        public
        onlyOwner
    {
        securusProxyTrigger = _securusProxyTrigger;
    }

    /**
     * @dev set the {proxyTriggerAmount} for the trigger.
     *
     * Says from which coin transfer size the trigger should be on.
     *
     * Requirements:
     *
     * - only `owner` can update the `proxyTriggerAmount`
     */
    function setproxyTriggerAmount(uint256 _proxyTriggerAmount)
        external
        onlyOwner
    {
        proxyTriggerAmount = _proxyTriggerAmount;
    }

    /**
     * @dev set the {nextProxyTrigger} for contract trigger.
     *
     * The owner decides after which blocktime the strategy may be executed again.
     *
     * Requirements:
     *
     * - only `owner` can update the `nextProxyTrigger`
     */
    function setNextProxyTrigger(uint256 _nextProxyTrigger) public onlyOwner {
        nextProxyTrigger = _nextProxyTrigger;
    }

    /**
     * @dev set the {freeMintSupply} that the minter can create new coins.
     *
     * The owner decides how many new coins may be created by the minter.
     *
     * Requirements:
     *
     * - only `owner` can update the `freeMintSupply`
     */
    function setFreeMintSupply(uint256 _freeMintSupply) public onlyOwner {
        freeMintSupply = _freeMintSupply;
    }

    /**
     * @dev set the {proxyBlockTimelock} to define block waiting times.
     *
     * This function ensures that functions cannot be executed immediately
     * but have to wait for a defined block time.
     *
     * Requirements:
     *
     * - only `owner` can update the proxyBlockTimelock
     * - proxyBlockTimelock can only be bigger than last proxyBlockTimelock
     * - proxyBlockTimelock must be lower than 30 days
     *
     */
    function setProxyBlockTimelock(uint256 _setProxyBlockTimelock)
        public
        onlyOwner
    {
        require(
            proxyBlockTimelock < _setProxyBlockTimelock,
            "SAFETY FIRST || proxyBlockTimelock can only be bigger than last blockTimelock"
        );
        require(
            _setProxyBlockTimelock <= 30 days,
            "SAFETY FIRST || proxyBlockTimelock greater than 30 days"
        );
        proxyBlockTimelock = _setProxyBlockTimelock;
    }

    /**
     * @dev Outputs the remaining time of the proxyBlockTimelock.
     *
     * How many blocks still have to pass to activate the new Proxy.
     */
    function checkRemainingProxyBlockTimelock() public view returns (uint256) {
        uint256 remainingProxyBlockTimelock = lastProxyTimelockBlock.sub(
            block.timestamp
        );

        return remainingProxyBlockTimelock;
    }

    /**
     * @dev Outputs the remaining time of the Proxy Trigger.
     *
     * How many blocks still have to pass until the next proxy trigger possibility.
     */
    function checkRemainingProxyTriggerBlocktime()
        public
        view
        returns (uint256)
    {
        uint256 remainingProxyTriggerBlocktime = nextProxyTriggerBlock.sub(
            block.timestamp
        );

        return remainingProxyTriggerBlocktime;
    }

    /**
     * @dev Sets `external smart contracts`.
     *
     * These functions serve to be flexible and to connect further automated systems
     * that will require an update in the long term.
     *
     * Requirements:
     *
     * - only `owner` can update the external smart contracts
     * - `external smart contracts` must be correct and work
     */
    function updateZeroFeeContract(address _ZeroFeeContract) public onlyOwner {
        zeroFee = IZeroFee(_ZeroFeeContract);
    }

    function updateDontTriggerContract(address _dontTriggerContract)
        public
        onlyOwner
    {
        dontTrigger = IDontTrigger(_dontTriggerContract);
    }

    function updateWhitelistContract(address _whitelistContract)
        public
        onlyOwner
    {
        whitelist = IWhitelist(_whitelistContract);
    }

    function updateBlacklistContract(address _blacklistContract)
        public
        onlyOwner
    {
        blacklist = IBlacklist(_blacklistContract);
    }

    function updateReferralsContract(address _referralsContract)
        public
        onlyOwner
    {
        referrals = IReferrals(_referralsContract);
    }

    /**
     * @dev Sets `external securus proxy smart contract`
     *
     * This function shows that the owner wants to update
     * the `securusProxyContract` and activates the `lastProxyTimelockBlock`.
     *
     * The new `securusProxyContract` is now shown to everyone
     * and people can make necessary decisions from it.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - only `owner` can update the external smart contracts
     * - `external smart contracts` must be correct and work
     */
    function updateSecurusProxyContract(address _securusProxyContract)
        public
        onlyOwner
    {
        newSecurusProxyContract = _securusProxyContract;
        lastProxyTimelockBlock = block.timestamp.add(proxyBlockTimelock);
    }

    /**
     * @dev Activate new `external Securus proxy smart contract`
     *
     * After the `lastProxyTimelockBlock` time has expired
     * The owner can now activate his submitted `external Securus proxy smart contract`
     * and reset the `proxyBlockTimelock` to 1 day.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - only `owner` can update the external smart contracts
     * - `external smart contracts` must be correct and work
     */
    function activateNewSecurusProxyContract() public onlyOwner {
        require(
            lastProxyTimelockBlock < block.timestamp,
            "SAFETY FIRST || safetyTimelock smaller than current block"
        );
        securusProxy = ISecurusProxy(newSecurusProxyContract);
        proxyBlockTimelock = 1 days; //Set the update time back to 1 day in case there is an error and you need to intervene quickly.
    }
}
