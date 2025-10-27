# Rebase Token Demo

A Foundry project implementing a rebase-type deflationary ERC20 token using the scaling factor design.

## Overview

This project demonstrates the implementation of a deflationary ERC20 token that uses a rebase mechanism with scaling factors. The token automatically reduces the total supply over time, creating deflationary pressure.

## Features

- ERC20 compliant token with rebase functionality
- Deflationary mechanism using scaling factors
- Gas-optimized implementation
- Comprehensive test suite
- Deployment scripts

## Getting Started

```bash
# Install dependencies
forge install

# Build the project
forge build

# Run tests
forge test

# Run tests with gas reporting
forge test --gas-report

# Deploy (configure network in foundry.toml)
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>
```

## Project Structure

```
├── foundry.toml           # Foundry configuration file
├── lib/                   # Dependencies (as git submodules)
├── script/                # Deployment and interaction scripts
├── src/                   # Source files
│   └── RebaseToken.sol   # Main rebase token implementation
└── test/                  # Test files
    └── RebaseToken.t.sol # Comprehensive test suite
```

## Documentation

- [Foundry Book](https://book.getfoundry.sh/)
- [Foundry GitHub](https://github.com/foundry-rs/foundry)
- [ERC20 Standard](https://eips.ethereum.org/EIPS/eip-20)