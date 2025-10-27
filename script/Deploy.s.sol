// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/RebaseToken.sol";

/**
 * @title DeployRebaseToken
 * @dev Deployment script for RebaseToken contract
 */
contract DeployRebaseToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy RebaseToken with 1M initial supply
        RebaseToken token = new RebaseToken(
            "RebaseToken",
            "RBT", 
            18,
            1000000 * 1e18
        );
        
        vm.stopBroadcast();
        
        // Log deployment information
        console.log("RebaseToken deployed at:", address(token));
        console.log("Deployer:", deployer);
        console.log("Initial Supply:", token.totalSupply());
        console.log("Initial Index:", token.getIndex());
        console.log("Owner:", token.owner());
    }
}
