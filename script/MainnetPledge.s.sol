// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../src/MainnetPledge.sol";

contract MainnetPledgeDeploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MainnetPledge pledge = new MainnetPledge();
        vm.stopBroadcast();
    }
}
