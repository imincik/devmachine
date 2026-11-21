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

| Option        | Type                | Description                                        |
| ------------- | ------------------- | -------------------------------------------------- |
| `services`    | NixOS module        | NixOS configuration of the services VM             |
| `forwardPorts`| list of ports       | Ports forwarded from host to VM (`5432` or `{ host = 8080; guest = 80; }`) |
| `shareProjectDir` | bool (default `true`) | Share project directory (git root or current directory) with VM at `/devmachine` |
| `packages`    | list of packages    | Packages available in `nix develop`                |
| `environment` | attrs of strings    | Environment variables set in `nix develop`         |
| `shellHook`   | lines               | Shell hook to run when entering `nix develop`      |
