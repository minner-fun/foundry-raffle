// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

/**
 * @title A sample Raffle Contract
 * @author Minner
 * @notice This contract is for creating a sample raffle
 * @dev it implements Chainlink VRFv2.5 and Chainlink Automation
 */
contract Raffle{

    uint256 private immutable I_ENTRANCEFEE;
    uint256 private immutable I_INTERVAL;
    address payable[] private s_players;
    
    uint256 private s_lastTimeStamp;
    error Raffle_NotEnoughEthSend();

    event EnteredRaffle(address indexed player);

    constructor(uint256 entranceFee, uint256 interval){
        I_ENTRANCEFEE = entranceFee;
        I_INTERVAL = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() public payable {
        if(msg.value < I_ENTRANCEFEE){
            revert Raffle_NotEnoughEthSend();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() public {
        if (block.timestamp - s_lastTimeStamp < I_INTERVAL){
            revert();
        }
    }

    /**Getter Function */

    function getEntranceFee() external view returns(uint256){
        return I_ENTRANCEFEE;
    }

}