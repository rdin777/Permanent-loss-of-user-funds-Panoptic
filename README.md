# Panoptic Security Research & Audit Findings

This repository contains proof-of-concept (PoC) exploits demonstrating critical vulnerabilities identified in the Panoptic protocol during security research.

---

## Findings Summary

| # | Vulnerability Title | Severity | Target Component | Type |
|---|---|---|---|---|
| 1 | Precision Loss & "Ghost Debt" Liquidation Deadlock | **High** | `CollateralTracker` | Math / Logic Error |
| 2 | Cross-Contract Reentrancy via Liquidator Incentives | **High** | `CollateralTracker` / `PanopticPool` | Reentrancy (CEI Violation) |

---

## Part 1: Precision Loss & "Ghost Debt" Liquidation Deadlock

### 1. Vulnerability Overview
A critical rounding/precision loss vulnerability exists in the collateral and share math calculations. Under specific pool states, rounding errors in debt conversion allow a user's debt to be rounded down to zero or calculated incorrectly, resulting in "ghost debt" that can never be settled or liquidated.

### 2. The Impact (Permanent Loss of Funds)
* **Deadlock:** The liquidation logic relies on exact conversion calculations. When precision loss occurs, the contract fails to settle the correct share amount.
* **Denial of Service (DoS):** Affected user accounts enter a permanent deadlock state where they cannot be liquidated, and their remaining collateral is locked in the protocol forever.
* **Bad Debt:** The protocol cannot recover undercollateralized positions, leading to unbacked pool debt.

### 3. Proof of Concept Execution
To run the original mathematical deadlock exploit:
```bash
forge test --match-path test/foundry/Exploit.t.sol -vv

## Part 2: Cross-Contract Reentrancy & Phantom Shares Hijacking

### 1. Vulnerability Overview
During the liquidation process in `CollateralTracker.settleLiquidation`, the contract sends ETH back to the liquidator to settle gas/execution bonuses (`safeTransferETH`). 

However, this external call is executed **before** the final balance check and token burn logic (violating the Checks-Effects-Interactions pattern). A malicious liquidator can intercept the control flow via a fallback/receive function (reentrancy) and move the target's phantom shares to a clean address before the contract has a chance to burn them.

### 2. The Impact (Infinite Supply Inflation)
1. The attacker triggers a liquidation and receives an ETH transfer.
2. In the `receive()` block of the exploit contract, the attacker transfers all phantom shares from the victim to a clean receiver address.
3. The control flow returns to `settleLiquidation`. The contract attempts to burn `type(uint248).max` shares from the victim, but finds their balance is now empty (`0`).
4. Due to underflow protection logic, the protocol compensates for this discrepancy by **inflating `_internalSupply`** by the missing amount.
5. Result: The attacker converts non-withdrawable phantom shares into real, backed ERC-20 assets, diluting the entire pool and draining user collateral.

### 3. How to Run the Reentrancy PoC
```bash
forge test --match-path test/foundry/ReentrancyExploit.t.sol -vv
