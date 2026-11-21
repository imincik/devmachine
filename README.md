## Quick Start

Add `devmachine` configuration to your project:

```
nix flake init -t github:imincik/devmachine
```

Then,

1. run `nix run .#dev -- vm` or `nix develop` + `dev vm` to start a VM with services
1. run `nix run .#dev -- ssh` or `dev ssh` in another terminal to connect
   to the running VM over SSH (faster terminal than the VM console)
1. run `nix run .#dev -- shell` or `nix develop` to launch a shell environment


## Configuration Options

### VM

- `vm.services`
  - Description: NixOS configuration (module) of the services VM
  - Default: `{ }`
  - Example: `{ services.postgresql.enable = true; }`
- `vm.forwardPorts`
  - Description: ports forwarded from host to VM, either a port number (same
    port on host and VM) or `{ host = <port>; guest = <port>; }`
  - Default: `[ ]`
  - Example: `[ 5432 { host = 8080; guest = 80; } ]`
- `vm.sshPort`
  - Description: host port (bound to `127.0.0.1`) forwarded to SSH in VM, used
    by `dev ssh`
  - Default: `2222`
  - Example: `2200`
- `vm.shareProjectDir`
  - Description: share project directory (git root or current directory) with
    VM at `/project`
  - Default: `true`
  - Example: `false`
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
  - Example: `''echo "Welcome in this shell environment!"''`

For more configuration examples see the [templates](templates/) directory. A
specific template can be used with
`nix flake init -t github:imincik/devmachine#<template>`, e.g. `#postgres`.


## Credits

Inspired by
[Running local dev services with Nix](https://www.tweag.io/blog/2026-10-29-running-local-dev-services-with-nix/)
blog post by Tweag.
