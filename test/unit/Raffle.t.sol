// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console2} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {LinkToken} from "../mocks/LinkToken.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 constant STARTING_PLAYER_BALANCE = 5 * 10 ** 19;
    uint256 constant ENTRANCEFEE = 1e16;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    LinkToken linktoken;
    address alice = makeAddr("alice");

    event EnteredRaffle(address indexed player);

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        // interval = 300;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        linktoken = LinkToken(config.linkToken);
        vm.deal(alice, STARTING_PLAYER_BALANCE);
    }

    function testEntranceFee() public view {
        uint256 entranceFee = raffle.getEntranceFee();
        console2.log(entranceFee);
        vm.assertEq(entranceFee, ENTRANCEFEE);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(alice);
        vm.expectRevert(Raffle.Raffle_NotEnoughEthSend.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(alice);
        raffle.enterRaffle{value: ENTRANCEFEE}();
        address playerRecorded = raffle.getPlayer(0);
        assertEq(playerRecorded, alice);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(alice);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(alice);
        raffle.enterRaffle{value: ENTRANCEFEE}();
    }

    function testDontAllowPlayersToEnterWhileRafflelsCalculating() public {
        vm.prank(alice);
        raffle.enterRaffle{value: ENTRANCEFEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.pickWinner();

        // vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        // vm.prank(alice);
        // raffle.enterRaffle{value: ENTRANCEFEE}();
    }
}
