# Zoo Sustainability Tax — Formal Spec

**Status**: Final
**Date**: 2025-12-15
**Realizes**: 2021 Whitepaper §5 (Sustainability), §6 (Supporting Non-Profits), §7 (Foundation), §8 (Liquidity Protocol — fee mention).
**Originated**: 2021-10-31.

---

## 1. Statement

Every value-bearing transaction in the Zoo protocol routes a small
percentage to the **Zoo Foundation treasury**. The treasury is governed
by the Zoo DAO (ZIP-0017) and disburses to wildlife-conservation
non-profits (ZIP-0023, ZIP-0530, ZIP-0570). This is the on-chain
realization of the founder commitment in §6 of the 2021 paper:

> *"The Zoo DAO ... takes responsibility for managing the treasury and
> ensuring that donations are allocated to impactful initiatives."*

## 2. Tax Rates

Single global parameter `sustainabilityTaxBps` (basis points, `1 bps = 0.01%`).
Default schedule:

| Operation | Rate (bps) | Rate (%) |
|---|---|---|
| NFT mint (`mintEgg`) | 200 | 2.0% |
| NFT feed / boost | 100 | 1.0% |
| Marketplace trade | 200 | 2.0% |
| Pool listing fill | 200 | 2.0% |
| Burn redeem (exit fee on collateral only) | 100 | 1.0% |
| Bridge teleport | 50 | 0.5% |

All within the 1–3% range named in §6 of the 2021 paper. Maximum
sustainability tax in any single transaction is bounded at 300 bps
(3%) by hard cap in the contract. Higher rates require supermajority
DAO vote (ZIP-0017 §Parameter Change).

## 3. Treasury Recipient

The recipient is the **Zoo Foundation Treasury Multisig** governed by
the Zoo DAO. Custody: M-Chain MPC (LP-019) threshold-signed under a
2-of-3 board / community split.

```solidity
address public constant ZOO_FOUNDATION_TREASURY = 0xZooTreasuryMultisigOnZooL1;
```

## 4. Disbursement

Disbursement happens through ZIP-0023 (Community Grant Program) and
ZIP-0104 (Research Funding DAO Treasury). Quarterly allocation cycles.
Recipient categories:

1. **Wildlife conservation NGOs** (per the V1 species catalogue: WWF,
   IUCN, ZSL, Panthera, AWF, WCS, Sumatran-Elephant Conservation
   Initiative, Save the Rhino, etc.).
2. **In-situ field operations** (anti-poaching, habitat protection).
3. **Research grants** (genomics, conservation AI, citizen science —
   see ZIP-0500 series).
4. **Foundation operations** (capped at 15% of treasury per cycle).

## 5. Accounting

The contract emits a `SustainabilityTax` event on every collection:

```solidity
event SustainabilityTax(
    address indexed payer,
    address indexed source,    // contract that triggered the tax
    bytes32 indexed kind,      // "MINT" | "FEED" | "TRADE" | "POOL" | "BURN" | "BRIDGE"
    uint256 amount,
    address asset
);
```

Off-chain analytics aggregate by `kind` and publish quarterly impact
reports under the framework in ZIP-0501 (Conservation Impact
Measurement) and ZIP-0560 (Evidence Locker Index).

## 6. Anti-Bypass

- All Zoo first-party contracts (NFT, Marketplace, Bridge, Pool, Bond,
  AMM) MUST include the tax hook before transfer. Audited and gated
  by ZIP-0100 (Zoo Contract Registry).
- Off-protocol transfers (raw ERC-721 `transferFrom`) are not taxed
  but also do not earn protocol rewards. Reward gating creates the
  economic incentive to stay on-protocol.

## 7. Sustainability Posture

The tax is *additive* to base sustainability through Quasar 3.0's
energy efficiency: GPU-native execution under LP-137 keeps committee
hot paths on the device, avoiding wasteful re-shuffling. The
combination — efficient consensus + protocol-level conservation tax —
operationalizes the §5 commitment that "blockchain technology can
have a positive impact on the environment."

## 8. Cross-References

- 2021 Whitepaper §5 (Sustainability), §6 (Non-Profits), §7 (Foundation).
- ZIP-0018 (Treasury Management Protocol).
- ZIP-0023 (Community Grant Program).
- ZIP-0104 (Research Funding DAO Treasury).
- ZIP-0500 (ESG Principles Conservation Impact).
- ZIP-0501 (Conservation Impact Measurement).
- ZIP-0560 (Evidence Locker Index).
- ZIP-0570 (Zoo Labs Impact Thesis).
- `contracts/specs/zoo-nft-liquidity-protocol.md` (consumer of this hook).

## 9. Activation

Live with Zoo L1 genesis on 2025-12-25. Initial parameters fixed by
genesis configuration; subsequent changes via ZIP-0017 governance.
