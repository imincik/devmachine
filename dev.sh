usage() {
  cat <<EOF
Usage: dev <command>

Commands:
  vm [--console|--status]
                  Start VM with services in background (if not running) and
                  connect to it over SSH

                  --console starts VM in foreground and connects to its emulated
                  console instead

                  --status reports VM status

  shell           Launch shell environment

  help            Show this help message
EOF
}

# Console log of VM started in background
vm_log=devmachine-vm.log

# QEMU pidfile, absolute because VM run script changes directory
vm_pidfile=$PWD/devmachine-vm.pid

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

prepare_vm() {
  set_project_dir
  QEMU_OPTS="${QEMU_OPTS:-} -pidfile $vm_pidfile"
  export QEMU_OPTS
}

# Pidfile can be left behind if VM crashes, check process is QEMU
vm_running() {
  local pid
  pid=$(cat "$vm_pidfile" 2>/dev/null) || return 1
  [[ "$(readlink "/proc/$pid/exe" 2>/dev/null)" == *qemu-system-* ]]
}

launch_vm() {
  if vm_running; then
    return
  fi

  prepare_vm
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
      prepare_vm
      exec "$DEVMACHINE_VM" "$@"
    fi
    if [ "${1:-}" = "--status" ]; then
      if vm_running; then
        echo "VM is running (pid $(cat "$vm_pidfile"))"
      else
        echo "VM is stopped"
        exit 1
      fi
      exit
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
