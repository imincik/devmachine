## Quick Start

Create a new project from the template:

```
nix flake init -t github:imincik/devmachine
```

Then,

1. run `nix run .#dev -- services` to start a VM with services
1. run `nix develop` to launch a shell environment


## Configuration Options

- `services`
  - Description: NixOS configuration (module) of the services VM
  - Default: `{ }`
- `forwardPorts`
  - Description: ports forwarded from host to VM, e.g. `5432` or
    `{ host = 8080; guest = 80; }`
  - Default: `[ ]`
- `shareProjectDir`
  - Description: share project directory (git root or current directory) with
    VM at `/devmachine`
  - Default: `true`
- `packages`
  - Description: packages available in `nix develop`
  - Default: `[ ]`
- `environment`
  - Description: environment variables set in `nix develop`
  - Default: `{ }`
- `shellHook`
  - Description: shell hook to run when entering `nix develop`
  - Default: `""`
