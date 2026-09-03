#!/usr/bin/env bash
set -euo pipefail
export PATH="/usr/local/go/bin:$PATH"
# Go's build cache uses $TMPDIR (defaults to /tmp), which during kickstart
# install can be a separate, small, constrained mount even when / itself
# has plenty of free space -- /var/tmp is FHS-conventional persistent disk
# space, not subject to that. mktemp also respects TMPDIR, so this covers
# both our own clone directory and Go's internal build-cache scratch dirs.
export TMPDIR=/var/tmp

echo "[kubectl] resolving latest stable release tag"
tag=$(git ls-remote --tags --refs https://github.com/kubernetes/kubernetes.git \
  | awk -F/ '{print $NF}' \
  | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
  | sort -V \
  | tail -n1)
echo "[kubectl] building ${tag} from source (large repo, this takes a while)"

tmp=$(mktemp -d)
git clone --depth 1 --branch "$tag" https://github.com/kubernetes/kubernetes.git "$tmp/kubernetes"
(
  cd "$tmp/kubernetes"
  make WHAT=cmd/kubectl
)

binary=$(find "$tmp/kubernetes/_output" -type f -name kubectl | head -n1)
if [[ -z "$binary" ]]; then
  echo "[kubectl] build did not produce a kubectl binary under _output" >&2
  exit 1
fi
cp "$binary" /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl
rm -rf "$tmp"
# unlike $TMPDIR scratch dirs (self-cleaning), Go's build/module cache under
# $HOME/.cache/go-build and $HOME/go/pkg/mod persists across builds and
# would otherwise bloat the final image for no future benefit
go clean -cache -modcache

echo "[kubectl] installed: $(/usr/local/bin/kubectl version --client --output=yaml | head -n2)"
