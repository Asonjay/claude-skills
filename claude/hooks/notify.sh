#!/bin/bash
# Claude Code notification hook
#
# Configure via env vars in settings.json:
#   CLAUDE_NOTIFY_METHOD: "desktop" (default) or "ntfy"
#   CLAUDE_NTFY_TOPIC:    your ntfy.sh topic (required if method is "ntfy")

NOTIFY_METHOD="${CLAUDE_NOTIFY_METHOD:-desktop}"

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')

MSG=""
case "$EVENT" in
  Stop)
    MSG="Finished generating response"
    ;;
  PermissionRequest)
    TOOL=$(echo "$INPUT" | jq -r '.tool_name // "a tool"')
    MSG="Waiting for permission to use: $TOOL"
    ;;
  Notification)
    TYPE=$(echo "$INPUT" | jq -r '.notification_type // empty')
    case "$TYPE" in
      permission_prompt)
        MSG="Waiting for permission"
        ;;
      idle_prompt)
        MSG="Waiting for input"
        ;;
      elicitation_dialog)
        MSG="Asking a question — check the terminal"
        ;;
      *)
        MSG=$(echo "$INPUT" | jq -r '.message // "Needs your attention"')
        ;;
    esac
    ;;
esac

if [ -z "$MSG" ]; then
  exit 0
fi

case "$NOTIFY_METHOD" in
  ntfy)
    if [ -n "$CLAUDE_NTFY_TOPIC" ]; then
      curl -s -d "$MSG" "ntfy.sh/$CLAUDE_NTFY_TOPIC" &>/dev/null &
    fi
    ;;
  desktop|*)
    export DISPLAY="${DISPLAY:-:20}"
    notify-send -u normal -i dialog-information "Claude Code" "$MSG" 2>/dev/null
    SOUND=""
    case "$EVENT" in
      Stop) SOUND="/usr/share/sounds/Yaru/stereo/complete.oga" ;;
      PermissionRequest) SOUND="/usr/share/sounds/Yaru/stereo/dialog-question.oga" ;;
      Notification) SOUND="/usr/share/sounds/Yaru/stereo/message-new-instant.oga" ;;
    esac
    if [ -n "$SOUND" ]; then
      paplay "$SOUND" &>/dev/null &
    fi
    ;;
esac

exit 0
