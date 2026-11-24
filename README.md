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

This project is designed by a human and developed with the assistance of coding
agents. All code is reviewed by a human.

## Credits

Inspired by the
[Running local dev services with Nix](https://www.tweag.io/blog/2026-10-29-running-local-dev-services-with-nix/)
blog post by Tweag.
