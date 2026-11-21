## Quick Start

Create a new project from the template:

```
nix flake init -t github:imincik/devmachine
```

or import the flake-parts module into an existing flake:

```nix
{
  inputs.devmachine.url = "github:imincik/devmachine";

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devmachine.flakeModules.default ];
      systems = [ "x86_64-linux" ];
      perSystem = { pkgs, ... }: {
        devmachine = {
          services = { services.postgresql.enable = true; };
          forwardPorts = [ 5432 ];
          packages = [ pkgs.postgresql ];
          environment.PG_URI = "postgres://localhost/postgres";
          shellHook = ''echo "Welcome here ..."'';
        };
      };
    };
}
```

Then,

1. run `nix run .#dev -- services` to start the services
1. run `nix develop` to launch a shell environment containing packages


## Options

All options are set in `perSystem.devmachine`:

- `services` (NixOS module, default `{ }`) – NixOS configuration of the services VM
- `forwardPorts` (list of ports, default `[ ]`) – ports forwarded from host to VM, e.g.
  `5432` or `{ host = 8080; guest = 80; }`
- `shareProjectDir` (bool, default `true`) – share project directory (git root
  or current directory) with VM at `/devmachine`
- `packages` (list of packages, default `[ ]`) – packages available in `nix develop`
- `environment` (attrs of strings, default `{ }`) – environment variables set in `nix develop`
- `shellHook` (lines, default `""`) – shell hook to run when entering `nix develop`
