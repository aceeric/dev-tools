#!/usr/bin/env bash
set -euo pipefail

echo "[golang] resolving latest version"
version_output=$(curl -fsSL "https://go.dev/VERSION?m=text")
version=$(printf '%s' "$version_output" | head -n1)
echo "[golang] installing ${version}"

tmp=$(mktemp -d)
curl -fsSL "https://go.dev/dl/${version}.linux-amd64.tar.gz" -o "$tmp/go.tar.gz"
rm -rf /usr/local/go
tar -C /usr/local -xzf "$tmp/go.tar.gz"
rm -rf "$tmp"

cat > /etc/profile.d/golang.sh <<'EOF'
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF

echo "[golang] installed: $(/usr/local/go/bin/go version)"
