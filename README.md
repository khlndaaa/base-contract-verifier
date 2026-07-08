# Base Contract Verifier

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Built for Base](https://img.shields.io/badge/Built%20for-Base-0052FF)](https://base.org)

Automatic Solidity contract verification on **Base**, via GitHub
Actions, Foundry (`forge verify-contract`), and the free Blockscout Pro
API (Etherscan-compatible).

Two ways to trigger it:
1. **Automatically** — on push to `main`, if `contracts.json` or files
   under `src/` changed
2. **Manually** — via **Actions → Run workflow**, with a field for a
   specific address

## Structure

```
.
├── src/Counter.sol              # example contract (replace with your own)
├── contracts.json                # list of contracts for auto-verification
├── foundry.toml                  # Foundry config + Base/Blockscout
├── verify.sh                     # script that reads contracts.json and verifies
└── .github/workflows/verify.yml  # the workflow itself
```

## Setup

### 1. Get a free Blockscout Pro API key

Same key used for the other Base tools in this collection:

1. https://dev.blockscout.com/ → Login
2. Create an API key (starts with `proapi_...`)

### 2. Add the secret to your repository

**Settings → Secrets and variables → Actions → New repository secret**
- Name: `BLOCKSCOUT_API_KEY`
- Value: your key

### 3. Describe your contracts in `contracts.json`

```json
{
  "network": "base",
  "contracts": [
    {
      "name": "MyToken",
      "path": "src/MyToken.sol:MyToken",
      "address": "0xYourContractAddress",
      "constructorArgs": ""
    }
  ]
}
```

- `path` — format `path/To/File.sol:ContractName`
- `address` — the deployed contract's address on Base
- `constructorArgs` — ABI-encoded hex string of constructor arguments
  (get it with `cast abi-encode "constructor(uint256,address)" 100 0x...`);
  leave empty if the constructor takes no arguments
- Add as many entries as you like to the `contracts` array — the
  verifier walks through every one with a non-empty address

Once you push a change to `main` (e.g. after deploying a new contract
and updating its address in `contracts.json`), verification runs
automatically.

### 4. Or run it manually for a single address

**Actions → Verify Base Contracts → Run workflow**, fill in:
- `address` — the contract's address
- `contract_path` — `src/File.sol:ContractName`
- `constructor_args` — optional
- `network` — `base` (mainnet) or `base_sepolia` (testnet)

Handy when a contract was deployed outside this repo (e.g. via Remix).

## How it works

- `foundry.toml` registers Base and Base Sepolia as `[etherscan]`
  targets, but points the URL at the Blockscout Pro API instead of
  `etherscan.io` — Foundry supports any Etherscan-compatible verifier
  through `--verifier etherscan` with a custom URL.
- `verify.sh` parses `contracts.json` with `jq` and calls
  `forge verify-contract --watch` for every contract with an address
  set, waiting for the server to confirm verification rather than just
  firing off the request.
- The workflow has two independent paths: manual input
  (`workflow_dispatch` with `address`) and bulk verification from the
  config file (`push`, or `workflow_dispatch` without `address`).

## Local run (without GitHub)

```bash
export BLOCKSCOUT_API_KEY=proapi_your_key
forge build
bash verify.sh contracts.json
```

## License

MIT — use it, modify it, fork it freely.
