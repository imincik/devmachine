## Quick Start

Create a new project from the template:

```
nix flake init -t github:imincik/devos
```

or import the flake-parts module into an existing flake:

```nix
{
  inputs.devos.url = "github:imincik/devos";

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devos.flakeModules.default ];
      systems = [ "x86_64-linux" ];
      perSystem = { pkgs, ... }: {
        devos = {
          services = { services.postgresql.enable = true; };
          forwardPorts = [ 5432 ];
          packages = [ pkgs.postgresql ];
          environment.PG_URI = "postgres://localhost/postgres";
          shellHook = ''echo "Run 'devos up' to start services."'';
        };
      };
    };
}
```

Then,

1. run `nix run .#devos -- up` to start the services
1. `nix develop` to launch a shell environment containing packages


## Options

All options are set in `perSystem.devos`:

| Option        | Type                | Description                                        |
| ------------- | ------------------- | -------------------------------------------------- |
| `services`    | NixOS module        | NixOS configuration of the services VM             |
| `forwardPorts`| list of ports       | Ports forwarded from host to VM (`5432` or `{ host = 8080; guest = 80; }`) |
| `shareProjectDir` | bool (default `true`) | Share project directory (git root or current directory) with VM at `/devos` |
| `packages`    | list of packages    | Packages available in `nix develop`                |
| `environment` | attrs of strings    | Environment variables set in `nix develop`         |
| `shellHook`   | lines               | Shell hook to run when entering `nix develop`      |
