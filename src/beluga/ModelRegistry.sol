// SPDX-License-Identifier: BSD-3-Clause
// Copyright (C) 2026, Zoo Labs Foundation. All rights reserved.
pragma solidity ^0.8.31;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title ModelRegistry
/// @notice NFT registry for AI models on Beluga L3. One NFT per model.
/// @dev Weights stored off-chain (IPFS/S3). On-chain: metadata hash, owner, pricing.
///      Integrates with ComputeMarket -- providers reference modelId from this registry.
contract ModelRegistry is ERC721, Ownable, ReentrancyGuard {

    struct Model {
        bytes32 weightsHash;    // BLAKE3 hash of model weights
        string  weightsURI;     // IPFS CID or S3 URI for weights
        string  metadataURI;    // Model card, architecture, license
        uint256 pricePerToken;  // Suggested BLG price per inference token
        uint256 totalInferences;
        bool    active;
    }

    mapping(uint256 => Model) public models;

    uint256 public nextModelId;

    event ModelRegistered(uint256 indexed modelId, address indexed owner, bytes32 weightsHash);
    event ModelUpdated(uint256 indexed modelId, uint256 pricePerToken);
    event ModelDeactivated(uint256 indexed modelId);
    event InferenceRecorded(uint256 indexed modelId, uint256 count);

    error ModelNotActive(uint256 modelId);
    error NotModelOwner(uint256 modelId, address caller);
    error EmptyWeightsHash();

    constructor()
        ERC721("Beluga Model Registry", "BLG-MODEL")
        Ownable(msg.sender)
    {}

    /// @notice Register a new model. Mints an NFT to the caller.
    /// @param weightsHash BLAKE3 hash of model weights file
    /// @param weightsURI  IPFS CID or S3 URI where weights are stored
    /// @param metadataURI Model card URI (architecture, license, benchmarks)
    /// @param pricePerToken Suggested BLG price per inference token (0 = free)
    /// @return modelId The minted NFT token ID
    function register(
        bytes32 weightsHash,
        string calldata weightsURI,
        string calldata metadataURI,
        uint256 pricePerToken
    ) external nonReentrant returns (uint256 modelId) {
        if (weightsHash == bytes32(0)) revert EmptyWeightsHash();

        modelId = nextModelId++;
        _mint(msg.sender, modelId);

        models[modelId] = Model({
            weightsHash: weightsHash,
            weightsURI: weightsURI,
            metadataURI: metadataURI,
            pricePerToken: pricePerToken,
            totalInferences: 0,
            active: true
        });

        emit ModelRegistered(modelId, msg.sender, weightsHash);
    }

    /// @notice Update model pricing. Only the NFT owner can call.
    function updatePrice(uint256 modelId, uint256 pricePerToken) external {
        if (ownerOf(modelId) != msg.sender) revert NotModelOwner(modelId, msg.sender);
        models[modelId].pricePerToken = pricePerToken;
        emit ModelUpdated(modelId, pricePerToken);
    }

    /// @notice Deactivate a model. Only the NFT owner can call.
    function deactivate(uint256 modelId) external {
        if (ownerOf(modelId) != msg.sender) revert NotModelOwner(modelId, msg.sender);
        models[modelId].active = false;
        emit ModelDeactivated(modelId);
    }

    /// @notice Record completed inferences. Called by ComputeMarket or authorized contracts.
    /// @dev Owner-gated to prevent spam. In production, grant to ComputeMarket address.
    function recordInferences(uint256 modelId, uint256 count) external onlyOwner {
        if (!models[modelId].active) revert ModelNotActive(modelId);
        models[modelId].totalInferences += count;
        emit InferenceRecorded(modelId, count);
    }

    /// @notice Check if a model is registered and active.
    function isActive(uint256 modelId) external view returns (bool) {
        return modelId < nextModelId && models[modelId].active;
    }
}
