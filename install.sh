#!/usr/bin/env bash
set -euo pipefail

OWNER="ehaiwag"
REPO="llm-mask"
BRANCH="main"

INSTALL_DIR="$HOME/.llm-mask"
BIN_DIR="$INSTALL_DIR/bin"
SHELL_DIR="$INSTALL_DIR/shell"
MAP_DIR="$INSTALL_DIR/maps"

RAW_BASE="https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}"

echo "Installing llm-mask..."

mkdir -p "$BIN_DIR" "$SHELL_DIR" "$MAP_DIR"

download() {
  local url="$1"
  local out="$2"
  curl -fsSL "$url" -o "$out"
}

# 1) Download required files (no repo clone needed)
download "$RAW_BASE/bin/llm_mask.py" "$BIN_DIR/llm_mask.py"
chmod +x "$BIN_DIR/llm_mask.py"

download "$RAW_BASE/shell/llm-mask.sh" "$SHELL_DIR/llm-mask.sh"

# 2) Install default sensitive.txt if missing
if [[ ! -f "$INSTALL_DIR/sensitive.txt" ]]; then
  download "$RAW_BASE/config/sensitive.example.txt" "$INSTALL_DIR/sensitive.txt"
fi

# 3) Decide which rc file to modify
# - curl|bash runs in bash, so ZSH_VERSION is usually empty.
# - Use $SHELL first; fall back to whichever rc exists; else default to .zshrc.
RC_FILE=""

if [[ "${SHELL:-}" == *"zsh"* ]]; then
  RC_FILE="$HOME/.zshrc"
elif [[ "${SHELL:-}" == *"bash"* ]]; then
  # Prefer bashrc on linux, but macOS may use bash_profile
  if [[ -f "$HOME/.bashrc" ]]; then
    RC_FILE="$HOME/.bashrc"
  else
    RC_FILE="$HOME/.bash_profile"
  fi
else
  # Fallback: if user already has zshrc, use it; else bashrc; else zshrc.
  if [[ -f "$HOME/.zshrc" ]]; then
    RC_FILE="$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then
    RC_FILE="$HOME/.bashrc"
  else
    RC_FILE="$HOME/.zshrc"
  fi
fi

# Ensure rc file exists so grep never errors
touch "$RC_FILE"

SOURCE_LINE="source \"$SHELL_DIR/llm-mask.sh\""

# 4) Add source line idempotently (quietly)
if ! grep -Fq "$SOURCE_LINE" "$RC_FILE" 2>/dev/null; then
  {
    echo ""
    echo "# llm-mask"
    echo "$SOURCE_LINE"
  } >> "$RC_FILE"
fi

# 5) Helpful clipboard check (non-fatal)
if command -v pbcopy >/dev/null 2>&1; then
  :
elif command -v xclip >/dev/null 2>&1; then
  :
else
  echo "[WARN] No clipboard tool found."
  echo "       macOS: pbcopy/pbpaste should exist by default"
  echo "       Linux: please install xclip (e.g. sudo apt install xclip)"
fi

echo "Installation complete."
echo ""
echo "Restart your shell or run:"
echo "source \"$RC_FILE\""
echo ""
echo "Then try:"
echo "maskclip"
echo "unmaskclip"
