// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.31;

import {Script, console} from "forge-std/Script.sol";

// All Zoo bridge tokens
import {Z} from "../src/bridge/zoo/Z.sol";
import {ZooETH} from "../src/bridge/zoo/ZETH.sol";
import {ZooBTC} from "../src/bridge/zoo/ZBTC.sol";
import {ZooUSD} from "../src/bridge/zoo/ZUSD.sol";
import {ZooLUX} from "../src/bridge/zoo/ZLUX.sol";
import {ZooSOL} from "../src/bridge/zoo/ZSOL.sol";
import {ZooTON} from "../src/bridge/zoo/ZTON.sol";
import {ZooBNB} from "../src/bridge/zoo/ZBNB.sol";
import {ZooPOL} from "../src/bridge/zoo/ZPOL.sol";
import {ZooCELO} from "../src/bridge/zoo/ZCELO.sol";
import {ZooFTM} from "../src/bridge/zoo/ZFTM.sol";
import {ZooAVAX} from "../src/bridge/zoo/ZAVAX.sol";
import {ZooADA} from "../src/bridge/zoo/ZADA.sol";
import {ZooBLAST} from "../src/bridge/zoo/ZBLAST.sol";
import {ZooXDAI} from "../src/bridge/zoo/ZXDAI.sol";
import {ZooNOT} from "../src/bridge/zoo/ZNOT.sol";

/**
 * @title DeployZooBridge
 * @notice Deploy all Zoo bridge tokens (Z-tokens) on Zoo subnet chains
 */
contract DeployZooBridge is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        console.log("=== Deploying Zoo Bridge Tokens ===");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerKey);

        // Core stablecoin
        Z z = new Z();
        console.log("Z:", address(z));

        // Major assets
        ZooETH zeth = new ZooETH();
        console.log("ZETH:", address(zeth));

        ZooBTC zbtc = new ZooBTC();
        console.log("ZBTC:", address(zbtc));

        ZooUSD zusd = new ZooUSD();
        console.log("ZUSD:", address(zusd));

        ZooLUX zlux = new ZooLUX();
        console.log("ZLUX:", address(zlux));

        ZooSOL zsol = new ZooSOL();
        console.log("ZSOL:", address(zsol));

        ZooTON zton = new ZooTON();
        console.log("ZTON:", address(zton));

        ZooBNB zbnb = new ZooBNB();
        console.log("ZBNB:", address(zbnb));

        ZooPOL zpol = new ZooPOL();
        console.log("ZPOL:", address(zpol));

        ZooCELO zcelo = new ZooCELO();
        console.log("ZCELO:", address(zcelo));

        ZooFTM zftm = new ZooFTM();
        console.log("ZFTM:", address(zftm));

        ZooAVAX zavax = new ZooAVAX();
        console.log("ZAVAX:", address(zavax));

        ZooADA zada = new ZooADA();
        console.log("ZADA:", address(zada));

        ZooBLAST zblast = new ZooBLAST();
        console.log("ZBLAST:", address(zblast));

        ZooXDAI zxdai = new ZooXDAI();
        console.log("ZXDAI:", address(zxdai));

        ZooNOT znot = new ZooNOT();
        console.log("ZNOT:", address(znot));

        vm.stopBroadcast();

        console.log("");
        console.log("=== ZOO BRIDGE TOKENS DEPLOYED ===");
        console.log("Total: 16 tokens");
    }
}
