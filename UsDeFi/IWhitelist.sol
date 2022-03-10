/**
 * @title Interface Whitelist
 * @dev IWhitelist contract
 *
 * @author - <AUREUM VICTORIA GROUP>
 * for the Securus Foundation 
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

pragma solidity 0.6.12;

interface IWhitelist {
    function isWhitelisted(address _user) external view returns (bool);

    function statusWhitelist() external view returns (bool);
}
