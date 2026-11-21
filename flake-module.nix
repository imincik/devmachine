{ mkVM }:
{ lib, flake-parts-lib, ... }:
let
  inherit (lib) mkOption types;

  # Mount point of the shared project directory in the VM
  mountPoint = "/project";
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
      cfg = config.devmachine;
    in
    {
      options.devmachine = {
        vm = {
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

          shareProjectDir = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Whether to share the project directory with the VM, mounted
              read-write at `${mountPoint}`. The project directory is the git
              repository root or the current directory, and can be overridden
              by the `DEVMACHINE_PROJECT_DIR` environment variable.
            '';
          };

          packages = mkOption {
            type = types.listOf types.package;
            default = [ ];
            example = lib.literalExpression "[ pkgs.htop ]";
            description = "List of packages installed in the VM.";
          };
        };

        shell = {
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
      };

      config = {
        packages.devmachine-vm = mkVM {
          inherit system;
          modules = [
            ./vm.nix
            cfg.vm.services
            {
              environment.systemPackages = cfg.vm.packages;

              virtualisation.forwardPorts = map (p: {
                host.port = p.host;
                guest.port = p.guest;
              }) cfg.vm.forwardPorts;

              # Source is expanded by the VM run script at start time
              virtualisation.sharedDirectories.project = lib.mkIf cfg.vm.shareProjectDir {
                source = ''"''${DEVMACHINE_PROJECT_DIR:-$PWD}"'';
                target = mountPoint;
                writable = true;
              };
            }
          ];
        };

        packages.dev = pkgs.writeShellApplication {
          name = "dev";
          runtimeEnv.DEVMACHINE_VM = lib.getExe config.packages.devmachine-vm;
          text = builtins.readFile ./dev.sh;
        };

        devShells.default = lib.mkDefault (
          pkgs.mkShell {
            packages = [ config.packages.dev ] ++ cfg.shell.packages;
            env = cfg.shell.environment;
            inherit (cfg.shell) shellHook;
          }
        );
      };
    }
  );
}
