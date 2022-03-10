/**
 * @title Interface Zero Fee
 * @dev IZeroFee contract
 *
 * @author - <AUREUM VICTORIA GROUP>
 * for the Securus Foundation 
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

pragma solidity 0.6.12;

interface IZeroFee {
    function isZeroFeeSender(address _address) external view returns (bool);

    function isZeroFeeRecipient(address _address) external view returns (bool);
}
