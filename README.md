## Quick Start

Create a new project from the template:

```
nix flake init -t github:imincik/devmachine
```

Then,

1. run `nix run .#dev -- services` to start a VM with services
1. run `nix develop` to launch a shell environment


## Configuration Options

All options are set in `perSystem.devmachine`:

- `services` (NixOS module, default `{ }`) – NixOS configuration of the services VM
- `forwardPorts` (list of ports, default `[ ]`) – ports forwarded from host to VM, e.g.
  `5432` or `{ host = 8080; guest = 80; }`
- `shareProjectDir` (bool, default `true`) – share project directory (git root
  or current directory) with VM at `/devmachine`
- `packages` (list of packages, default `[ ]`) – packages available in `nix develop`
- `environment` (attrs of strings, default `{ }`) – environment variables set in `nix develop`
- `shellHook` (lines, default `""`) – shell hook to run when entering `nix develop`
