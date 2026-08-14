#!/usr/bin/env bash
#
# NoiseTorch bootstrap installer.
#
#   curl -fsSL https://raw.githubusercontent.com/Fabian2000/NoiseTorch/master/get.sh | bash
#
# Downloads the latest release, verifies its checksum and runs the installer
# contained in the archive. Set VERSION=v0.12.3 to install a specific release.
#
set -euo pipefail

REPO="Fabian2000/NoiseTorch"
VERSION="${VERSION:-latest}"

info() { printf '\033[1;34m::\033[0m %s\n' "$1"; }
die()  { printf '\033[1;31mXX\033[0m %s\n' "$1" >&2; exit 1; }

for cmd in curl tar sha512sum; do
	command -v "$cmd" >/dev/null 2>&1 || die "'$cmd' is required but not installed."
done

[ "$(uname -s)" = "Linux" ] || die "NoiseTorch only runs on Linux."
[ "$(uname -m)" = "x86_64" ] || die "Only x86_64 is supported, this is $(uname -m)."

if [ "$VERSION" = "latest" ]; then
	info "Looking up the latest release"
	VERSION="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
		| sed -n 's/.*"tag_name" *: *"\([^"]*\)".*/\1/p' | head -n1)"
	[ -n "$VERSION" ] || die "Could not determine the latest release."
fi

TARBALL="NoiseTorch_x64_${VERSION}.tgz"
BASE="https://github.com/$REPO/releases/download/$VERSION"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

info "Downloading $TARBALL"
curl -fsSL -o "$TMP/$TARBALL" "$BASE/$TARBALL" \
	|| die "Download failed. Does release $VERSION exist?"

# The releases are not signed; verifying the published checksum at least rules
# out a truncated or corrupted download.
info "Verifying checksum"
curl -fsSL -o "$TMP/$TARBALL.sha512sum" "$BASE/$TARBALL.sha512sum" \
	|| die "Could not download the checksum file."
# The checksum file records the path as it was during the build (bin/...), so
# compare the bare hash against the file we actually downloaded.
( cd "$TMP" && printf '%s  %s\n' \
	"$(awk 'NR==1{print $1}' "$TARBALL.sha512sum")" "$TARBALL" \
	| sha512sum -c --quiet - ) \
	|| die "Checksum mismatch — refusing to install."

info "Unpacking"
tar -xzf "$TMP/$TARBALL" -C "$TMP"

DIR="$TMP/NoiseTorch_x64_${VERSION}"
[ -x "$DIR/install.sh" ] || die "Archive does not contain install.sh."

# Hand the installer a real terminal: when this script is piped into bash, its
# own stdin is the pipe, and sudo inside the installer needs the tty anyway.
info "Running installer"
if [ ! -t 0 ] && { exec 3</dev/tty; } 2>/dev/null; then
	"$DIR/install.sh" <&3
	exec 3<&-
else
	"$DIR/install.sh"
fi
