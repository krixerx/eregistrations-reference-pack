#!/usr/bin/env bash
# Moves this pack to another core release: writes CORE_VERSION and the core
# images' digests in docker/core.conf and vendors that release's
# service-builder skill into .claude/skills/service-builder/ (the release
# asset service-builder-<version>.tar.gz). The images follow from core.conf;
# check the pack with the core's pack-check.sh afterwards (check.yml does).
# Reading the digests needs docker buildx (no daemon) and the registry.
#
#   scripts/update-core.sh <x.y.z>
set -euo pipefail

version="${1:-}"
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "usage: scripts/update-core.sh <x.y.z>" >&2
  exit 2
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
. "$root/docker/core.conf"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
# SERVICE_BUILDER_URL overrides the release asset (a mirror, or a local
# file:// archive built with the core's scripts/package-service-builder.mjs).
url="${SERVICE_BUILDER_URL:-https://github.com/$CORE_REPO/releases/download/v$version/service-builder-$version.tar.gz}"
echo "update-core: $url"
curl -fsSL "$url" -o "$tmp/skill.tar.gz"
tar -xzf "$tmp/skill.tar.gz" -C "$tmp"
if ! grep -qx "core $version" "$tmp/service-builder/VERSION"; then
  echo "update-core: the archive's VERSION does not name core $version" >&2
  exit 1
fi

# Resolved before anything is written, so a failure leaves the pack as it was.
# Keep the build-arg/image pairs in step with check.yml and publish.yml.
digests=""
for pair in ENGINE_CORE:cib7-core FRONTEND_CORE:frontend-core \
  BACKEND_CORE:backend-core MCP_CORE:mcp-core MOBILE_CORE:mobile-core; do
  image="$CORE_IMAGES/cib7-poc-${pair#*:}:$version"
  if ! digest="$(docker buildx imagetools inspect "$image" --format '{{.Manifest.Digest}}')" \
    || ! [[ "$digest" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    echo "update-core: cannot read the digest of $image" >&2
    exit 1
  fi
  echo "update-core: $image@$digest"
  digests+="${pair%%:*}_DIGEST=$digest"$'\n'
done

rm -rf "$root/.claude/skills/service-builder"
mkdir -p "$root/.claude/skills"
mv "$tmp/service-builder" "$root/.claude/skills/service-builder"
sed -i.bak -e "s/^CORE_VERSION=.*/CORE_VERSION=$version/" -e '/^[A-Z_]*_CORE_DIGEST=/d' \
  "$root/docker/core.conf"
rm -f "$root/docker/core.conf.bak"
printf '%s' "$digests" >> "$root/docker/core.conf"
echo "update-core: core $version ($(sed -n 's/^platform-api //p' "$root/.claude/skills/service-builder/VERSION")); check pack.yaml's platform"
