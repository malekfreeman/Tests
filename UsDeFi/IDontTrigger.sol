/**
 * @title Interface dont Trigger
 * @dev IDontTrigger contract
 *
 * @author - <AUREUM VICTORIA GROUP>
 * for the Securus Foundation 
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

pragma solidity 0.6.12;

interface IDontTrigger {
    function isDontTrigger(address _address) external view returns (bool);
}
