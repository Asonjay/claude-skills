#!/bin/bash
# Claude Code notification hook
# Plays distinct sounds + shows auto-dismissing notifications

# Chrome Remote Desktop runs on :20
export DISPLAY=:20

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')

SOUND=""
MSG=""
case "$EVENT" in
  Stop)
    SOUND="/usr/share/sounds/Yaru/stereo/complete.oga"
    MSG="Finished generating response"
    ;;
  PermissionRequest)
    TOOL=$(echo "$INPUT" | jq -r '.tool_name // "a tool"')
    SOUND="/usr/share/sounds/Yaru/stereo/dialog-question.oga"
    MSG="Waiting for permission to use: $TOOL"
    ;;
  Notification)
    TYPE=$(echo "$INPUT" | jq -r '.notification_type // empty')
    case "$TYPE" in
      permission_prompt)
        SOUND="/usr/share/sounds/Yaru/stereo/dialog-question.oga"
        MSG="Waiting for permission"
        ;;
      idle_prompt)
        SOUND="/usr/share/sounds/Yaru/stereo/message-new-instant.oga"
        MSG="Waiting for input"
        ;;
      elicitation_dialog)
        SOUND="/usr/share/sounds/Yaru/stereo/dialog-question.oga"
        MSG="Asking a question — check the terminal"
        ;;
      *)
        SOUND="/usr/share/sounds/Yaru/stereo/bell.oga"
        MSG=$(echo "$INPUT" | jq -r '.message // "Needs your attention"')
        ;;
    esac
    ;;
esac

# Show auto-dismissing notification (normal urgency = auto-dismiss)
if [ -n "$MSG" ]; then
  notify-send -u normal -i dialog-information "Claude Code" "$MSG"
fi

# Play the sound (non-blocking)
if [ -n "$SOUND" ]; then
  paplay "$SOUND" &>/dev/null &
fi

# Terminal bell so VS Code tab flashes
printf '\a'

exit 0
