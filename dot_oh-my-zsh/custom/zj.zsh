#------------ZELLIJ + JIRA-------------
# zj — open or attach a zellij session named after a Jira ticket.
# Accepts a full Jira URL (browse, board, or any link containing the key)
# or a bare key (ACTVTNS-799 / actvtns-799). Same ticket -> same session.
#
# On first creation the session uses the `jira` layout (CLAUDE / SHELL / MISC
# tabs). If the session already exists -- live OR a serialized/EXITED one --
# it is reattached/resurrected with its saved tabs instead of the layout.
zj() {
  emulate -L zsh
  local input="$1"
  if [[ -z "$input" ]]; then
    echo "usage: zj <jira-url-or-ticket-key>" >&2
    return 1
  fi

  # Extract the first PROJECT-123 pattern (case-insensitive), normalize to upper.
  local key
  key=$(printf '%s\n' "$input" | grep -oiE '[A-Z][A-Z0-9]+-[0-9]+' | head -n1)
  key=${key:u}

  if [[ -z "$key" ]]; then
    echo "zj: no Jira ticket key found in: $input" >&2
    return 1
  fi

  # Don't nest: zellij refuses to attach from inside a running session.
  if [[ -n "$ZELLIJ" ]]; then
    echo "zj: already inside zellij session '${ZELLIJ_SESSION_NAME:-?}'; detach first (Ctrl o, d)." >&2
    return 1
  fi

  # Does a session with this name already exist (live or resurrectable)?
  # `list-sessions -s` prints bare names, including EXITED ones.
  if zellij list-sessions -s 2>/dev/null | grep -qxF "$key"; then
    # Exists: attach (resurrects from serialized state if it was EXITED).
    zellij attach "$key"
  else
    # New: create with the jira layout (CLAUDE / SHELL / MISC tabs).
    zellij --session "$key" --new-session-with-layout jira
  fi
}
