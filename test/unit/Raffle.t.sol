// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console2} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    // HelperConfig helperConfig;

    uint256 constant BALANCE = 5 * 10 ** 19;
    uint256 constant entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    address alice = makeAddr("alice");

    event EnteredRaffle(address indexed player);

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        raffle = deployRaffle.run();
        vm.deal(alice, BALANCE);
    }

    function testEntranceFee() public view {
        uint256 entranceFee = raffle.getEntranceFee();
        console2.log(entranceFee);
        vm.assertEq(entranceFee, ENTRANCEFEE);
    }

    function testRaffleRevertsWhenYouDontPayEnough()public{
        vm.prank(alice);
        vm.expectRevert(Raffle.Raffle_NotEnoughEthSend.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public{
        vm.prank(alice);
        raffle.enterRaffle{value: 0.5 ether}();
        address playerRecorded = raffle.getPlayer(0);
        assertEq(playerRecorded, alice);

    }

    function testEmitsEventOnEntrance() public{
        vm.prank(alice);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(alice);
        raffle.enterRaffle{value: 0.5 ether}();
    }

    function testDontAllowPlayersToEnterWhileRafflelsCalculation() public{
        vm.prank(alice);
        raffle.enterRaffle(value:ENTRANCEFEE);
        vm.warp(block.timestamp + 1)
    }

}
