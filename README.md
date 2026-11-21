## Quick Start

Create a new project from the template:

```
nix flake init -t github:imincik/devmachine
```

Then,

1. run `nix run .#dev -- services` to start a VM with services
1. run `nix develop` to launch a shell environment

Tip: you can launch `dev services` inside `nix develop` as well to launch
services. This will start VM faster because Nix doesn't need to evaluate VM
configuration again.


## Configuration Options

- `services`
  - Description: NixOS configuration (module) of the services VM
  - Default: `{ }`
  - Example: `{ services.postgresql.enable = true; }`
- `forwardPorts`
  - Description: ports forwarded from host to VM, either a port number (same
    port on host and VM) or `{ host = <port>; guest = <port>; }`
  - Default: `[ ]`
  - Example: `[ 5432 { host = 8080; guest = 80; } ]`
- `shareProjectDir`
  - Description: share project directory (git root or current directory) with
    VM at `/devmachine`
  - Default: `true`
  - Example: `false`
- `packages`
  - Description: packages available in `nix develop`
  - Default: `[ ]`
  - Example: `[ pkgs.postgresql pkgs.mongosh ]`
- `environment`
  - Description: environment variables set in `nix develop`
  - Default: `{ }`
  - Example: `{ PG_URI = "postgres://app@localhost/app"; }`
- `shellHook`
  - Description: shell hook to run when entering `nix develop`
  - Default: `""`
  - Example: `''echo "Run 'dev services' to start services."''`


## Credits

Inspired by
[Running local dev services with Nix](https://www.tweag.io/blog/2026-10-29-running-local-dev-services-with-nix/)
blog post by Tweag.
