## Quick Start

Create a new project from the template:

```
nix flake init -t github:imincik/devmachine
```

Then,

1. run `nix run .#dev -- vm` to start a VM with services
1. run `nix run .#dev -- shell` to launch a shell environment


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
- `vm.shareProjectDir`
  - Description: share project directory (git root or current directory) with
    VM at `/project`
  - Default: `true`
  - Example: `false`
- `vm.packages`
  - Description: packages installed in the VM
  - Default: `[ ]`
  - Example: `[ pkgs.htop ]`

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


## Credits

Inspired by
[Running local dev services with Nix](https://www.tweag.io/blog/2026-10-29-running-local-dev-services-with-nix/)
blog post by Tweag.
