# Zoo NFT Liquidity Protocol — Formal Spec

**Status**: Final
**Date**: 2025-12-15
**Realizes**: 2021 Whitepaper §8 ("Zoo: An NFT Liquidity Protocol"), §13 (Collateral-Backed NFTs), §15 (Asset Transfer), §18 (Animal Rewards).
**Originated**: 2021-10-31 (Antje Worring, Zoo Labs Foundation).

---

## 1. Historical Lineage — Canonical Coinage

The phrase **"NFT Liquidity Protocol"** was coined by Zoo Labs Foundation
in the **October 31, 2021** founder whitepaper (Antje Worring). Quoting
§8 of the 2021 paper verbatim:

> *"Zoo is a liquidity protocol for NFTs, in the way that Uniswap or
> PancakeSwap is for tokens."*

This specific phrasing — "NFT Liquidity Protocol" — predates by years
the use of the word "Liquidity" as a brand name by other entities.
**Zoo coined the term**. Subsequent third-party brand adoption is a
downstream effect.

This spec formalizes the protocol Zoo invented and continues to
operate under that name in 2025-12-15.

## 2. Goal

Treat every animal NFT as an **LP token**: it locks collateral, accrues
rewards, supports fractionalization and pool listing, and can be burned
to redeem the underlying. Each NFT is a position; each position
contributes to a marketplace where empathetic AI companions are also
financial primitives.

## 3. Core Mechanics

### 3.1 Animal NFT as Position

Each animal NFT (ZRC-721 wildlife token, see ZIP-0200) is a
position with the fields:

| Field | Type | Description |
|---|---|---|
| `species` | `bytes32` | IUCN-mapped species identifier |
| `rarity` | `uint8` | 0=Common, 1=Rare, 2=Epic, 3=Legendary |
| `lifeStage` | `uint8` | 0=Egg, 1=Baby, 2=Teen, 3=Adult |
| `collateralAsset` | `address` | $ZOO or any whitelisted ERC-20 |
| `collateralAmount` | `uint256` | Locked principal |
| `mintTimestamp` | `uint64` | Used for lifecycle progression |
| `lastFedAt` | `uint64` | Timestamp of last `feed` call |
| `accruedRewards` | `uint256` | Streamed rewards in $ZOO |

### 3.2 Operations

| Operation | Description | 2021 §reference |
|---|---|---|
| `mintEgg(species, rarity, collateralAsset, amount)` | Lock collateral, mint Egg NFT | §17 Gen 0 |
| `feed(tokenId, asset, amount)` | Add collateral; refresh `lastFedAt` | §13.2 Feeding |
| `boost(tokenId, asset, amount)` | Apply temporary multiplier on rewards | §13.3 Boosts |
| `breed(tokenIdA, tokenIdB)` | Pair two adults; mint child Egg under generational limits | §13.4 Breeding |
| `hatch(tokenId)` | Egg → Baby after maturity timer | §17.1 |
| `claimRewards(tokenId)` | Stream `accruedRewards` to owner | §13.1.2 Rewards |
| `burn(tokenId)` | "Free the animal": redeem collateral + accrued rewards | §15.1.2 Burning |
| `listPool(tokenIds[], price)` | List a set of NFTs as a single marketplace pool | §8 Pools |

### 3.3 Reward Function

Per-second rewards for an NFT:

```
r(t) = baseRate(rarity) * stage(lifeStage) * boostFactor(t) * collateralAmount
```

- `baseRate(rarity)`: 1× / 1.5× / 2× / 3× for Common/Rare/Epic/Legendary.
- `stage(lifeStage)`: 0× / 0.5× / 1× / 1× — Eggs do not earn (§13.1).
- `boostFactor(t)`: 1.0–2.0, decays linearly back to 1.0 over 7 days post-`boost`.
- `collateralAmount`: principal locked.

Daily allowances by rarity (§17.3) are exposed as `dailyAllowance(rarity)`
and capped per NFT to prevent runaway inflation.

### 3.4 Burn-to-Redeem

`burn(tokenId)` is the canonical "free the animal" exit. The contract
transfers `collateralAmount + accruedRewards − exitFee` to the owner,
where `exitFee = collateralAmount * sustainabilityTaxBps / 10000`
(see `zoo-sustainability-tax.md`). The exit fee routes to the Zoo
Foundation treasury multisig. The NFT is permanently destroyed.

### 3.5 Pool Listing (Marketplace)

A user lists `tokenIds[]` at price `P` in $ZOO. The contract escrows
the NFTs. Buyer pays `P`; seller receives `P − marketplaceFee − sustainabilityTaxBps`;
treasury receives `sustainabilityTaxBps`. The pool transfers atomically.

## 4. Architecture (2025-12-15)

The protocol runs on **Zoo L1** (Quasar-native, GPU-native execution
under LP-132 / LP-137). Settlement is Quasar 3.0 (LP-020): BLS +
Ringtail + ML-DSA composite, post-quantum-safe.

| Layer | Component | Lux ref |
|---|---|---|
| Settlement | Q-Chain certs anchor every state transition | LP-020 |
| Execution | QuasarGPU adapter on Zoo L1 | LP-132 |
| Identity | DID + XP attestations on A-Chain | LP-060, LP-134 |
| Bridge | B-Chain teleport for cross-chain redemption | LP-134 |
| Confidential collateral | Optional FHE wrap on F-Chain | LP-013 |

## 5. Cross-References

- 2021 Whitepaper §8, §13, §15, §17, §18 (`papers/zoo-2021-original-whitepaper/`).
- Genesis retrospective (`papers/zoo-nft-liquidity-protocol/`).
- ZIP-0203 (Habitat NFT Fractional Ownership).
- ZIP-0207 (Breeding Simulation NFT).
- ZIP-0204 (Dynamic Metadata Living NFTs).
- Sustainability Tax spec (`contracts/specs/zoo-sustainability-tax.md`).

## 6. Activation

Live on Zoo L1 mainnet from 2025-12-25 (Quasar 3.0 production cutover),
co-incident with the per-LLM chains activation. Existing animal NFT
holders from 2021–2024 BSC era are migrated through the Zoo Bridge
under the Top-2 NFT Migration Program (see ROADMAP-2025-12-15.md).
