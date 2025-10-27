# RebaseToken Demo

A Foundry project implementing a **deflationary ERC20 token** using a **scaling factor design** for rebase mechanics. This token automatically reduces the total supply over time through owner-controlled rebase operations, creating deflationary pressure.

## 🎯 Project Purpose

This project demonstrates how to implement a rebase-type deflationary token that:
- Maintains ERC20 compatibility for seamless DeFi integration
- Uses internal shares and a global scaling factor for efficient rebasing
- Provides owner-controlled deflationary mechanics
- Handles rounding and precision correctly
- Optimizes gas usage through share-based storage

## 🏗️ Design Overview

### Scaling Factor Mechanism

The RebaseToken uses a **scaling factor design** where:

- **Internal Storage**: Balances are stored as `rawShares` (not direct token amounts)
- **Global Index**: A scaling factor `index` (starts at `BASE = 1e18`)
- **Balance Calculation**: `balanceOf(account) = rawShares[account] * index / BASE`
- **Transfer Logic**: Converts amounts to shares: `shares = amount * BASE / index`

### Rebase Mechanism

- **Owner Control**: Only the contract owner can trigger rebases
- **Deflationary**: Each rebase reduces the index by 1% (`newIndex = oldIndex * 99 / 100`)
- **Event Emission**: Emits `Rebase(oldIndex, newIndex, block.timestamp)`
- **Safety**: Minimum index threshold prevents precision issues

### Key Benefits

1. **Gas Efficient**: Share-based storage minimizes state changes
2. **Precision Safe**: Proper rounding and minimum threshold protection
3. **ERC20 Compatible**: Works with all existing DeFi protocols
4. **Deflationary**: Automatic supply reduction creates scarcity
5. **Owner Controlled**: Secure rebase mechanism with proper access control

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Git for version control

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd rebase-token-demo

# Install dependencies
forge install
```

### Build and Test

```bash
# Build the project
forge build

# Run all tests
forge test

# Run tests with gas reporting
forge test --gas-report

# Run specific test with verbose output
forge test --match-test "testSingleRebase" -vvv
```

## 📊 Example Results

### Initial State

```solidity
// Contract deployment with 1,000,000 tokens
Initial Supply: 1,000,000.000000000000000000 tokens
Initial Index: 1.000000000000000000 (BASE = 1e18)
Owner Balance: 1,000,000.000000000000000000 tokens
```

### After 1 Rebase (1% reduction)

```solidity
// After calling rebase() once
New Index: 0.990000000000000000 (99% of original)
Total Supply: 990,000.000000000000000000 tokens
Owner Balance: 990,000.000000000000000000 tokens
Reduction: 10,000.000000000000000000 tokens (1%)
```

### After 3 Rebases (3% total reduction)

```solidity
// After calling rebase() three times
New Index: 0.970299000000000000 (99% × 99% × 99%)
Total Supply: 970,299.000000000000000000 tokens
Owner Balance: 970,299.000000000000000000 tokens
Reduction: 29,701.000000000000000000 tokens (2.9701%)
```

### Transfer + Rebase Example

```solidity
// Initial state
Owner Balance: 1,000,000 tokens
Alice Balance: 0 tokens

// Transfer 100,000 tokens to Alice
token.transfer(alice, 100000 * 1e18);
Owner Balance: 900,000 tokens
Alice Balance: 100,000 tokens

// Perform rebase (1% reduction)
token.rebase();
Owner Balance: 891,000 tokens (900,000 × 0.99)
Alice Balance: 99,000 tokens (100,000 × 0.99)
Total Supply: 990,000 tokens
```

## 🔧 How to Reproduce Results Locally

### Step 1: Clone and Setup

```bash
git clone <repository-url>
cd rebase-token-demo
forge install
forge build
```

### Step 2: Run Tests to Verify

```bash
# Run all tests to ensure everything works
forge test

# Run specific tests for rebase functionality
forge test --match-test "testSingleRebase|testMultipleRebase"
```

### Step 3: Deploy and Interact (Optional)

```bash
# Deploy to local testnet
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key <PRIVATE_KEY>

# Or deploy to a testnet
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

### Step 4: Manual Testing

You can also interact with the contract manually:

```solidity
// Deploy the contract
RebaseToken token = new RebaseToken("RebaseToken", "RBT", 18, 1000000 * 1e18);

// Check initial state
console.log("Initial Supply:", token.totalSupply());
console.log("Initial Index:", token.getIndex());

// Perform rebase
token.rebase();

// Check after rebase
console.log("Supply after rebase:", token.totalSupply());
console.log("Index after rebase:", token.getIndex());
```

## 📁 Project Structure

```
├── foundry.toml           # Foundry configuration
├── lib/                   # Dependencies (forge-std)
├── script/                # Deployment scripts
├── src/                   # Source files
│   └── RebaseToken.sol   # Main contract implementation
├── test/                  # Test files
│   └── RebaseToken.t.sol # Comprehensive test suite
└── README.md             # This file
```

## 🧪 Test Coverage

The test suite includes **18 comprehensive tests** covering:

- ✅ **Initialization**: Constructor parameters and initial state
- ✅ **Single Rebase**: 1% reduction with event emission
- ✅ **Transfer + Rebase**: Proper scaling after transfers
- ✅ **Multiple Rebases**: 3 consecutive rebases with consistency
- ✅ **Rounding Edge Cases**: 1 wei transfers and precision handling
- ✅ **Permission Control**: Owner-only rebase functionality
- ✅ **Supply Consistency**: Total supply vs sum of balances

### Running Specific Tests

```bash
# Test initialization
forge test --match-test "testInitialization"

# Test rebase functionality
forge test --match-test "testSingleRebase|testMultipleRebase"

# Test rounding edge cases
forge test --match-test "testRoundingEdgeCase1Wei"

# Test permission control
forge test --match-test "testRebaseOnlyOwner"
```

## ⚡ Gas Optimization

The contract is optimized for gas efficiency:

- **Deployment**: ~931k gas
- **Rebase Operation**: ~30k gas
- **Transfer**: ~54k gas
- **Balance Query**: ~4.8k gas

## 🔒 Security Features

- **Owner Control**: Only contract owner can perform rebases
- **Minimum Index**: Prevents index from going too low (precision protection)
- **Zero Address Checks**: All transfer and approval functions
- **Balance Validation**: Ensures sufficient funds before transfers
- **Proper Rounding**: Handles division operations correctly

## 📚 Technical Details

### Contract Functions

```solidity
// Core ERC20 Functions
function balanceOf(address account) external view returns (uint256)
function transfer(address to, uint256 amount) external returns (bool)
function transferFrom(address from, address to, uint256 amount) external returns (bool)
function approve(address spender, uint256 amount) external returns (bool)
function totalSupply() external view returns (uint256)

// Rebase Functions
function rebase() external onlyOwner
function getIndex() external view returns (uint256)
function getRawShares(address account) external view returns (uint256)

// Owner Functions
function transferOwnership(address newOwner) external onlyOwner
```

### Events

```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
event Rebase(uint256 oldIndex, uint256 newIndex, uint256 timestamp);
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 References

- [Foundry Book](https://book.getfoundry.sh/)
- [ERC20 Standard](https://eips.ethereum.org/EIPS/eip-20)
- [Rebase Token Patterns](https://github.com/ampleforth/token-geyser)

---

**Note**: This is a demonstration project. For production use, consider additional security audits, access control mechanisms, and economic modeling for the rebase parameters.