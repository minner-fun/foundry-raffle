// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console2} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 constant BALANCE = 5 * 10 ** 19;

    address alice = makeAddr("alice");

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        vm.deal(alice, BALANCE);
    }

    function testEntranceFee() public view {
        uint256 entranceFee = raffle.getEntranceFee();
        console2.log(entranceFee);
        vm.assertEq(entranceFee, 1e16);
    }
}
