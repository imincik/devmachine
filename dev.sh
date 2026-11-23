usage() {
  cat <<EOF
Usage: dev <command>

Commands:
  vm [--console]  Start VM with services in background (if not running) and
                  connect to it over SSH, --console starts VM in foreground
                  and connects to its emulated console instead
  shell           Launch shell environment
  help            Show this help message
EOF
}

# Console log of VM started in background
vm_log=devmachine-vm.log

set_project_dir() {
  if [ -z "${DEVMACHINE_PROJECT_DIR:-}" ]; then
    DEVMACHINE_PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    export DEVMACHINE_PROJECT_DIR
  fi
}

vm_ssh() {
  ssh -p "$DEVMACHINE_SSH_PORT" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    "$@"
}

# QEMU opens forwarded port as soon as VM is started
ssh_port_open() {
  (exec 3<>"/dev/tcp/127.0.0.1/$DEVMACHINE_SSH_PORT") 2>/dev/null
}

launch_vm() {
  if ssh_port_open; then
    return
  fi

  set_project_dir
  echo "Starting VM in background (console log: $vm_log)"
  # Forward journal to console, otherwise log stops updating after boot
  QEMU_KERNEL_PARAMS="${QEMU_KERNEL_PARAMS:-} systemd.journald.forward_to_console=1" \
    setsid "$DEVMACHINE_VM" </dev/null >"$vm_log" 2>&1 &
  vm_pid=$!
}

wait_for_ssh() {
  local deadline=$((SECONDS + 120))

  printf "Waiting for VM ... "
  until vm_ssh -o BatchMode=yes -o ConnectTimeout=2 dev@127.0.0.1 true 2>/dev/null; do
    if [ -n "${vm_pid:-}" ] && ! kill -0 "$vm_pid" 2>/dev/null; then
      echo
      echo "dev: VM exited, last lines of $vm_log:" >&2
      tail -n 20 "$vm_log" >&2
      exit 1
    fi
    if [ "$SECONDS" -ge "$deadline" ]; then
      echo
      echo "dev: timed out waiting for VM SSH, see $vm_log" >&2
      exit 1
    fi
    sleep 1
  done
  echo "ready"
}

case "${1:-}" in
  vm)
    shift
    if [ "${1:-}" = "--console" ]; then
      shift
      set_project_dir
      exec "$DEVMACHINE_VM" "$@"
    fi
    launch_vm
    wait_for_ssh
    vm_ssh dev@127.0.0.1 "$@"
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
