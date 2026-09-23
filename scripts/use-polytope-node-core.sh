#!/bin/bash
# Build @subql/node-core from a polytope-labs/subql checkout and point @subql/node-ethereum at it instead of npm.
# The packed tarball is written to vendor/subql-node-core.tgz, which packages/node/polytope/Dockerfile installs from.
#
# Usage: scripts/use-polytope-node-core.sh <path to polytope-labs/subql checkout>
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <path to polytope-labs/subql checkout>" >&2
  exit 1
fi

SUBQL_DIR=$(cd "$1" && pwd)
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TARBALL="$ROOT/vendor/subql-node-core.tgz"

mkdir -p "$ROOT/vendor"
rm -f "$TARBALL"

# Packing replaces node-core's workspace dependencies with their versions, which resolve from npm
(
  cd "$SUBQL_DIR"
  yarn install
  # typescript is a root dependency, so build from the root; -b also builds node-core's workspace references
  yarn tsc -b packages/node-core
  yarn workspace @subql/node-core pack --out "$TARBALL"
)

cd "$ROOT"
jq '.dependencies["@subql/node-core"] = "file:../../vendor/subql-node-core.tgz"' packages/node/package.json \
  > packages/node/package.tmp.json
mv packages/node/package.tmp.json packages/node/package.json

echo "@subql/node-ethereum now uses @subql/node-core $(tar -xzOf "$TARBALL" package/package.json | jq -r .version) from $SUBQL_DIR ($(git -C "$SUBQL_DIR" rev-parse --short HEAD))"
