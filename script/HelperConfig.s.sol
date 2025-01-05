// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    /* VRF Mock Values */
    
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 1115511;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval; 
        address _vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;
    
    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId]._vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if(chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether, // 1e16
            interval: 30 seconds,
            _vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit: 500000
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // check to see if we have active network config
        if (localNetworkConfig._vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
        // Depoloy Mocks
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock();
        vm.stopBroadcast();


    }
}