#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="sgr"

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "[INFO] Stopping tmux session '$SESSION_NAME'"
  # Send Ctrl-C to all panes for graceful shutdown
  for pane in $(tmux list-panes -t "$SESSION_NAME" -F '#P'); do
    tmux send-keys -t "$SESSION_NAME":0.$pane C-c
  done
  sleep 1
  tmux kill-session -t "$SESSION_NAME"
  echo "[INFO] Session '$SESSION_NAME' terminated."
else
  echo "[INFO] No tmux session named '$SESSION_NAME' found."
fi

