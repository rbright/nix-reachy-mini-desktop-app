#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage:
  ${0} [--version <version>] [--file <path>]

Examples:
  ${0}
  ${0} --version 0.9.20
  ${0} --version v0.9.20
  ${0} --file ${script_dir}/../package.nix

Environment overrides:
  REACHY_REPO_OWNER   GitHub owner (default: pollen-robotics)
  REACHY_REPO_NAME    GitHub repo (default: reachy-mini-desktop-app)
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

version=""
target_file="${script_dir}/../package.nix"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      version="${2:-}"
      shift 2
      ;;
    --file)
      target_file="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

repo_owner="${REACHY_REPO_OWNER:-pollen-robotics}"
repo_name="${REACHY_REPO_NAME:-reachy-mini-desktop-app}"

require_cmd git
require_cmd jq
require_cmd nix
require_cmd perl

if [[ ! -f "$target_file" ]]; then
  echo "Target file not found: $target_file" >&2
  exit 1
fi

if [[ -z "$version" ]]; then
  latest_tag="$({
    git ls-remote --tags --refs "https://github.com/${repo_owner}/${repo_name}.git" 'v*'
  } | awk '{ print $2 }' | sed 's@refs/tags/@@' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)"

  if [[ -z "$latest_tag" ]]; then
    echo "Failed to resolve latest stable tag from ${repo_owner}/${repo_name}" >&2
    exit 1
  fi

  version="${latest_tag#v}"
fi

version="${version#v}"
if [[ -z "$version" ]]; then
  echo "Resolved version is empty" >&2
  exit 1
fi

tag="v${version}"
source_url="https://github.com/${repo_owner}/${repo_name}/releases/download/${tag}/Reachy.Mini.Control_${version}_amd64.deb"

source_hash="$(
  nix store prefetch-file --json "$source_url" | jq -r '.hash'
)"

if [[ ! "$source_hash" =~ ^sha256- ]]; then
  echo "Failed to resolve source hash from: $source_url" >&2
  exit 1
fi

echo "Updating Reachy Mini Desktop App package definition"
echo "  repo:    ${repo_owner}/${repo_name}"
echo "  version: ${version}"

VERSION="$version" perl -0pi -e 's/(\n\s*version = )"[^"]+";/$1 . "\"" . $ENV{VERSION} . "\";"/e' "$target_file"
SOURCE_HASH="$source_hash" perl -0pi -e 's/(src = fetchurl \{.*?\n\s*hash = )"sha256-[^"]+";/$1 . "\"" . $ENV{SOURCE_HASH} . "\";"/se' "$target_file"

echo "Updated: $target_file"
echo "  version:  ${version}"
echo "  src.hash: ${source_hash}"
