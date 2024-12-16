// SPDX-License-Identifier: MIT

// Layout of Contract: 
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions


pragma solidity 0.8.19;


/**
 * @title A sample Raffle Contract
 * @author Vahagn Chavushyan
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */

contract Raffle {

    /* Errors */
    error Raffle__SendMoreToEnterRaffle();

    /* State Variables */
    address payable [] private s_players;
    uint256 private immutable i_entranceFee;

    /* Events */
    event RaffleEntered(address indexed player);
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }


    /* Functions */
    function enterRaffle() public payable {
        //require(msg.value >= i_entranceFee, "Not enough ETH sent"); This is not gas efficient
        if (msg.value < i_entranceFee) {
             revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function pickWinner() public {

    }

    /** Getter Functions */

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
} 