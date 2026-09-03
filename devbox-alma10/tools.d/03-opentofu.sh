#!/usr/bin/env bash
set -euo pipefail
export PATH="/usr/local/go/bin:$PATH"
# Go's build cache uses $TMPDIR (defaults to /tmp), which during kickstart
# install can be a separate, small, constrained mount even when / itself
# has plenty of free space -- /var/tmp is FHS-conventional persistent disk
# space, not subject to that. mktemp also respects TMPDIR, so this covers
# both our own clone directory and Go's internal build-cache scratch dirs.
export TMPDIR=/var/tmp
export GOPATH=/var/tmp/go
export GOCACHE=/var/tmp/go-build-cache

echo "[opentofu] resolving latest release"
tag=$(git ls-remote --tags --refs https://github.com/opentofu/opentofu.git \
  | awk -F/ '{print $NF}' \
  | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
  | sort -V \
  | tail -n1)
echo "[opentofu] building ${tag} from source"

tmp=$(mktemp -d)
git clone --depth 1 --branch "$tag" https://github.com/opentofu/opentofu.git "$tmp/opentofu"
(
  cd "$tmp/opentofu"
  # -tags http2legacy works around a known x/net v0.54.0 + Go 1.27
  # incompatibility (golang/go#79503): x/net's http2 server split its
  # implementation across two files gated by Go version, and the go1.27
  # path dropped the TrailerPrefix symbol grpc (an OpenTofu transitive
  # dependency) still references. This tag forces the old code path back
  # on regardless of Go version -- the ecosystem's own sanctioned bridge
  # for this, not a hack. Fixed properly upstream in x/net v0.55.0+.
  go build -tags http2legacy -o tofu ./cmd/tofu
)

if [[ ! -f "$tmp/opentofu/tofu" ]]; then
  echo "[opentofu] build did not produce a tofu binary" >&2
  exit 1
fi
cp "$tmp/opentofu/tofu" /usr/local/bin/tofu
chmod +x /usr/local/bin/tofu
rm -rf "$tmp"
# unlike $TMPDIR scratch dirs (self-cleaning), Go's build/module cache under
# $HOME/.cache/go-build and $HOME/go/pkg/mod persists across builds and
# would otherwise bloat the final image for no future benefit
go clean -cache -modcache

echo "[opentofu] installed: $(/usr/local/bin/tofu --version | head -n1)"
