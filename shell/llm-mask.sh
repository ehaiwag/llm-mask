LLM_MASK_HOME="$HOME/.llm-mask"
LLM_MASK_SCRIPT="$LLM_MASK_HOME/bin/llm_mask.py"
LLM_MASK_PHRASES="$LLM_MASK_HOME/sensitive.txt"
LLM_MASK_MAPS="$LLM_MASK_HOME/maps"
LLM_MASK_LAST="$LLM_MASK_HOME/last_map"

# detect clipboard tool
if command -v pbcopy >/dev/null 2>&1; then
    CLIP_IN="pbpaste"
    CLIP_OUT="pbcopy"
elif command -v xclip >/dev/null 2>&1; then
    CLIP_IN="xclip -selection clipboard -o"
    CLIP_OUT="xclip -selection clipboard"
else
    echo "No clipboard tool found (pbcopy or xclip required)"
fi


maskclip() {

    local TEMP_PHRASE="${1:-}"

    mkdir -p "$LLM_MASK_MAPS"

    local TS
    TS="$(date +"%Y-%m-%d_%H%M%S")"
    local MAP_FILE="$LLM_MASK_MAPS/$TS.json"

    if [[ -n "$TEMP_PHRASE" ]]; then
        $CLIP_IN | python3 "$LLM_MASK_SCRIPT" mask \
            --map "$MAP_FILE" \
            --phrase-file "$LLM_MASK_PHRASES" \
            --phrase "$TEMP_PHRASE" \
            | $CLIP_OUT
    else
        $CLIP_IN | python3 "$LLM_MASK_SCRIPT" mask \
            --map "$MAP_FILE" \
            --phrase-file "$LLM_MASK_PHRASES" \
            | $CLIP_OUT
    fi

    echo "$MAP_FILE" > "$LLM_MASK_LAST"

    echo "[masked]"
    echo "map: $MAP_FILE"
}


unmaskclip() {

    local MAP_FILE="${1:-}"

    if [[ -z "$MAP_FILE" ]]; then
        MAP_FILE=$(cat "$LLM_MASK_LAST")
    fi

    $CLIP_IN | python3 "$LLM_MASK_SCRIPT" unmask \
        --map "$MAP_FILE" \
        | $CLIP_OUT

    echo "[restored]"
}
