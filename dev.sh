usage() {
  cat <<EOF
Usage: dev <command>

Commands:
  services  Start services VM (press Ctrl-k in VM to power off)
  help      Show this help message
EOF
}

case "${1:-}" in
  services)
    shift
    if [ -z "${DEVMACHINE_PROJECT_DIR:-}" ]; then
      DEVMACHINE_PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
      export DEVMACHINE_PROJECT_DIR
    fi
    exec "$DEVMACHINE_VM" "$@"
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
