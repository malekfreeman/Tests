/**
 * @title Interface Referrals
 * @dev IReferrals contract
 *
 * @author - <AUREUM VICTORIA GROUP>
 * for the Securus Foundation 
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

pragma solidity 0.6.12;

interface IReferrals {
    function getSponsor(address account) external view returns (address);
}