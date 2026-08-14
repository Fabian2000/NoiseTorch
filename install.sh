#!/usr/bin/env bash
#
# NoiseTorch installer (PipeWire-fix build).
#
# Installs the binary, desktop entry and icon into the user's home directory and
# the RNNoise LADSPA plugin into a system LADSPA directory. Re-run it to update
# an existing installation; this build has no self-updater.
#
#   ./install.sh              install or update
#   ./install.sh --uninstall  remove everything it installed
#
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
DESKTOP_DIR="$DATA_DIR/applications"
ICON_DIR="$DATA_DIR/icons/hicolor/256x256/apps"

info() { printf '\033[1;34m::\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1" >&2; }
die()  { printf '\033[1;31mXX\033[0m %s\n' "$1" >&2; exit 1; }

# PipeWire >= 1.6 only looks up LADSPA plugins by name inside the LADSPA
# directories; absolute paths are no longer accepted. Pick the first directory
# that exists, preferring the one matching the system's library layout.
find_ladspa_dir() {
	local dir
	for dir in "${LADSPA_PATH//:/ }" /usr/lib64/ladspa /usr/lib/ladspa \
	           /usr/lib/x86_64-linux-gnu/ladspa; do
		[ -n "$dir" ] && [ -d "$dir" ] && { printf '%s' "$dir"; return 0; }
	done
	return 1
}

# Run a command as root, but only when it is actually necessary — if the target
# directory is already writable, do not ask for a password at all.
as_root() {
	if [ -w "$LADSPA_DIR" ]; then
		"$@"
	elif [ "$(id -u)" -eq 0 ]; then
		"$@"
	elif command -v sudo >/dev/null 2>&1; then
		sudo "$@"
	elif command -v pkexec >/dev/null 2>&1; then
		pkexec "$@"
	else
		die "Need root to write to $LADSPA_DIR, but neither sudo nor pkexec was found."
	fi
}

LADSPA_DIR="$(find_ladspa_dir)" || die "No LADSPA directory found. Install a LADSPA package (e.g. ladspa) and retry."

if [ "${1:-}" = "--uninstall" ]; then
	info "Removing NoiseTorch"
	rm -f "$BIN_DIR/noisetorch" \
	      "$DESKTOP_DIR/noisetorch.desktop" \
	      "$ICON_DIR/noisetorch.png"
	if [ -f "$LADSPA_DIR/nt-filter.so" ]; then
		info "Removing $LADSPA_DIR/nt-filter.so"
		as_root rm -f "$LADSPA_DIR/nt-filter.so"
	fi
	command -v update-desktop-database >/dev/null 2>&1 && \
		update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
	info "Done. Your config in ~/.config/noisetorch was left untouched."
	exit 0
fi

for f in noisetorch nt-filter.so noisetorch.desktop noisetorch.png; do
	[ -f "$SRC/$f" ] || die "Missing $f next to this script — extract the whole archive first."
done

if pgrep -x noisetorch >/dev/null 2>&1; then
	warn "NoiseTorch is running. Close it before updating, otherwise the running"
	warn "instance keeps the old binary until you restart it."
fi

info "Installing binary to $BIN_DIR/noisetorch"
install -Dm755 "$SRC/noisetorch" "$BIN_DIR/noisetorch"

info "Installing desktop entry and icon"
# Point Exec at the absolute path: the desktop session's PATH does not
# necessarily include ~/.local/bin, which would leave a launcher that silently
# does nothing.
install -Dm644 "$SRC/noisetorch.desktop" "$DESKTOP_DIR/noisetorch.desktop"
sed -i "s|^Exec=noisetorch$|Exec=$BIN_DIR/noisetorch|" "$DESKTOP_DIR/noisetorch.desktop"
install -Dm644 "$SRC/noisetorch.png" "$ICON_DIR/noisetorch.png"
command -v update-desktop-database >/dev/null 2>&1 && \
	update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true

info "Installing LADSPA plugin to $LADSPA_DIR/nt-filter.so"
as_root install -Dm755 "$SRC/nt-filter.so" "$LADSPA_DIR/nt-filter.so"

case ":$PATH:" in
	*":$BIN_DIR:"*) ;;
	*) warn "$BIN_DIR is not in your PATH — add it to run 'noisetorch' from a shell." ;;
esac

info "Done."
echo
echo "  Start NoiseTorch from your application menu or run: noisetorch"
echo "  On first start it asks for your password once, to grant itself"
echo "  CAP_SYS_RESOURCE (needed to raise its memlock limit)."
echo
echo "  This build has no self-updater. To update, download the newer release"
echo "  and run ./install.sh again. To remove it: ./install.sh --uninstall"
