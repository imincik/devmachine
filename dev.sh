# shellcheck shell=bash

usage() {
  cat <<EOF
Usage: dev <command>

Commands:
  vm [--console|--status|--reload]
                  Start VM in background (if not running) and connect to it
                  over SSH

                  --console start VM in foreground and connect to it using
                  emulated console

                  --reload automatically reload VM when devmachine.nix file
                  is changed

                  --status reports VM status

  shell           Launch shell environment

  help            Show this help message
EOF
}

### State files

# Console log of VM started in background
vm_log=devmachine-vm.log

# QEMU pidfile, absolute because VM run script changes directory
vm_pidfile=$PWD/devmachine-vm.pid

# Log and pidfile of configuration watcher started by `vm --reload`
reload_log=devmachine-reload.log
reload_pidfile=$PWD/devmachine-reload.pid

# Pidfile can be left behind if process crashes, check process matches pattern
pidfile_alive() {
  local pidfile=$1 pattern=$2 pid
  pid=$(cat "$pidfile" 2>/dev/null) || return 1
  # shellcheck disable=SC2053 # pattern is a glob
  [[ "$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null)" == $pattern ]]
}

### VM lifecycle

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

# Run non-interactive command in VM
vm_exec() {
  vm_ssh -o BatchMode=yes dev@127.0.0.1 "$@"
}

vm_running() {
  pidfile_alive "$vm_pidfile" "*qemu-system-*"
}

vm_status() {
  if vm_running; then
    echo "VM is running (pid $(cat "$vm_pidfile"))"
  else
    echo "VM is stopped"
    exit 1
  fi
}

prepare_vm() {
  set_project_dir
  QEMU_OPTS="${QEMU_OPTS:-} -pidfile $vm_pidfile"
  export QEMU_OPTS
}

start_vm_console() {
  prepare_vm
  exec "$DEVMACHINE_VM" "$@"
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

# Start VM (if not running), optionally start watcher and connect over SSH
connect_vm() {
  local reload=

  if [ "${1:-}" = "--reload" ]; then
    reload=1
    shift
  fi

  launch_vm
  wait_for_ssh
  if [ -n "$reload" ]; then
    start_watcher
  fi
  vm_ssh dev@127.0.0.1 "$@"
}

### Configuration reload

# Running VM sees new configuration via shared host Nix store
switch_vm() {
  local system

  echo "Building VM configuration ..."
  system=$(nix build .#devmachine-system --no-link --print-out-paths) || return 1

  if ! vm_exec test -e "$system"; then
    echo "dev: new configuration is not available in VM Nix store" \
      "(is vm.isolateNixStore enabled?), restart VM to apply it" >&2
    return 1
  fi

  echo "Switching VM to new configuration ..."
  vm_exec sudo "$system/bin/switch-to-configuration" test
}

# Report result to VM journal, so it is visible without watching log on host.
# VM shows it as zellij notice (devmachine-notify user service), failures are
# logged with err priority.
reload_vm() {
  local priority msg

  echo "--- $(date '+%F %T') devmachine.nix changed"
  if switch_vm; then
    priority=user.notice msg="switched to new configuration"
  else
    priority=user.err msg="reload failed, see $reload_log on host"
  fi
  echo "--- $msg"
  vm_exec logger -t devmachine-reload -p "$priority" "$msg" || true
}

watcher_running() {
  pidfile_alive "$reload_pidfile" "* vm --reload*"
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
watch_config() {
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

### Commands

# Internal invocations by the watcher
if [ -n "${DEVMACHINE_RELOAD:-}" ]; then
  reload_vm
  exit
fi
if [ -n "${DEVMACHINE_WATCH:-}" ]; then
  watch_config
  exit
fi

case "${1:-}" in
  vm)
    shift
    case "${1:-}" in
      --console)
        shift
        start_vm_console "$@"
        ;;
      --status)
        vm_status
        ;;
      *)
        connect_vm "$@"
        ;;
    esac
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
