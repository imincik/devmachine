{ nixpkgs }:
{ lib, flake-parts-lib, ... }:
let
  inherit (lib) mkOption types;
  inherit (import ./mkvm.nix { inherit (nixpkgs) lib; }) mkVM;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      cfg = config.devos;
    in
    {
      options.devos = {
        services = mkOption {
          type = types.deferredModule;
          default = { };
          description = ''
            Configuration of available services.

            See the list of available
            [configuration options](https://search.nixos.org/options) .
          '';
        };

        forwardPorts = mkOption {
          type = types.listOf (
            types.coercedTo types.port
              (port: {
                host = port;
                guest = port;
              })
              (
                types.submodule {
                  options = {
                    host = mkOption {
                      type = types.port;
                      description = "Port on the host.";
                    };
                    guest = mkOption {
                      type = types.port;
                      description = "Port in the VM.";
                    };
                  };
                }
              )
          );
          default = [ ];
          example = [
            5432
            {
              host = 8080;
              guest = 80;
            }
          ];
          description = ''
            TCP ports forwarded from the host to the VM. A port number forwards
            the same port, an attribute set maps a `host` port to a `guest` port.
          '';
        };

        packages = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "List of packages available in a shell environment";
        };

        environment = mkOption {
          type = types.attrsOf (
            types.coercedTo (types.oneOf [
              types.int
              types.path
            ]) toString types.str
          );
          default = { };
          description = "Environment variables set in a shell environment.";
        };

        shellHook = mkOption {
          type = types.lines;
          default = "";
          description = "Shell hook executed when entering a shell environment.";
        };
      };

      config = {
        packages.devos-vm = mkVM {
          inherit system;
          modules = [
            ./devos.nix
            cfg.services
            {
              virtualisation.forwardPorts = map (p: {
                host.port = p.host;
                guest.port = p.guest;
              }) cfg.forwardPorts;
            }
          ];
        };

        packages.devos = pkgs.writeShellApplication {
          name = "devos";
          text = ''
            usage() {
              cat <<EOF
            Usage: devos <command>

            Commands:
              up      Start services VM (press Ctrl-k in VM to power off)
              help    Show this help message
            EOF
            }

            case "''${1:-}" in
              up)
                shift
                exec ${lib.getExe config.packages.devos-vm} "$@"
                ;;
              "" | help | -h | --help)
                usage
                ;;
              *)
                echo "devos: unknown command '$1'" >&2
                usage >&2
                exit 1
                ;;
            esac
          '';
        };

        devShells.default = lib.mkDefault (
          pkgs.mkShell {
            packages = [ config.packages.devos ] ++ cfg.packages;
            env = cfg.environment;
            inherit (cfg) shellHook;
          }
        );
      };
    }
  );
}
