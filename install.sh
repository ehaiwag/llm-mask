#!/usr/bin/env bash
set -euo pipefail

# =========
# Config
# =========
OWNER="ehaiwag"
REPO="llm-mask"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}"

INSTALL_DIR_DEFAULT="$HOME/.llm-mask"

usage() {
  cat <<'EOF'
llm-mask installer

Usage:
  curl -fsSL https://raw.githubusercontent.com/ehaiwag/llm-mask/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/ehaiwag/llm-mask/main/install.sh | bash -s -- --clean
  curl -fsSL https://raw.githubusercontent.com/ehaiwag/llm-mask/main/install.sh | bash -s -- --uninstall
  curl -fsSL https://raw.githubusercontent.com/ehaiwag/llm-mask/main/install.sh | bash -s -- --prefix ~/.local/llm-mask
  curl -fsSL https://raw.githubusercontent.com/ehaiwag/llm-mask/main/install.sh | bash -s -- --quiet

Options:
  --clean        Remove existing installation directory before installing.
  --uninstall    Remove installation directory and shell rc hook.
  --prefix PATH  Install to PATH (default: ~/.llm-mask).
  --quiet        Less output.
EOF
}

log() { [[ "${QUIET:-0}" == "1" ]] || echo "$@"; }
warn() { echo "[WARN] $@" >&2; }
die() { echo "[ERROR] $@" >&2; exit 1; }

download() {
  local url="$1"
  local out="$2"
  curl -fsSL "$url" -o "$out"
}

detect_rc_file() {
  # Prefer $SHELL, then existing rc files.
  local shell_path="${SHELL:-}"
  if [[ "$shell_path" == *"zsh"* ]]; then
    echo "$HOME/.zshrc"
    return
  fi
  if [[ "$shell_path" == *"bash"* ]]; then
    # Linux usually uses .bashrc; macOS bash often uses .bash_profile
    if [[ -f "$HOME/.bashrc" ]]; then
      echo "$HOME/.bashrc"
    else
      echo "$HOME/.bash_profile"
    fi
    return
  fi

  # Fallback
  if [[ -f "$HOME/.zshrc" ]]; then
    echo "$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then
    echo "$HOME/.bashrc"
  elif [[ -f "$HOME/.bash_profile" ]]; then
    echo "$HOME/.bash_profile"
  else
    echo "$HOME/.zshrc"
  fi
}

ensure_rc_hook() {
  local rc_file="$1"
  local hook_line="$2"

  touch "$rc_file"

  if ! grep -Fq "$hook_line" "$rc_file" 2>/dev/null; then
    {
      echo ""
      echo "# llm-mask"
      echo "$hook_line"
    } >> "$rc_file"
  fi
}

remove_rc_hook() {
  local rc_file="$1"
  local hook_line="$2"

  [[ -f "$rc_file" ]] || return 0

  # Remove exact hook line and the optional "# llm-mask" comment line near it.
  # Keep it safe and minimal: create a backup then rewrite.
  local tmp="${rc_file}.llm-mask.tmp"
  awk -v hook="$hook_line" '
    $0 == hook { next }
    $0 == "# llm-mask" { next }
    { print }
  ' "$rc_file" > "$tmp" && mv "$tmp" "$rc_file"
}

check_clipboard() {
  if command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1; then
    log "[OK] Clipboard: pbcopy/pbpaste (macOS)"
    return
  fi
  if command -v xclip >/dev/null 2>&1; then
    log "[OK] Clipboard: xclip (Linux)"
    return
  fi
  warn "No clipboard tool found."
  warn "  macOS: pbcopy/pbpaste should exist by default"
  warn "  Linux: install xclip (e.g. sudo apt install xclip)"
}

# =========
# Parse args
# =========
INSTALL_DIR="$INSTALL_DIR_DEFAULT"
CLEAN=0
UNINSTALL=0
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --clean) CLEAN=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --prefix)
      [[ $# -ge 2 ]] || die "--prefix requires a path"
      INSTALL_DIR="$2"
      shift 2
      ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1 (use --help)" ;;
  esac
done

BIN_DIR="$INSTALL_DIR/bin"
SHELL_DIR="$INSTALL_DIR/shell"
MAP_DIR="$INSTALL_DIR/maps"
PHRASES_FILE="$INSTALL_DIR/sensitive.txt"

RC_FILE="$(detect_rc_file)"
HOOK_LINE="source \"$SHELL_DIR/llm-mask.sh\""

# =========
# Uninstall
# =========
if [[ "$UNINSTALL" == "1" ]]; then
  log "Uninstalling llm-mask..."
  remove_rc_hook "$RC_FILE" "$HOOK_LINE"
  if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
    log "[OK] Removed: $INSTALL_DIR"
  else
    log "[OK] Nothing to remove at: $INSTALL_DIR"
  fi
  log "Done."
  exit 0
fi

# =========
# Install
# =========
log "Installing llm-mask..."
log "  Install dir: $INSTALL_DIR"
log "  Shell rc:    $RC_FILE"

if [[ "$CLEAN" == "1" && -d "$INSTALL_DIR" ]]; then
  log "Cleaning existing installation: $INSTALL_DIR"
  rm -rf "$INSTALL_DIR"
fi

mkdir -p "$BIN_DIR" "$SHELL_DIR" "$MAP_DIR"

# Download required files (no repo clone needed)
download "$RAW_BASE/bin/llm_mask.py" "$BIN_DIR/llm_mask.py"
chmod +x "$BIN_DIR/llm_mask.py"

download "$RAW_BASE/shell/llm-mask.sh" "$SHELL_DIR/llm-mask.sh"

# Install default sensitive.txt only if missing (upgrade-safe)
if [[ ! -f "$PHRASES_FILE" ]]; then
  download "$RAW_BASE/config/sensitive.example.txt" "$PHRASES_FILE"
fi

# Ensure rc hook
ensure_rc_hook "$RC_FILE" "$HOOK_LINE"

check_clipboard

log ""
log "Installation complete."
log ""
log "Next:"
log "  source \"$RC_FILE\""
log "  maskclip"
log "  unmaskclip"
