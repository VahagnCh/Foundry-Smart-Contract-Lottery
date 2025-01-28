// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interaction.s.sol";

contract DeployRaffle is Script {
    function run() public {} 

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig= new HelperConfig();
        // local -> deploy mocks, get local config
        // sepolia -> get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config._vrfCoordinator) = createSubscription.createSubscription(config._vrfCoordinator);

            // Fund it
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config._vrfCoordinator, config.subscriptionId, config.link);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee, 
            config.interval, 
            config._vrfCoordinator, 
            config.gasLane, 
            config.subscriptionId, 
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        // Dont need to broadcast because we already have it in addConsumer function
        addConsumer.addConsumer(config.subscriptionId, address(raffle), config._vrfCoordinator);

        return (raffle, helperConfig);
    }

}



