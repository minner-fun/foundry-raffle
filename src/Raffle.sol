// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title A sample Raffle Contract
 * @author Minner
 * @notice This contract is for creating a sample raffle
 * @dev it implements Chainlink VRFv2.5 and Chainlink Automation
 */
contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    // Chainlink vrf Variables
    // VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entrancefee;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address payable[] private s_players;
    mapping(uint256=>address) public s_playersId;
    mapping(address=>uint256) public s_results;

    enum RaffleState{
        OPEN,
        CALCULATING
    }

    RaffleState private s_raffleState;

    error Raffle_NotEnoughEthSend();
    error Raffle_TransferFailed();
    error Raffle_RaffleNotOpen();
    error Raffle_UpkeepNotNeeded(uint256, uint256, uint256);
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed player);

    constructor(
        uint256 subscriptionId,
        bytes32 gasLane,
        uint256 entranceFee,
        uint256 interval,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) {
        i_entrancefee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() public payable {
        if (s_raffleState != RaffleState.OPEN){
            revert Raffle_RaffleNotOpen();
        }

        if (msg.value < i_entrancefee) {
            revert Raffle_NotEnoughEthSend();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }


    function checkUpkeep(
        bytes calldata /* checkData */
    )public view override returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        return (upkeepNeeded, bytes(""));

    }

    function performUpkeep(bytes calldata /* performData */) external override {
        
        // (bool upkeepNeeded, ) = checkUpkeep(bytes(""));

        // if (!upkeepNeeded){
        //     revert Raffle_UpkeepNotNeeded(
        //         address(this).balance,
        //         s_players.length,
        //         uint256(s_raffleState)
        //     );
        // }

        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords:NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        s_playersId[requestId] = msg.sender;
        s_results[msg.sender] = 1;
    }
    


    function pickWinner() public {
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CALCULATING;


        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords:NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        s_playersId[requestId] = msg.sender;
        s_results[msg.sender] = 1;

    }

    function fulfillRandomWords(
        uint256,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner = (randomWords[0] % s_players.length);
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        (bool success, ) = s_recentWinner.call{value:address(this).balance}("");
        if (!success){
            revert Raffle_TransferFailed();
        }
        s_players = new address payable[](0); // 长度为0的动态数组，注意(0)表示是的长度为0
        s_lastTimeStamp = block.timestamp;

        s_raffleState = RaffleState.OPEN;
        emit PickedWinner(winner);
    }

    /**Getter Function */

    function getEntranceFee() external view returns (uint256) {
        return i_entrancefee;
    }
}
