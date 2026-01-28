// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle Contract
 * @author Minner
 * @notice This contract is for creating a sample raffle
 * @dev it implements Chainlink VRFv2.5 and Chainlink Automation
 */
contract Raffle is VRFConsumerBaseV2Plus {
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

    error Raffle_NotEnoughEthSend();
    error Raffle_TransferFailed();

    event EnteredRaffle(address indexed player);

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
        if (msg.value < i_entrancefee) {
            revert Raffle_NotEnoughEthSend();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() public {
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }

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
    }

    /**Getter Function */

    function getEntranceFee() external view returns (uint256) {
        return i_entrancefee;
    }
}
