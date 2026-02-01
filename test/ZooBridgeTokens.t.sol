// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2025 Zoo Labs Foundation
pragma solidity ^0.8.31;

import "forge-std/Test.sol";
import "../src/bridge/zoo/ZETH.sol";
import "../src/bridge/zoo/ZBTC.sol";
import "../src/bridge/zoo/ZUSD.sol";

/**
 * @title ZooBridgeTokensTest
 * @notice Tests for Zoo MPC-controlled bridge tokens (Z* prefix)
 * @dev Tests cover admin-only minting/burning, role management, and transfers
 */
contract ZooBridgeTokensTest is Test {
    ZooETH public zeth;
    ZooBTC public zbtc;
    ZooUSD public zusd;

    address public deployer;
    address public admin;
    address public mpcBridge;
    address public user1;
    address public user2;
    address public attacker;

    event BridgeMint(address indexed account, uint amount);
    event BridgeBurn(address indexed account, uint amount);

    function setUp() public {
        deployer = address(this);
        admin = makeAddr("admin");
        mpcBridge = makeAddr("mpcBridge");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        attacker = makeAddr("attacker");

        zeth = new ZooETH();
        zbtc = new ZooBTC();
        zusd = new ZooUSD();

        zeth.grantAdmin(mpcBridge);
        zbtc.grantAdmin(mpcBridge);
        zusd.grantAdmin(mpcBridge);
    }

    /*//////////////////////////////////////////////////////////////
                            METADATA TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ZooTokenMetadata() public view {
        assertEq(zeth.name(), "Zoo ETH");
        assertEq(zeth.symbol(), "ZETH");
        assertEq(zeth.decimals(), 18);

        assertEq(zbtc.name(), "Zoo BTC");
        assertEq(zbtc.symbol(), "ZBTC");
        assertEq(zbtc.decimals(), 18);

        assertEq(zusd.name(), "Zoo Dollar");
        assertEq(zusd.symbol(), "ZUSD");
        assertEq(zusd.decimals(), 18);
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN ROLE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function test_DeployerHasAdminRole() public view {
        assertTrue(zeth.hasRole(zeth.DEFAULT_ADMIN_ROLE(), deployer));
    }

    function test_GrantAdminRole() public {
        zeth.grantAdmin(admin);
        assertTrue(zeth.hasRole(zeth.DEFAULT_ADMIN_ROLE(), admin));
    }

    function testRevert_GrantAdmin_Unauthorized() public {
        vm.prank(attacker);
        vm.expectRevert("LRC20B: caller is not admin");
        zeth.grantAdmin(admin);
    }

    /*//////////////////////////////////////////////////////////////
                        MINTING TESTS (ADMIN ONLY)
    //////////////////////////////////////////////////////////////*/

    function test_MintByAdmin() public {
        uint256 amount = 100e18;

        vm.prank(mpcBridge);
        zeth.mint(user1, amount);

        assertEq(zeth.balanceOf(user1), amount);
        assertEq(zeth.totalSupply(), amount);
    }

    function test_BridgeMintByAdmin() public {
        uint256 amount = 50e18;

        vm.expectEmit(true, false, false, true);
        emit BridgeMint(user1, amount);

        vm.prank(mpcBridge);
        bool success = zeth.bridgeMint(user1, amount);

        assertTrue(success);
        assertEq(zeth.balanceOf(user1), amount);
    }

    function testRevert_MintByNonAdmin() public {
        vm.prank(attacker);
        vm.expectRevert("LRC20B: caller is not admin");
        zeth.mint(user1, 100e18);
    }

    /*//////////////////////////////////////////////////////////////
                        BURNING TESTS (ADMIN ONLY)
    //////////////////////////////////////////////////////////////*/

    function test_BurnByAdmin() public {
        vm.prank(mpcBridge);
        zeth.mint(user1, 100e18);

        vm.prank(mpcBridge);
        zeth.burn(user1, 50e18);

        assertEq(zeth.balanceOf(user1), 50e18);
    }

    function test_BridgeBurnByAdmin() public {
        vm.prank(mpcBridge);
        zeth.mint(user1, 100e18);

        vm.expectEmit(true, false, false, true);
        emit BridgeBurn(user1, 60e18);

        vm.prank(mpcBridge);
        bool success = zeth.bridgeBurn(user1, 60e18);

        assertTrue(success);
        assertEq(zeth.balanceOf(user1), 40e18);
    }

    function testRevert_BurnByNonAdmin() public {
        vm.prank(mpcBridge);
        zeth.mint(user1, 100e18);

        vm.prank(attacker);
        vm.expectRevert("LRC20B: caller is not admin");
        zeth.burn(user1, 50e18);
    }

    /*//////////////////////////////////////////////////////////////
                        TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_TransferByUser() public {
        vm.prank(mpcBridge);
        zeth.mint(user1, 100e18);

        vm.prank(user1);
        zeth.transfer(user2, 40e18);

        assertEq(zeth.balanceOf(user1), 60e18);
        assertEq(zeth.balanceOf(user2), 40e18);
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_MintAmount(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < type(uint256).max / 2);

        vm.prank(mpcBridge);
        zeth.mint(user1, amount);

        assertEq(zeth.balanceOf(user1), amount);
    }

    function testFuzz_BurnAmount(uint256 mintAmount, uint256 burnAmount) public {
        vm.assume(mintAmount > 0);
        vm.assume(mintAmount < type(uint256).max / 2);
        vm.assume(burnAmount <= mintAmount);

        vm.startPrank(mpcBridge);
        zeth.mint(user1, mintAmount);
        zeth.burn(user1, burnAmount);
        vm.stopPrank();

        assertEq(zeth.balanceOf(user1), mintAmount - burnAmount);
    }

    /*//////////////////////////////////////////////////////////////
                    OWNER/DEPLOYER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_DeployerIsOwner() public view {
        assertEq(zeth.owner(), deployer);
    }

    function test_OwnerHasDefaultAdminRole() public view {
        assertTrue(zeth.hasRole(zeth.DEFAULT_ADMIN_ROLE(), deployer));
    }
}
