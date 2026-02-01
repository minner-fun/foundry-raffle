// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {HelperConfig} from "./HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";
// import {Raffle} from "../src/Raffle.sol";
import {Raffle} from "src/Raffle.sol"; // 可以直接这样导入，不用..的绝对路径

contract DeployRaffle is Script {
    function run() external returns (Raffle) {
        (Raffle raffle, HelperConfig helperConfig) = deployContract();
        return raffle;
    }

    function deployContract() internal returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
