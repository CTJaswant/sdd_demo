#!/usr/bin/env bash
# Usage: bash lint.sh <target_path> [--json]
# Lints TypeScript/React files. Installs deps on first run into /tmp/ts-review-lint.
set -euo pipefail

TARGET="${1:-.}"
FORMAT="${2:---format=stylish}"
[[ "$FORMAT" == "--json" ]] && FORMAT="--format=json"

WORKDIR="/tmp/ts-review-lint"

# Bootstrap once
if [[ ! -f "$WORKDIR/node_modules/.bin/eslint" ]]; then
  mkdir -p "$WORKDIR"
  cd "$WORKDIR"
  npm init -y --silent > /dev/null
  npm install --silent --save-dev \
    eslint@8 \
    @typescript-eslint/parser \
    @typescript-eslint/eslint-plugin \
    eslint-plugin-react \
    eslint-plugin-react-hooks \
    > /dev/null 2>&1
fi

# Write minimal config
cat > "$WORKDIR/.eslintrc.json" << 'EOF'
{
  "parser": "@typescript-eslint/parser",
  "parserOptions": { "ecmaFeatures": { "jsx": true }, "ecmaVersion": "latest" },
  "plugins": ["@typescript-eslint", "react", "react-hooks"],
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended"
  ],
  "settings": { "react": { "version": "detect" } },
  "rules": {
    "react/react-in-jsx-scope": "off",
    "react/prop-types": "off",
    "@typescript-eslint/no-explicit-any": "warn",
    "@typescript-eslint/no-unused-vars": "warn"
  },
  "env": { "browser": true, "es2021": true }
}
EOF

exec "$WORKDIR/node_modules/.bin/eslint" \
  --no-eslintrc \
  --config "$WORKDIR/.eslintrc.json" \
  --ext .ts,.tsx \
  $FORMAT \
  "$TARGET"