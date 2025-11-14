# GuessTheNumber Security Audit Project

This repository contains a security audit of the [GuessTheNumber challenge](https://capturetheether.com/challenges/lotteries/guess-the-number) from Capture The Ether, and a secure reimplementation that addresses all identified vulnerabilities.

## Overview

### Original Contract (GuessTheNumber.sol)

A simple guessing game where users pay 1 ether to guess a number. If correct, they win 2 ether.

**Status:** 🔴 **CRITICAL VULNERABILITIES** - Do NOT deploy

### Original Contract (Working version)

Since the original contract uses old 0.4.21 Solidity version, in order to make it easier to understand and audit, the same has to be upgraded to 0.8.30 Solidity version. Available at [GuessTheNumberWorking.sol](GuessTheNumberWorking.sol)

### Secure Version (GuessTheNumberV2.sol)

A fully secured implementation that fixes all critical, medium, and low severity issues.

## Documentation

- **[AUDIT_REPORT.md](./AUDIT_REPORT.md)** - Complete security audit with detailed findings
- **[AUDIT_POC.md](./AUDIT_POC.md)** - Step-by-step deployment and usage guide

## Technology Stack

- **Solidity**: 0.8.30
- **Framework**: Foundry
- **Security**: OpenZeppelin Contracts v5.5.0
  - ReentrancyGuard
  - Ownable
  - Address utilities

## Audit Summary

| Severity | Count | Status |
|----------|-------|--------|
| 🔴 Critical | 3 | ✅ Fixed in V2 |
| 🟡 Medium | 2 | ✅ Fixed in V2 |
| 🟢 Low | 1 | ✅ Fixed in V2 |
| ℹ️ Info | 1 | ✅ Implemented |
