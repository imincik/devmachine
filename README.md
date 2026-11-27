# devmachine

Declaratively configure a reproducible, isolated development environment for
your software project, powered by a NixOS VM.

## Features

- **Shell environment** – reproducible environment containing your command line
  and GUI tools (`dev shell`)

- **Devmachine VM** – reproducible and isolated environment containing your
  command line tools, coding agent and services (`dev vm`)

## Use Cases

1. **Software development with service dependencies**
  – development tools (compilers, interpreters, libraries, database clients) are
   provided by shell environment on the host
  - services services required by the software (databases, message queues, web
   servers) run in the VM

   Example: Python web service running on the host, using PostgreSQL running
   in the VM.

   ```
   nix flake init -t github:imincik/devmachine#postgres
   nix run .#dev -- vm --reload   # start VM with PostgreSQL, then detach
   nix run .#dev -- shell         # enter shell with Python and psql
   python app.py                  # open http://localhost:8000
   ```

1. **LLM-assisted coding with agent isolation** – the coding agent, all
   development tools and services run in the VM. The agent can freely run
   commands, install packages and restart services, but it only sees the VM
   and the shared project directory (`/project`), not your host home
   directory, credentials or other projects.

   Example: Claude Code developing the same Python web service with
   PostgreSQL, all running in the VM.

   ```
   nix flake init -t github:imincik/devmachine#llm-agent
   nix run .#dev -- vm --reload   # start VM and connect to it
   claude                         # run in the VM, log in on first run
   python app.py                  # run in another zellij pane in the VM,
                                  # open http://localhost:8000 on the host
   ```

## Quick Start

Add `devmachine` to your project:

```
nix flake init -t github:imincik/devmachine
```

Then:

1. run `nix run .#dev -- vm --reload` to launch a VM

1. add your coding agent to the `devmachine.vm.packages` list in the
   `devmachine.nix` configuration file (changes are applied automatically)

1. launch the coding agent and start slop/vibe/smart coding your new project

Run `nix run .#dev -- --help` for a full list of all `dev` command options.

## Devmachine VM

`dev vm` starts the VM in the background (if it is not already running) and
connects to it over SSH. The VM console log is written to `devmachine-vm.log`
in the project directory. Use `dev vm --status` to check whether the VM is
running.

Interactive SSH logins start [zellij](https://zellij.dev) and attach to the
`devmachine` session, or create it. Detaching from the session (`Ctrl-o d`)
logs out, the session keeps running in the VM.

Press `Ctrl-k` in a VM shell to power off the VM.

### Disk image

The VM disk is stored in the `devmachine.qcow2` image file in the directory
where the VM is started. The image is created on the first start and keeps the
VM state (home directory, service data) across restarts. Delete the image
while the VM is stopped to reset the VM to a clean state, or to apply a changed
`vm.diskSize`.

To grow the disk without losing the VM state, stop the VM, resize the image on
the host and grow the filesystem in the VM:

```
nix shell nixpkgs#qemu -c qemu-img resize devmachine.qcow2 20G
dev vm -- sudo resize2fs /dev/vda
```

Shrinking the disk is not supported, delete the image instead.

### Automatic reload

`dev vm --reload` also starts a background watcher on the host, which watches
the `devmachine.nix` file. When the file changes, the watcher builds the new
VM configuration and switches the running VM to it, so there is no need to
restart the VM. The watcher stops when the VM stops, and its output is written
to `devmachine-reload.log` in the project directory.

The result of each reload is logged to the VM system journal with the
`devmachine-reload` tag. To see when changes are applied, run in the VM:

```
journalctl -f -t devmachine-reload
```

A successful reload logs `switched to new configuration`. A failed reload
logs `reload failed, see devmachine-reload.log on host`, and the build or
switch error is in that log file.

Automatic reload requires the VM to share the host Nix store, it does not work
with `vm.isolateNixStore` enabled (restart the VM to apply changes instead).

## Configuration Options

### VM

- `vm.services`
  - Description: NixOS configuration (module) for services running in the VM
  - Default: `{ }`
  - Example: `{ services.postgresql.enable = true; }`
- `vm.forwardPorts`
  - Description: ports forwarded from host to VM, either a port number (same
    port on host and VM) or `{ host = <port>; guest = <port>; }`
  - Default: `[ ]`
  - Example: `[ 5432 { host = 8080; guest = 80; } ]`
- `vm.sshPort`
  - Description: host port (bound to `127.0.0.1`) forwarded to SSH in VM, used
    by `dev vm`
  - Default: `28022`
  - Example: `2200`
- `vm.shareProjectDir`
  - Description: share project directory (git root or current directory) with
    VM at `/project`
  - Default: `true`
  - Example: `false`
- `vm.isolateNixStore`
  - Description: provide VM with a Nix store image containing only the VM
    closure instead of sharing the whole host Nix store (the image is built
    every time the VM is started)
  - Default: `false`
  - Example: `true`
- `vm.packages`
  - Description: packages installed in the VM
  - Default: `[ ]`
  - Example: `[ pkgs.htop ]`
- `vm.nix`
  - Description: enable Nix in the VM, with flakes and a writable Nix store
    persisted in the disk image (increase `vm.diskSize` for builds and
    downloads)
  - Default: `false`
  - Example: `true`
- `vm.cores`
  - Description: number of CPU cores of the VM
  - Default: `2`
  - Example: `4`
- `vm.memorySize`
  - Description: memory size of the VM in MiB
  - Default: `2048`
  - Example: `4096`
- `vm.diskSize`
  - Description: disk size of the VM in MiB, applies only when the disk image
    is created (see [Disk image](#disk-image) to resize an existing image)
  - Default: `1024`
  - Example: `10240`

### Shell

- `shell.packages`
  - Description: packages available in `dev shell`
  - Default: `[ ]`
  - Example: `[ pkgs.postgresql pkgs.mongosh ]`
- `shell.environment`
  - Description: environment variables set in `dev shell`
  - Default: `{ }`
  - Example: `{ PG_URI = "postgres://app@localhost/app"; }`
- `shell.shellHook`
  - Description: shell hook to run when entering `dev shell`
  - Default: `""`
  - Example: `''echo "Welcome to this shell environment!"''`

For more configuration examples see the [templates](templates/) directory.
A specific template can be used with
`nix flake init -t github:imincik/devmachine#<template>`.

## AI Assistance

This project is designed by a human and developed by human with
the assistance of coding agents, following the
[Responsible AI Guide](https://responsibleai.guide/).

## Credits

Inspired by the
[Running local dev services with Nix](https://www.tweag.io/blog/2026-10-29-running-local-dev-services-with-nix/)
blog post by Tweag.
