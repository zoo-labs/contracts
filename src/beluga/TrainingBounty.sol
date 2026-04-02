// SPDX-License-Identifier: BSD-3-Clause
// Copyright (C) 2026, Zoo Labs Foundation. All rights reserved.
pragma solidity ^0.8.31;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title TrainingBounty
/// @notice Post BLG bounties for model fine-tuning. Community submits results.
/// @dev Minimal escrow: poster deposits BLG, owner approves winner, BLG released.
///      No on-chain training verification -- that happens off-chain via benchmarks.
///      The owner (Safe multisig) arbitrates disputes.
contract TrainingBounty is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Status { Open, Claimed, Cancelled }

    struct Bounty {
        address poster;
        uint256 amount;
        uint256 deadline;
        uint256 modelId;       // ModelRegistry token ID for base model
        string  taskURI;       // IPFS URI describing the fine-tuning task
        Status  status;
    }

    IERC20 public immutable blg;

    mapping(uint256 => Bounty) public bounties;
    uint256 public nextBountyId;

    event BountyCreated(uint256 indexed bountyId, address indexed poster, uint256 amount, uint256 modelId);
    event BountyClaimed(uint256 indexed bountyId, address indexed winner, uint256 amount);
    event BountyCancelled(uint256 indexed bountyId);

    error BountyNotOpen(uint256 bountyId);
    error NotPoster(uint256 bountyId);
    error DeadlineNotPassed(uint256 bountyId);
    error ZeroAmount();
    error InvalidDeadline();

    constructor(address blgToken) Ownable(msg.sender) {
        blg = IERC20(blgToken);
    }

    /// @notice Create a training bounty with BLG escrow.
    /// @param amount BLG to escrow as reward
    /// @param deadline Unix timestamp after which poster can cancel
    /// @param modelId Base model token ID from ModelRegistry
    /// @param taskURI IPFS URI with fine-tuning task description
    function create(
        uint256 amount,
        uint256 deadline,
        uint256 modelId,
        string calldata taskURI
    ) external nonReentrant returns (uint256 bountyId) {
        if (amount == 0) revert ZeroAmount();
        if (deadline <= block.timestamp) revert InvalidDeadline();

        blg.safeTransferFrom(msg.sender, address(this), amount);

        bountyId = nextBountyId++;
        bounties[bountyId] = Bounty({
            poster: msg.sender,
            amount: amount,
            deadline: deadline,
            modelId: modelId,
            taskURI: taskURI,
            status: Status.Open
        });

        emit BountyCreated(bountyId, msg.sender, amount, modelId);
    }

    /// @notice Award bounty to winner. Only owner (Safe multisig) can call.
    /// @param bountyId The bounty to award
    /// @param winner Address to receive BLG
    function award(uint256 bountyId, address winner) external onlyOwner nonReentrant {
        Bounty storage b = bounties[bountyId];
        if (b.status != Status.Open) revert BountyNotOpen(bountyId);

        b.status = Status.Claimed;
        blg.safeTransfer(winner, b.amount);

        emit BountyClaimed(bountyId, winner, b.amount);
    }

    /// @notice Cancel an expired bounty. Only the poster can call, only after deadline.
    function cancel(uint256 bountyId) external nonReentrant {
        Bounty storage b = bounties[bountyId];
        if (b.status != Status.Open) revert BountyNotOpen(bountyId);
        if (b.poster != msg.sender) revert NotPoster(bountyId);
        if (block.timestamp < b.deadline) revert DeadlineNotPassed(bountyId);

        b.status = Status.Cancelled;
        blg.safeTransfer(msg.sender, b.amount);

        emit BountyCancelled(bountyId);
    }
}
