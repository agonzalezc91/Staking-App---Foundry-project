# Staking App (Solidity) — Foundry Project

This repository contains a simple staking application built with **Solidity** and tested using **Foundry**.

The project includes:
- A mintable ERC20 token (`StakingToken`) used for testing and staking.
- A staking contract (`StakingApp`) where users deposit a **fixed amount** of tokens for a period of time to earn ETH rewards.
- A full Foundry test suite (`StakingAppTest`) covering the main contract behaviors.

---

## Contracts

### 1) StakingToken (`src/StakingToken.sol`)
A minimal ERC20 token used for the staking flow.

- Inherits from OpenZeppelin `ERC20`.
- Constructor sets `name` and `symbol`.
- Includes a public `mint(uint256 amount)` function that mints tokens to `msg.sender`.

This token is intentionally simple and mintable to make testing easier.

---

### 2) StakingApp (`src/StakingApp.sol`)
A simple staking contract with:
- A fixed staking amount per user (`fixedStakingAmount`)
- A staking period (`stakingPeriod`)
- ETH rewards per period (`rewardPerPeriod`)
- Owner-controlled configuration for `stakingPeriod`

#### Key state variables
- `stakingToken`: address of the ERC20 token used for staking
- `stakingPeriod`: required time to wait between reward claims
- `fixedStakingAmount`: required deposit amount (users must deposit exactly this amount)
- `rewardPerPeriod`: ETH amount paid per successful claim
- `userBalance`: tracks whether a user has deposited the fixed amount
- `elapsePeriod`: stores the last timestamp used to check staking elapsed time

#### Main functions
- `depositTokens(uint256 tokenAmountToDeposit_)`
  - Requires `tokenAmountToDeposit_ == fixedStakingAmount`
  - Requires the user has not deposited before (`userBalance[msg.sender] == 0`)
  - Transfers tokens into the contract using `transferFrom`
  - Sets `userBalance[msg.sender]` and `elapsePeriod[msg.sender]`

- `withdrawTokens()`
  - Transfers the user’s deposited tokens back to the user

- `claimRewards()`
  - Requires the user is staking (`userBalance[msg.sender] == fixedStakingAmount`)
  - Requires enough time elapsed since last claim (`block.timestamp - elapsePeriod[msg.sender] >= stakingPeriod`)
  - Updates `elapsePeriod[msg.sender]`
  - Pays `rewardPerPeriod` in ETH to the caller using low-level `.call`

- `receive() external payable onlyOwner`
  - Allows the owner to fund the contract with ETH for rewards

- `changeStakingPeriod(uint256 newStakingPeriod_) external onlyOwner`
  - Owner can update stakingPeriod

---

## Testing (Foundry)

The test suite is in:
- `test/StakingAppTest.t.sol`

It deploys:
- `StakingToken(name, symbol)`
- `StakingApp(tokenAddress, owner, stakingPeriod, fixedAmount, rewardPerPeriod)`

### What is tested

#### Deployment & ownership
- Token and staking app deploy correctly (non-zero addresses)
- Only the owner can call `changeStakingPeriod`
- Owner can change staking period

#### ETH funding (receive)
- The staking contract can receive ETH when called by the owner

#### Deposits
- Reverts if deposit amount is not equal to the fixed staking amount ("Incorrect Amount")
- Deposits correctly update:
  - `userBalance`
  - `elapsePeriod`
- A user cannot deposit more than once ("User already deposited")

#### Withdrawals
- With no deposit, withdraw does not change the stored `userBalance`
- After deposit, withdraw transfers the correct amount of tokens back to the user

#### Rewards
- Reverts if user is not staking ("Not staking")
- Reverts if not enough time has elapsed ("need to wait")
- Reverts if contract has no ETH to pay rewards ("Transfer failed")
- After enough time and with contract funded, user can claim rewards successfully and receives `rewardPerPeriod`

---

## How to run

From the project root:

    forge test -vv

Run with more fuzz iterations (optional):

    forge test --fuzz-runs 1000 -vv

---

## Notes

- Rewards are paid in ETH. The contract must be funded by the owner using a plain ETH transfer (the contract `receive()` function is `onlyOwner`).
- Users must deposit exactly `fixedStakingAmount`. Partial deposits are not supported.
- The token contract is mintable by anyone (for testing convenience).

---

## Possible improvements

- Add a revert in `withdrawTokens()` when user is not staking.
- Add ERC20 transfer return value checks (`require(transfer(...))`).
- Add `ReentrancyGuard` for safety on functions that transfer ETH.
- Track staked balances for variable staking amounts (not fixed).
- Add events for reward claims.

---
