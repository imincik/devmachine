# devmachine

Declaratively configure a reproducible, isolated development environment for
your software project, powered by a NixOS VM.

## Features

- **Shell environment** – reproducible environment containing your command line
  and GUI tools (`dev shell`)

- **Devmachine VM** – reproducible and isolated environment containing your
  command line tools, coding agent and services (`dev vm`)

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

### Disk image

The VM disk is stored in the `devmachine.qcow2` image file in the directory
where the VM is started. The image is created on the first start and keeps the
VM state (home directory, service data) across restarts. Delete the image
while the VM is stopped to reset the VM to a clean state, or to apply a changed
`vm.diskSize`.

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
  - Default: `2222`
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
- `vm.shellHook`
  - Description: shell hook to run when connecting to the VM with interactive
    `dev vm` session, after entering the project directory (not on console
    login, for `dev vm <command>` or in shells started from the session)
  - Default: `""`
  - Example: `''echo "Welcome to the VM!"''`
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
    is created (delete the existing `.qcow2` image to resize it)
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
