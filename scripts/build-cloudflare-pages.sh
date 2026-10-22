#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# npm rather than bun, matching CI: a `package-lock.json` is maintained here and
# a `bun.lock` is not, so with bun a dependency bump arrives as a manifest the
# lockfile does not match.
#
# `npm ci` on both, where docs used to run a plain `bun install`: that resolved
# whatever was newest at deploy time, so what the site was built from was not
# what any pull request had checked.
cd "$ROOT_DIR/website"
npm ci
npm run build

cd "$ROOT_DIR/docs"
npm ci
npm run build

rm -rf "$ROOT_DIR/website/dist/docs"
mkdir -p "$ROOT_DIR/website/dist/docs"
cp -R "$ROOT_DIR/docs/dist/." "$ROOT_DIR/website/dist/docs/"
