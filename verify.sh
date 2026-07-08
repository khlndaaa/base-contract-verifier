#!/usr/bin/env bash
# Automatic contract verifier for Base, via Foundry + Blockscout Pro API.
# Reads contracts.json and runs `forge verify-contract` for every entry
# that has a non-empty address.

set -euo pipefail

CONFIG_FILE="${1:-contracts.json}"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Config file $CONFIG_FILE not found"
  exit 1
fi

if [ -z "${BLOCKSCOUT_API_KEY:-}" ]; then
  echo "❌ BLOCKSCOUT_API_KEY secret is not set"
  exit 1
fi

NETWORK=$(jq -r '.network' "$CONFIG_FILE")
COUNT=$(jq '.contracts | length' "$CONFIG_FILE")

echo "🔍 Network: $NETWORK | Contracts in list: $COUNT"

FAILED=0

for i in $(seq 0 $((COUNT - 1))); do
  NAME=$(jq -r ".contracts[$i].name" "$CONFIG_FILE")
  CONTRACT_PATH=$(jq -r ".contracts[$i].path" "$CONFIG_FILE")
  ADDRESS=$(jq -r ".contracts[$i].address" "$CONFIG_FILE")
  CTOR_ARGS=$(jq -r ".contracts[$i].constructorArgs // \"\"" "$CONFIG_FILE")

  if [ -z "$ADDRESS" ] || [ "$ADDRESS" = "null" ]; then
    echo "⏭️  [$NAME] no address set in contracts.json — skipping"
    continue
  fi

  echo ""
  echo "▶️  Verifying $NAME ($CONTRACT_PATH) at address $ADDRESS ..."

  CMD=(forge verify-contract
    "$ADDRESS"
    "$CONTRACT_PATH"
    --chain "$NETWORK"
    --verifier etherscan
    --etherscan-api-key "$BLOCKSCOUT_API_KEY"
    --watch)

  if [ -n "$CTOR_ARGS" ] && [ "$CTOR_ARGS" != "null" ]; then
    CMD+=(--constructor-args "$CTOR_ARGS")
  fi

  if "${CMD[@]}"; then
    echo "✅ [$NAME] verified successfully"
  else
    echo "❌ [$NAME] verification failed"
    FAILED=1
  fi
done

if [ "$FAILED" -eq 1 ]; then
  echo ""
  echo "⚠️  One or more contracts failed to verify. See the log above."
  exit 1
fi

echo ""
echo "🎉 Done."
