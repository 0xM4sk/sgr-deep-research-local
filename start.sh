#!/usr/bin/env bash
set -euo pipefail

# SGR Local Stack Starter (tmux + Ollama + LiteLLM + Airsroute + App)

SESSION_NAME="sgr"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Ports and defaults
OLLAMA_HOST="127.0.0.1"
OLLAMA_PORT="11434"
LITELLM_PORT="8000"
AIRSROUTE_PORT="8010"

# Default model per request (override with OLLAMA_MODEL env)
OLLAMA_MODEL_DEFAULT="llama3.1:8b"
OLLAMA_MODEL="${OLLAMA_MODEL:-$OLLAMA_MODEL_DEFAULT}"

# Env for the app
export OPENAI_BASE_URL="http://127.0.0.1:${LITELLM_PORT}/v1"
export OPENAI_API_KEY="${OPENAI_API_KEY:-dev-key}"

PROXY_CONFIG_REL="sgr-streaming/proxy/litellm_config.yaml"
PROXY_CONFIG="$ROOT_DIR/$PROXY_CONFIG_REL"

command_exists() { command -v "$1" >/dev/null 2>&1; }

fail() { echo "[ERROR] $*" >&2; exit 1; }

info() { echo "[INFO] $*"; }

wait_for_port() {
  local host="$1"; local port="$2"; local name="${3:-service}"; local retries=60
  until nc -z "$host" "$port" >/dev/null 2>&1; do
    retries=$((retries-1))
    if [ $retries -le 0 ]; then
      fail "Timed out waiting for $name on ${host}:${port}"
    fi
    sleep 1
  done
}

ensure_dirs() {
  mkdir -p "$ROOT_DIR/reports" "$ROOT_DIR/logs" "$ROOT_DIR/.tmp"
}

preflight() {
  info "Preflight checks"
  command_exists tmux || fail "tmux not found. Install tmux."
  command_exists ollama || fail "ollama not found. Install Ollama."
  command_exists litellm || fail "litellm not found. Install with: pip install litellm"
  command_exists uvicorn || fail "uvicorn not found. Install with: pip install uvicorn"
  command_exists python || fail "python not found."
  [ -f "$PROXY_CONFIG" ] || fail "Missing LiteLLM config: $PROXY_CONFIG_REL"
  ensure_dirs
}

start_tmux() {
  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    info "tmux session '$SESSION_NAME' already exists. Attaching..."
    exec tmux attach -t "$SESSION_NAME"
  fi

  info "Starting tmux session '$SESSION_NAME'"
  tmux new-session -d -s "$SESSION_NAME" -c "$ROOT_DIR" -n local

  # Pane 0 (top-left): Ollama serve
  tmux send-keys -t "$SESSION_NAME":0.0 "printf '\\033]0;ollama\\007'" C-m
  tmux send-keys -t "$SESSION_NAME":0.0 "ollama serve" C-m

  # Split right (pane 1): LiteLLM
  tmux split-window -h -t "$SESSION_NAME":0 -c "$ROOT_DIR"
  tmux send-keys -t "$SESSION_NAME":0.1 "printf '\\033]0;litellm\\007'" C-m
  tmux send-keys -t "$SESSION_NAME":0.1 "litellm --config $PROXY_CONFIG --host 0.0.0.0 --port $LITELLM_PORT" C-m

  # Split bottom-left (pane 2): Airsroute gateway
  tmux select-pane -t "$SESSION_NAME":0.0
  tmux split-window -v -t "$SESSION_NAME":0 -c "$ROOT_DIR"
  tmux send-keys -t "$SESSION_NAME":0.2 "printf '\\033]0;airsroute\\007'" C-m
  tmux send-keys -t "$SESSION_NAME":0.2 "python -m uvicorn sgr-streaming.proxy.airsroute_gateway.app:app --reload --port $AIRSROUTE_PORT" C-m

  # Split bottom-right (pane 3): App
  tmux select-pane -t "$SESSION_NAME":0.1
  tmux split-window -v -t "$SESSION_NAME":0 -c "$ROOT_DIR"
  tmux send-keys -t "$SESSION_NAME":0.3 "printf '\\033]0;app\\007'" C-m
  tmux send-keys -t "$SESSION_NAME":0.3 "echo 'OPENAI_BASE_URL=$OPENAI_BASE_URL'; echo 'Model via LiteLLM mapping configured in $PROXY_CONFIG_REL'" C-m
  tmux send-keys -t "$SESSION_NAME":0.3 "python sgr-streaming/sgr_streaming.py" C-m

  # Wait for services becoming ready and ensure model availability
  info "Waiting for Ollama on $OLLAMA_HOST:$OLLAMA_PORT"
  wait_for_port "$OLLAMA_HOST" "$OLLAMA_PORT" "ollama"
  info "Ensuring model '$OLLAMA_MODEL' is present"
  tmux send-keys -t "$SESSION_NAME":0.0 "ollama list | rg -q '^$OLLAMA_MODEL\\b' || ollama pull '$OLLAMA_MODEL'" C-m

  info "Waiting for LiteLLM on 0.0.0.0:$LITELLM_PORT"
  wait_for_port 127.0.0.1 "$LITELLM_PORT" "litellm"
  info "Waiting for Airsroute on 0.0.0.0:$AIRSROUTE_PORT"
  wait_for_port 127.0.0.1 "$AIRSROUTE_PORT" "airsroute"

  tmux select-pane -t "$SESSION_NAME":0.3
  info "Attached to '$SESSION_NAME'. Use stop.sh to stop all."
  tmux attach -t "$SESSION_NAME"
}

preflight
start_tmux

