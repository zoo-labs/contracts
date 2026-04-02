// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.31;

import "forge-std/Test.sol";
import {ModelRegistry} from "../src/beluga/ModelRegistry.sol";
import {TrainingBounty} from "../src/beluga/TrainingBounty.sol";
import {LRC20} from "@luxfi/tokens/LRC20.sol";

/// @dev Minimal BLG mock for testing (native gas token is not ERC-20,
///      but the marketplace and bounty contracts use wrapped BLG).
contract MockBLG is LRC20 {
    constructor() LRC20("Beluga", "BLG") {
        _mint(msg.sender, 100_000_000 ether);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract BelugaTest is Test {
    ModelRegistry public registry;
    TrainingBounty public bounty;
    MockBLG public blg;

    address safe = address(this);
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        registry = new ModelRegistry();
        blg = new MockBLG();
        bounty = new TrainingBounty(address(blg));

        // Fund alice for bounties
        blg.mint(alice, 1_000_000 ether);
    }

    // -- ModelRegistry tests --

    function test_registerModel() public {
        bytes32 hash = keccak256("model-weights-v1");
        uint256 id = registry.register(hash, "ipfs://QmWeights", "ipfs://QmCard", 1e15);

        assertEq(id, 0);
        assertEq(registry.ownerOf(0), address(this));
        assertTrue(registry.isActive(0));

        (bytes32 h,,, uint256 price, uint256 inferences, bool active) = registry.models(0);
        assertEq(h, hash);
        assertEq(price, 1e15);
        assertEq(inferences, 0);
        assertTrue(active);
    }

    function test_registerMultipleModels() public {
        registry.register(keccak256("w1"), "ipfs://1", "ipfs://c1", 1e15);
        registry.register(keccak256("w2"), "ipfs://2", "ipfs://c2", 2e15);
        registry.register(keccak256("w3"), "ipfs://3", "ipfs://c3", 0);

        assertEq(registry.nextModelId(), 3);
        assertTrue(registry.isActive(2));
    }

    function test_updatePrice() public {
        registry.register(keccak256("w"), "ipfs://w", "ipfs://c", 1e15);
        registry.updatePrice(0, 5e15);

        (,,,uint256 price,,) = registry.models(0);
        assertEq(price, 5e15);
    }

    function test_deactivateModel() public {
        registry.register(keccak256("w"), "ipfs://w", "ipfs://c", 1e15);
        registry.deactivate(0);

        assertFalse(registry.isActive(0));
    }

    function test_revertEmptyHash() public {
        vm.expectRevert(ModelRegistry.EmptyWeightsHash.selector);
        registry.register(bytes32(0), "ipfs://w", "ipfs://c", 1e15);
    }

    function test_revertNotOwnerUpdate() public {
        registry.register(keccak256("w"), "ipfs://w", "ipfs://c", 1e15);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ModelRegistry.NotModelOwner.selector, 0, alice));
        registry.updatePrice(0, 5e15);
    }

    function test_recordInferences() public {
        registry.register(keccak256("w"), "ipfs://w", "ipfs://c", 1e15);
        registry.recordInferences(0, 100);

        (,,,, uint256 inferences,) = registry.models(0);
        assertEq(inferences, 100);
    }

    // -- TrainingBounty tests --

    function test_createBounty() public {
        vm.startPrank(alice);
        blg.approve(address(bounty), 10_000 ether);
        uint256 id = bounty.create(10_000 ether, block.timestamp + 7 days, 0, "ipfs://QmTask");
        vm.stopPrank();

        assertEq(id, 0);
        (address poster, uint256 amount,,,,) = bounty.bounties(0);
        assertEq(poster, alice);
        assertEq(amount, 10_000 ether);
    }

    function test_awardBounty() public {
        vm.startPrank(alice);
        blg.approve(address(bounty), 10_000 ether);
        bounty.create(10_000 ether, block.timestamp + 7 days, 0, "ipfs://QmTask");
        vm.stopPrank();

        uint256 bobBefore = blg.balanceOf(bob);
        bounty.award(0, bob);
        assertEq(blg.balanceOf(bob) - bobBefore, 10_000 ether);
    }

    function test_cancelExpiredBounty() public {
        vm.startPrank(alice);
        blg.approve(address(bounty), 5_000 ether);
        bounty.create(5_000 ether, block.timestamp + 1 days, 0, "ipfs://QmTask");
        vm.stopPrank();

        // Cannot cancel before deadline
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(TrainingBounty.DeadlineNotPassed.selector, 0));
        bounty.cancel(0);

        // Warp past deadline
        vm.warp(block.timestamp + 2 days);

        uint256 aliceBefore = blg.balanceOf(alice);
        vm.prank(alice);
        bounty.cancel(0);
        assertEq(blg.balanceOf(alice) - aliceBefore, 5_000 ether);
    }

    function test_revertDoubleAward() public {
        vm.startPrank(alice);
        blg.approve(address(bounty), 10_000 ether);
        bounty.create(10_000 ether, block.timestamp + 7 days, 0, "ipfs://QmTask");
        vm.stopPrank();

        bounty.award(0, bob);

        vm.expectRevert(abi.encodeWithSelector(TrainingBounty.BountyNotOpen.selector, 0));
        bounty.award(0, alice);
    }
}
