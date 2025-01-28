// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

/**
 * @title Unit Tests for Raffle Contract
 * @notice This contract contains all unit tests for the Raffle smart contract
 * @dev Uses Foundry's Test contract for testing utilities
 */
contract RaffleTest is Test {
    /* State Variables */
    Raffle public raffle;            // Instance of the Raffle contract we're testing
    HelperConfig public helperConfig;// Helper contract for network-specific configurations

    // Configuration variables that we'll get from HelperConfig
    uint256 entranceFee;            // Fee required to enter the raffle
    uint256 interval;               // Time interval between raffle draws
    address vrfCoordinator;         // Address of the VRF Coordinator
    bytes32 gasLane;               // Gas lane key hash for VRF
    uint256 subscriptionId;         // Chainlink VRF subscription ID
    uint32 callbackGasLimit;       // Gas limit for the VRF callback

    // Test user configuration
    address public PLAYER = makeAddr("player");  // Create a test address labeled "player"
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;  // Initial balance for test user

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    
    /**
     * @notice Set up function that runs before each test
     * @dev This function:
     * 1. Deploys a new instance of the Raffle contract
     * 2. Gets the network configuration (either local or testnet)
     * 3. Sets up all the configuration variables for testing
     */
    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        
        // Get the network config and set all our test variables
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config._vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit; 

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    /**
     * @notice Test that the raffle initializes in an OPEN state
     * @dev Verifies that when the contract is deployed, it starts in the OPEN state
     * allowing participants to enter
     */
    function test_RaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /**
     * @notice Test that the raffle reverts when the player doesn't pay enough
     * @dev Ensures that the contract rejects entries with insufficient funds
     */
    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    /**
     * @notice Test that the raffle records the player when they enter
     * @dev Ensures that the contract correctly records the player's address
     */
    function testRaffleRecordsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: entranceFee}();
        // Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    /**
     * @notice Test that entering the raffle emits an event
     * @dev Ensures that the contract correctly emits the RaffleEntered event
     */

    function testEnteringRaffleEmitsEvent() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        // Assert 
        raffle.enterRaffle{value: entranceFee}();
    }   

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number +1);
        raffle.performUpkeep("");
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

    }

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number +1);
        // Act 
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number +1);
        raffle.performUpkeep("");
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    // Challenge 
    // testCheckUpkeepReturnsFalseIfEnoughTimeHasPassed
    // testCheckUpkeepReturnsTrueWhenParametersAreGood

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasPassed() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number +1);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        // Arrange
        vm.warp(block.timestamp + interval - 1);
        vm.roll(block.number +1);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval - 1);
        vm.roll(block.number +1);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded);
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval +1);
        vm.roll(block.number + 1);
        // Act / Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
       uint256 currentBalance = 0;
       uint256 numPlayers = 0;
       Raffle.RaffleState rState = raffle.getRaffleState();
       // Act / Assert
       vm.expectRevert(
       abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
       );
      raffle.performUpkeep("");
    }

}
