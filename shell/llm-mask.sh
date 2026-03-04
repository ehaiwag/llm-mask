LLM_MASK_HOME="${LLM_MASK_HOME:-$HOME/.llm-mask}"
LLM_MASK_SCRIPT="$LLM_MASK_HOME/bin/llm_mask.py"
LLM_MASK_PHRASES="$LLM_MASK_HOME/sensitive.txt"
LLM_MASK_MAPS="$LLM_MASK_HOME/maps"
LLM_MASK_LAST="$LLM_MASK_HOME/last_map"

# Clipboard detection (macOS / Linux)
if command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1; then
  CLIP_IN="pbpaste"
  CLIP_OUT="pbcopy"
elif command -v xclip >/dev/null 2>&1; then
  CLIP_IN="xclip -selection clipboard -o"
  CLIP_OUT="xclip -selection clipboard"
else
  CLIP_IN=""
  CLIP_OUT=""
fi

_llm_mask_need_clipboard() {
  if [[ -z "$CLIP_IN" || -z "$CLIP_OUT" ]]; then
    echo "[ERROR] No clipboard tool found."
    echo "        macOS: pbcopy/pbpaste"
    echo "        Linux: install xclip (sudo apt install xclip)"
    return 1
  fi
  return 0
}

maskclip() {
  # usage:
  #   maskclip
  #   maskclip "temp1,temp2"
  local TEMP_PHRASE="${1:-}"

  _llm_mask_need_clipboard || return 1

  mkdir -p "$LLM_MASK_MAPS" "$LLM_MASK_HOME"
  [[ -f "$LLM_MASK_PHRASES" ]] || : > "$LLM_MASK_PHRASES"

  local TS
  TS="$(date +"%Y-%m-%d_%H%M%S")"
  local MAP_FILE="$LLM_MASK_MAPS/$TS.json"

  if [[ -n "$TEMP_PHRASE" ]]; then
    eval "$CLIP_IN" | python3 "$LLM_MASK_SCRIPT" mask \
      --map "$MAP_FILE" \
      --phrase-file "$LLM_MASK_PHRASES" \
      --phrase "$TEMP_PHRASE" \
      | eval "$CLIP_OUT"
  else
    eval "$CLIP_IN" | python3 "$LLM_MASK_SCRIPT" mask \
      --map "$MAP_FILE" \
      --phrase-file "$LLM_MASK_PHRASES" \
      | eval "$CLIP_OUT"
  fi

  echo "$MAP_FILE" > "$LLM_MASK_LAST"
  echo "[OK] masked -> clipboard"
  echo "     map: $MAP_FILE"
  [[ -n "$TEMP_PHRASE" ]] && echo "     temp: $TEMP_PHRASE"
}

unmaskclip() {
  # usage:
  #   unmaskclip
  #   unmaskclip /path/to/map.json
  local MAP_FILE="${1:-}"

  _llm_mask_need_clipboard || return 1

  if [[ -z "$MAP_FILE" ]]; then
    [[ -f "$LLM_MASK_LAST" ]] || { echo "[ERROR] last_map not found. Run maskclip first."; return 1; }
    MAP_FILE="$(cat "$LLM_MASK_LAST")"
  fi
  [[ -f "$MAP_FILE" ]] || { echo "[ERROR] map not found: $MAP_FILE"; return 1; }

  eval "$CLIP_IN" | python3 "$LLM_MASK_SCRIPT" unmask --map "$MAP_FILE" | eval "$CLIP_OUT"
  echo "[OK] unmasked -> clipboard"
  echo "     map: $MAP_FILE"
}
