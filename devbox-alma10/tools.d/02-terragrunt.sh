#!/usr/bin/env bash
set -euo pipefail
export PATH="/usr/local/go/bin:$PATH"
# Go's build cache uses $TMPDIR (defaults to /tmp), which during kickstart
# install can be a separate, small, constrained mount even when / itself
# has plenty of free space -- /var/tmp is FHS-conventional persistent disk
# space, not subject to that. mktemp also respects TMPDIR, so this covers
# both our own clone directory and Go's internal build-cache scratch dirs.
export TMPDIR=/var/tmp

echo "[terragrunt] resolving latest release"
tag=$(git ls-remote --tags --refs https://github.com/gruntwork-io/terragrunt.git \
  | awk -F/ '{print $NF}' \
  | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
  | sort -V \
  | tail -n1)
echo "[terragrunt] building ${tag} from source"

tmp=$(mktemp -d)
git clone --depth 1 --branch "$tag" https://github.com/gruntwork-io/terragrunt.git "$tmp/terragrunt"
(
  cd "$tmp/terragrunt"
  make build
)

if [[ ! -f "$tmp/terragrunt/terragrunt" ]]; then
  echo "[terragrunt] build did not produce a terragrunt binary" >&2
  exit 1
fi
cp "$tmp/terragrunt/terragrunt" /usr/local/bin/terragrunt
chmod +x /usr/local/bin/terragrunt
rm -rf "$tmp"
# unlike $TMPDIR scratch dirs (self-cleaning), Go's build/module cache under
# $HOME/.cache/go-build and $HOME/go/pkg/mod persists across builds and
# would otherwise bloat the final image for no future benefit
go clean -cache -modcache

echo "[terragrunt] installed: $(/usr/local/bin/terragrunt --version)"
