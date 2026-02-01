// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
contract HelperConfig is Script {
    function getConfig()
        external
        pure
        returns (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint256 subscriptionId,
            uint32 callbackGasLimit
        )
    {
        entranceFee = 1e16;
        interval = 300;
        vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
        gasLane = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
        subscriptionId = 66721667118437083041874565051496272638130143289173869246391392137040530621461;
        callbackGasLimit = 40000;
    }
}
