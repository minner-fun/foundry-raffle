// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console2} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {LinkToken} from "../mocks/LinkToken.sol";
import {Vm} from "forge-std/Vm.sol";

import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

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

    modifier raffleEntreAndTimePassed() {
        vm.prank(alice);
        raffle.enterRaffle{value: ENTRANCEFEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

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
        console2.log("test setUp vrf addr: ", vrfCoordinator);
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

    function testDontAllowPlayersToEnterWhileRafflelsCalculating() public raffleEntreAndTimePassed {
        raffle.pickWinner();

        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(alice);
        raffle.enterRaffle{value: ENTRANCEFEE}();
    }

    function testCheckUpkeepReturnFalseIfItHahNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public raffleEntreAndTimePassed {
        raffle.performUpkeep("");

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        vm.warp(block.timestamp + interval - 2);
        vm.roll(block.number + 1);

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepTrueWhenParametersGood() public raffleEntreAndTimePassed {
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public raffleEntreAndTimePassed {
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        vm.warp(block.timestamp + interval - 2);
        vm.roll(block.number + 1);

        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState raffleStatus = raffle.getRaffleStatus();

        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle_UpkeepNotNeeded.selector, 0, 0, raffleStatus));
        vm.prank(alice);
        raffle.performUpkeep("");
    }

    function testGetRaffleStatusShouldBeOpen() public {
        Raffle.RaffleState raffleStatus = raffle.getRaffleStatus();
        assertEq(uint256(raffleStatus), uint256(Raffle.RaffleState.OPEN));
    }

    function testGetRaffleStatusShouldBeCALCULATING() public raffleEntreAndTimePassed {
        raffle.performUpkeep("");

        Raffle.RaffleState raffleStatus = raffle.getRaffleStatus();
        assertEq(uint256(raffleStatus), uint256(Raffle.RaffleState.CALCULATING));
    }

    function testPerformUpkeepUpdatesRaffleStatusAndEmitsRequestId() public raffleEntreAndTimePassed {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleStatus();
        assert(uint256(requestId) > 0);
        console2.log("requestId: ", uint256(requestId));
        assert(uint256(raffleState) == 1);
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId)
        public
        raffleEntreAndTimePassed
        skipFork
    {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney(uint256 additionalEntrantsNum)
        public
        raffleEntreAndTimePassed
        skipFork
    {
        uint256 additionalEntrants = bound(additionalEntrantsNum, 1, 10000);
        uint256 startingIndex = 1;

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
            // Avoid precompile addresses (0x01..0x0b) which can fail on ETH transfer in tests.
            address player = address(uint160(i + 100));
            hoax(player, STARTING_PLAYER_BALANCE);
            raffle.enterRaffle{value: ENTRANCEFEE}();
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 expectedWinnerIndex =
            uint256(keccak256(abi.encode(uint256(requestId), uint256(0)))) % raffle.getNumberOfPlayers();
        address expectedWinner = raffle.getPlayer(expectedWinnerIndex);
        uint256 winnerStartingBalance = expectedWinner.balance;

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        address recentWinner = raffle.getRencentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleStatus();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = ENTRANCEFEE * (additionalEntrants + 1);

        assert(expectedWinner == recentWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}

// console2.log("recorded logs length:");
// console2.logUint(entries.length);

// for (uint256 i = 0; i < entries.length; i++) {
//     console2.log("---- log index ----");
//     console2.logUint(i);

//     console2.log("emitter:");
//     console2.logAddress(entries[i].emitter);

//     console2.log("topics length:");
//     console2.logUint(entries[i].topics.length);
//     for (uint256 j = 0; j < entries[i].topics.length; j++) {
//         console2.log("topic index:");
//         console2.logUint(j);
//         console2.logBytes32(entries[i].topics[j]);
//     }

//     console2.log("data:");
//     console2.logBytes(entries[i].data);
// }

// console2.log("requestId (topic[1] as bytes32):");
// console2.logBytes32(requestId);
// console2.log("requestId (topic[1] as uint256):");
// console2.logUint(uint256(requestId));
