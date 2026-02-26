// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {HelperConfig} from "./HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";
// import {Raffle} from "../src/Raffle.sol";
import {Raffle} from "src/Raffle.sol"; // 可以直接这样导入，不用..的绝对路径
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.sol";
import {console2} from "forge-std/Console2.sol";


contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        (Raffle raffle, HelperConfig helperConfig) = deployContract();
        return (raffle, helperConfig);
    }

    function deployContract() internal returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            config.subscriptionId = createSubscription.createSubscription(
                config.vrfCoordinator
            );

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.linkToken
            );
        }
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
        console2.log("Raffle deployed vrf addr: ", config.vrfCoordinator);
        AddConsumer addConsumer = new AddConsumer();

        addConsumer.addConsumer(
            address(raffle),
            config.vrfCoordinator,
            config.subscriptionId
        );
        return (raffle, helperConfig);
    }
}
