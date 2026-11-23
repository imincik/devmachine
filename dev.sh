usage() {
  cat <<EOF
Usage: dev <command>

Commands:
  vm [--console|--status|--reload]
                  Start VM with services in background (if not running) and
                  connect to it over SSH

                  --console starts VM in foreground and connects to its emulated
                  console instead

                  --status reports VM status

                  --reload also watches devmachine.nix in background (until VM
                  stops) and on every change builds VM configuration and
                  switches running VM to it, without restart (log:
                  devmachine-reload.log, results in VM journal)

  shell           Launch shell environment

  help            Show this help message
EOF
}

# Console log of VM started in background
vm_log=devmachine-vm.log

# QEMU pidfile, absolute because VM run script changes directory
vm_pidfile=$PWD/devmachine-vm.pid

# Log and pidfile of configuration watcher started by `vm --reload`
reload_log=devmachine-reload.log
reload_pidfile=$PWD/devmachine-reload.pid

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

# Running VM sees new configuration via shared host Nix store
reload_vm() {
  local system

  echo "Building VM configuration ..."
  system=$(nix build .#devmachine-system --no-link --print-out-paths) || return 1

  if ! vm_ssh -o BatchMode=yes dev@127.0.0.1 test -e "$system"; then
    echo "dev: new configuration is not available in VM Nix store" \
      "(is vm.isolateNixStore enabled?), restart VM to apply it" >&2
    return 1
  fi

  echo "Switching VM to new configuration ..."
  vm_ssh -o BatchMode=yes dev@127.0.0.1 sudo "$system/bin/switch-to-configuration" test
}

# Report result to VM journal, so it is visible without watching log on host
reload_once() {
  local msg

  echo "--- $(date '+%F %T') devmachine.nix changed"
  if reload_vm; then
    msg="switched to new configuration"
  else
    msg="reload failed, see $reload_log on host"
  fi
  echo "--- $msg"
  vm_ssh -o BatchMode=yes dev@127.0.0.1 logger -t devmachine-reload "$msg" || true
}

watcher_running() {
  local pid
  pid=$(cat "$reload_pidfile" 2>/dev/null) || return 1
  [[ "$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null)" == *" vm --reload"* ]]
}

start_watcher() {
  if watcher_running; then
    return
  fi

  echo "Watching devmachine.nix for changes in background (log: $reload_log)"
  DEVMACHINE_WATCH=1 setsid "$0" vm --reload </dev/null >>"$reload_log" 2>&1 &
  echo $! >"$reload_pidfile"
}

# Watch directory, editors replace file on save which breaks file watch.
# Queue changes made during reload, so latest configuration is applied.
# On change, this script is run again with DEVMACHINE_RELOAD set.
run_watcher() {
  # Not local, EXIT trap runs after function returns
  DEVMACHINE_RELOAD=1 watchexec --postpone --on-busy-update=queue --shell=none \
    --watch . --filter devmachine.nix -- "$0" vm --reload &
  watchexec_pid=$!
  trap 'kill "$watchexec_pid" 2>/dev/null || true; rm -f "$reload_pidfile"' EXIT

  # Stop watching when VM stops
  while vm_running && kill -0 "$watchexec_pid" 2>/dev/null; do
    sleep 2
  done
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
    reload=
    if [ "${1:-}" = "--reload" ]; then
      shift
      # Internal invocations by the watcher
      if [ -n "${DEVMACHINE_RELOAD:-}" ]; then
        reload_once
        exit
      fi
      if [ -n "${DEVMACHINE_WATCH:-}" ]; then
        run_watcher
        exit
      fi
      reload=1
    fi
    launch_vm
    wait_for_ssh
    if [ -n "$reload" ]; then
      start_watcher
    fi
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
