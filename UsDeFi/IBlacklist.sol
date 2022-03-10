/**
 * @title Interface Blacklist
 * @dev IBlacklist contract
 *
 * @author - <AUREUM VICTORIA GROUP>
 * for the Securus Foundation 
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

pragma solidity 0.6.12;

interface IBlacklist {
    function isBlacklisted(address _address) external view returns (bool);
}
