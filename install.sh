#!/usr/bin/env bash
set -e

INSTALL_DIR="$HOME/.llm-mask"
BIN_DIR="$INSTALL_DIR/bin"
MAP_DIR="$INSTALL_DIR/maps"

echo "Installing llm-mask..."

mkdir -p "$BIN_DIR"
mkdir -p "$MAP_DIR"

# copy python script
cp bin/llm_mask.py "$BIN_DIR/llm_mask.py"
chmod +x "$BIN_DIR/llm_mask.py"

# install shell helpers
mkdir -p "$INSTALL_DIR/shell"
cp shell/llm-mask.sh "$INSTALL_DIR/shell/llm-mask.sh"

# install config
if [ ! -f "$INSTALL_DIR/sensitive.txt" ]; then
    cp config/sensitive.example.txt "$INSTALL_DIR/sensitive.txt"
fi

# detect shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.bashrc"
fi

# add source line if not exists
if ! grep -q "llm-mask.sh" "$SHELL_RC"; then
    echo "" >> "$SHELL_RC"
    echo "# llm-mask" >> "$SHELL_RC"
    echo "source $INSTALL_DIR/shell/llm-mask.sh" >> "$SHELL_RC"
fi

echo "Installation complete."
echo ""
echo "Restart your shell or run:"
echo "source $SHELL_RC"
