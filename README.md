# HorizonPredict

## Decentralized Market Intelligence Layer

[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-orange)](https://stacks.co)
[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contract-blue)](https://clarity-lang.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

HorizonPredict is a revolutionary peer-to-peer financial coordination network that transforms collective intelligence into cryptographically enforced settlement mechanisms. Built on the Stacks blockchain and secured by Bitcoin's finality, the protocol enables communities to express market sentiment, hedge uncertainty, and allocate capital efficiently through trustless forecasting primitives.

## 🎯 Overview

Unlike traditional betting platforms, HorizonPredict establishes a structured financial instrument where speculation becomes meaningful market intelligence. The protocol leverages Bitcoin's security through Stacks' smart contracts to ensure transparent outcome resolution, automated capital distribution, and censorship-resistant participation.

### Key Features

- **Permissionless Market Creation**: Deploy markets with flexible lifecycle parameters
- **Non-custodial Staking**: Users retain full control with deterministic outcome resolution
- **Decentralized Oracle Integration**: Unbiased settlement through trusted data sources
- **Institutional-grade Economics**: Sustainable fee structures and treasury management
- **Transparent Settlement**: Cryptographically enforced outcome resolution

## 🏗️ Architecture

### System Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Market Maker  │    │     Oracle      │    │   Participants  │
│                 │    │   Integration   │    │                 │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    HorizonPredict Protocol                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Market    │  │ Position    │  │      Governance         │  │
│  │ Management  │  │ Tracking    │  │     & Treasury          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ Stacks Network  │
                    │ (Bitcoin Layer) │
                    └─────────────────┘
```

### Contract Architecture

The HorizonPredict protocol consists of several interconnected components:

#### Core Data Structures

1. **Market Registry** (`markets` map)
   - Tracks market lifecycle and state
   - Stores price points, stakes, and resolution status
   - Manages temporal constraints (start/end blocks)

2. **Position Ledger** (`user-predictions` map)
   - Records individual user positions
   - Tracks stake amounts and prediction directions
   - Manages claim status to prevent double-spending

#### Function Categories

- **Market Lifecycle**: Creation, participation, and resolution
- **Economic Engine**: Staking, fee calculation, and payout distribution
- **Oracle Integration**: External data source for price settlements
- **Governance**: Parameter updates and treasury management

## 📊 Data Flow

### Market Creation Flow

```
Contract Owner → create-market() → Market ID Generated → Market Active
```

### Participation Flow

```
User → make-prediction() → STX Transfer → Position Recorded → Stake Pooled
```

### Resolution Flow

```
Oracle → resolve-market() → End Price Set → Market Resolved → Claims Available
```

### Settlement Flow

```
Winner → claim-winnings() → Payout Calculated → STX Transfer → Fee Deduction
```

## 🔧 Core Functions

### Public Functions

#### Market Operations

- `create-market(start-price, start-block, end-block)` - Deploy new prediction market
- `make-prediction(market-id, prediction, stake)` - Enter position ("up" or "down")
- `resolve-market(market-id, end-price)` - Oracle-driven settlement
- `claim-winnings(market-id)` - Retrieve payouts after resolution

#### Governance

- `set-oracle-address(new-address)` - Update trusted oracle
- `set-minimum-stake(new-minimum)` - Adjust participation threshold
- `set-fee-percentage(new-fee)` - Modify protocol fees
- `withdraw-fees(amount)` - Treasury management

### Read-Only Functions

- `get-market(market-id)` - Retrieve market information
- `get-user-prediction(market-id, user)` - Query user positions
- `get-contract-balance()` - Check protocol treasury

## 💰 Economic Model

### Fee Structure

- **Protocol Fee**: 2% (configurable) deducted from winnings
- **Minimum Stake**: 1 STX (1,000,000 microSTX)
- **Payout Formula**: `(user_stake * total_pool) / winning_pool - fees`

### Capital Flow

1. Users stake STX in market positions
2. Funds held in contract escrow during market duration
3. Oracle resolves market with final price
4. Winners claim proportional share of total pool
5. Protocol fee retained for sustainability

## 🔒 Security Features

- **Owner-only Market Creation**: Prevents spam and ensures quality
- **Oracle Authorization**: Only designated oracle can resolve markets
- **Claim Protection**: Prevents double-claiming through state tracking
- **Balance Validation**: Ensures users have sufficient funds before staking
- **Temporal Constraints**: Markets operate within defined block ranges

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for local development
- Node.js 16+ for testing framework
- Stacks wallet for mainnet interaction

### Local Development

1. **Clone Repository**

   ```bash
   git clone <repository-url>
   cd horizon-predict
   ```

2. **Install Dependencies**

   ```bash
   npm install
   ```

3. **Run Tests**

   ```bash
   npm test
   ```

4. **Check Contracts**

   ```bash
   clarinet check
   ```

### Deployment

1. **Deploy to Testnet**

   ```bash
   clarinet integrate
   ```

2. **Deploy to Mainnet**

   ```bash
   clarinet deploy --network mainnet
   ```

## 📈 Usage Examples

### Creating a Market

```javascript
// Contract owner creates a BTC price prediction market
const result = await contractCall({
  contractAddress: "SP...",
  contractName: "horizon-predict",
  functionName: "create-market",
  functionArgs: [
    uintCV(50000000000), // Start price: $50,000 (microunits)
    uintCV(startBlock),
    uintCV(endBlock)
  ]
});
```

### Making a Prediction

```javascript
// User predicts price will go up with 5 STX stake
const result = await contractCall({
  contractAddress: "SP...",
  contractName: "horizon-predict",
  functionName: "make-prediction",
  functionArgs: [
    uintCV(0), // Market ID
    stringAsciiCV("up"),
    uintCV(5000000) // 5 STX in microSTX
  ]
});
```

## 🧪 Testing

The protocol includes comprehensive test coverage:

```bash
# Run all tests
npm test

# Run with coverage report
npm run test:report

# Watch mode for development
npm run test:watch
```

## 📋 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | ERR_OWNER_ONLY | Function restricted to contract owner |
| u101 | ERR_NOT_FOUND | Market or prediction not found |
| u102 | ERR_INVALID_PREDICTION | Invalid prediction parameter |
| u103 | ERR_MARKET_CLOSED | Market not active for operation |
| u104 | ERR_ALREADY_CLAIMED | Winnings already claimed |
| u105 | ERR_INSUFFICIENT_BALANCE | Insufficient STX balance |
| u106 | ERR_INVALID_PARAMETER | Invalid function parameter |

## 🗺️ Roadmap

- [ ] Multi-asset market support (beyond price predictions)
- [ ] Decentralized oracle network integration
- [ ] Liquidity provider incentives
- [ ] Mobile application interface
- [ ] Cross-chain compatibility

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
