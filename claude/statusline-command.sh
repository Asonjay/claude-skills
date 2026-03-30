#!/usr/bin/env bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Build output: model + context bar
output=""

if [ -n "$model" ]; then
    output="${model}"
fi

if [ -n "$used" ]; then
    pct=$(printf '%.0f' "$used")
    # Progress bar
    BAR_WIDTH=15
    FILLED=$((pct * BAR_WIDTH / 100))
    EMPTY=$((BAR_WIDTH - FILLED))
    BAR=""
    [ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /▓}"
    [ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"
    output="${output} | ${BAR} ${pct}%"
fi

printf "%s" "$output"
