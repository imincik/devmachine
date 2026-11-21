usage() {
  cat <<EOF
Usage: dev <command>

Commands:
  vm      Start VM with services (press Ctrl-k in VM to power off)
  ssh     Connect to running VM over SSH (faster terminal)
  shell   Launch shell environment
  help    Show this help message
EOF
}

case "${1:-}" in
  vm)
    shift
    if [ -z "${DEVMACHINE_PROJECT_DIR:-}" ]; then
      DEVMACHINE_PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
      export DEVMACHINE_PROJECT_DIR
    fi
    exec "$DEVMACHINE_VM" "$@"
    ;;
  ssh)
    shift
    exec ssh -p "$DEVMACHINE_SSH_PORT" \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o LogLevel=ERROR \
      dev@127.0.0.1 "$@"
    ;;
  shell)
    shift
    exec nix develop "$@"
    ;;
  "" | help | -h | --help)
    usage
    ;;
  *)
    echo "dev: unknown command '$1'" >&2
    usage >&2
    exit 1
    ;;
esac
