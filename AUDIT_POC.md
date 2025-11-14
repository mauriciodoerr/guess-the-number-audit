# GuessTheNumberV2 Deployment Guide

## Overview

GuessTheNumberV2 fixes all security vulnerabilities from the audit while maintaining the original simple game logic:
- Players guess a number and pay 1 ether
- Correct guess wins 2 ether instantly
- Wrong guess loses 1 ether
- No complex reveals or waiting periods
- Uses OpenZeppelin's `Address.sendValue()` for safer ether transfers

block.timestamp has been used as this is academic and just to control re-attempt to guess. Another idea would be to use blocks instead of timestamp.

## Prerequisites

- Foundry installed ([getfoundry.sh](https://getfoundry.sh))
- OpenZeppelin Contracts v5.5.0 (installed via Foundry)

## Security Improvements

### Critical Issues Fixed ✅

1. **Hidden Answer (CRITICAL-01)**
   - Answer stored as `keccak256(abi.encodePacked(answer))`
   - Cannot be read directly from storage
   - Note: Still vulnerable to brute force attacks (use Chainlink VRF for production)

2. **Reentrancy Protection (CRITICAL-02)**
   - Custom `nonReentrant` modifier
   - Follows Checks-Effects-Interactions (CEI) pattern
   - State updated before external calls

3. **No Locked Funds (CRITICAL-03)**
   - `withdrawFunds()` function for owner
   - Incorrect guesses automatically refunded
   - No funds can be permanently locked

### Medium Issues Fixed ✅

4. **Access Control (MEDIUM-01)**
   - Maximum 3 attempts per address
   - 60-second cooldown between guesses
   - Owner-only withdrawal function

5. **Event Logging (MEDIUM-02)**
   - `GuessAttempted` - logs all attempts
   - `GameWon` - logs wins
   - `FundsWithdrawn` - logs withdrawals
   - `ContractDeployed` - logs deployment

## Installation

### Step 0: Setup Project

If you haven't already, initialize the Foundry project and install OpenZeppelin:

```bash
# Initialize Foundry project (if not already done)
forge init

# Install OpenZeppelin Contracts
forge install OpenZeppelin/openzeppelin-contracts --no-commit

# The foundry.toml is already configured with remappings
```

The `foundry.toml` file includes:
```toml
[profile.default]
src = "."
out = "out"
libs = ["lib"]
remappings = [
    "@openzeppelin/=lib/openzeppelin-contracts/",
    "@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/"
]
```

### Step 1: Compile Contract

```bash
forge build --contracts GuessTheNumberV2.sol
```

## Deployment Instructions

### Step 2: Generate Answer Hash

Simply hash the answer number off-chain.

**Using JavaScript (ethers.js):**

```javascript
const { ethers } = require('ethers');

const answer = 42;
const answerHash = ethers.keccak256(
  ethers.solidityPacked(['uint256'], [answer])
);

console.log("Answer:", answer);
console.log("Answer Hash:", answerHash);
```

**Using Solidity/Remix:**

You can use the contract's helper function:
```solidity
// Call the pure function
generateAnswerHash(42)
// Returns: 0x...
```

**Using Cast (Foundry):**

```bash
cast keccak $(cast abi-encode "f(uint256)" 42)
```

**IMPORTANT:** Keep the answer secret! The hash alone doesn't reveal the number.

### Step 3: Deploy Contract

**Constructor Parameters:**

- `_answerHash`: The hash generated in Step 1
- `msg.value`: Must be exactly 1 ether

**Example Deployment (Foundry):**

```bash
# Generate hash
ANSWER_HASH=$(cast keccak $(cast abi-encode "f(uint256)" 42))

# Deploy
forge create GuessTheNumberChallengeV2 \
  --constructor-args $ANSWER_HASH \
  --value 1000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

## How to Play

### For Players

**Make a Guess:**

```javascript
// Just guess the number!
const myGuess = 42;

const tx = await contract.guess(myGuess, {
  value: ethers.parseEther("1")
});

await tx.wait();
console.log("Guess submitted!");

// Check if you won by listening to events
```

**Check Remaining Attempts:**

```javascript
const remaining = await contract.getRemainingAttempts(playerAddress);
console.log("Attempts remaining:", remaining);
```

**Check Cooldown:**

```javascript
const cooldown = await contract.getCooldownRemaining(playerAddress);
if (cooldown > 0) {
  console.log("Wait", cooldown, "seconds before next guess");
} else {
  console.log("Ready to guess!");
}
```

**Check if Game is Complete:**

```javascript
const complete = await contract.isComplete();
console.log("Game completed:", complete);
```

### For Owner

**Withdraw Funds:**

```javascript
// Only owner can call this
const tx = await contract.withdrawFunds();
await tx.wait();
console.log("Funds withdrawn");
```

## Game Flow Example

```javascript
// 1. Owner deploys with answer hash
const answer = 42;
const hash = ethers.keccak256(ethers.solidityPacked(['uint256'], [answer]));
const contract = await GuessTheNumberV2.deploy(hash, {
  value: ethers.parseEther("1")
});

// 2. Player 1 guesses wrong, loses 1 ether
await contract.connect(player1).guess(41, {
  value: ethers.parseEther("1")
});

// 3. Player 2 guesses right (wins immediately!)
await contract.connect(player2).guess(42, {
  value: ethers.parseEther("1")
});
// Player2 receives 2 ether instantly!

// 4. Game is now complete (balance = 0)
const complete = await contract.isComplete(); // true

// 5. If there are any remaining funds, owner can withdraw
if (!complete) {
  await contract.withdrawFunds();
}
```

## Security Features

### 1. Answer Protection
- Answer stored as keccak256 hash only
- Players just guess numbers
- Casual storage inspection won't reveal answer
- ⚠️ Warning: Vulnerable to brute force (try all numbers)
- For production: Use Chainlink VRF or similar

### 2. Reentrancy Protection
- Custom `nonReentrant` modifier prevents recursive calls
- State updated before external calls (CEI pattern)
- Protected against reentrancy attacks
- Uses OpenZeppelin's `Address.sendValue()` for safe transfers

### 3. Access Controls
- `onlyOwner` modifier for sensitive functions
- Max 3 attempts per address
- 60-second cooldown between guesses
- Prevents brute force and spam

### 4. No Locked Funds
- Owner can withdraw remaining funds
- No scenario where funds are permanently locked

### 5. Transparency
- All actions emit events
- Public view functions for game state
- Clear error messages with custom errors

## Support & References

- Audit Report: See `AUDIT_REPORT.md` for detailed vulnerability analysis
- Original Contract: `GuessTheNumber.sol`
- Secure Version: `GuessTheNumberV2.sol`
