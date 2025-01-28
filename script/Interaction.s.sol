// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script, console } from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkTocken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address _vrfCoordinator = helperConfig.getConfig()._vrfCoordinator;
        (uint256 subId,) = createSubscription(_vrfCoordinator);
        return (subId, _vrfCoordinator);
        
    }

    function createSubscription(address _vrfCoordinator) public returns (uint256, address) {
        console.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast();
        uint256 subId = (VRFCoordinatorV2_5Mock(_vrfCoordinator).createSubscription());
        vm.stopBroadcast();
        console.log("Your subscription id is: ", subId);
        console.log("Please update the subscription id in your HelperConfig.s.sol file");
        return (subId, _vrfCoordinator);
    }
    
    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address _vrfCoordinator = helperConfig.getConfig()._vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address link = helperConfig.getConfig().link;
        fundSubscription(_vrfCoordinator, subscriptionId, link);
    }

    function fundSubscription(address _vrfCoordinator, uint256 subscriptionId, address link) public {
        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", _vrfCoordinator);
        console.log("On ChainId: ", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(_vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(_vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }
    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address _vrfCoordinator = helperConfig.getConfig()._vrfCoordinator;
        addConsumer(subId, mostRecentlyDeployed, _vrfCoordinator);
    }

    function addConsumer(uint256 subId, address contractToAddVrf, address _vrfCoordinator) public {
        console.log("Adding consumer contract ", contractToAddVrf);
        console.log("To vrfCoordinator: ", _vrfCoordinator);
        console.log("On ChainId: ", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(_vrfCoordinator).addConsumer(subId, contractToAddVrf);
        vm.stopBroadcast();

    }


    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }



}