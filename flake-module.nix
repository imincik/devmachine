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

          sshPort = mkOption {
            type = types.port;
            default = 2222;
            example = 2200;
            description = ''
              Host port, bound to 127.0.0.1, forwarded to SSH in the VM. Used by
              `dev vm`.
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

          cores = mkOption {
            type = types.ints.positive;
            default = 2;
            example = 4;
            description = "Number of CPU cores of the VM.";
          };

          memorySize = mkOption {
            type = types.ints.positive;
            default = 2048;
            example = 4096;
            description = "Memory size of the VM in MiB.";
          };

          diskSize = mkOption {
            type = types.ints.positive;
            default = 1024;
            example = 10240;
            description = ''
              Disk size of the VM in MiB. Applies only when the disk image is
              created, delete the existing `.qcow2` image to resize it.
            '';
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

              virtualisation.cores = cfg.vm.cores;
              virtualisation.memorySize = cfg.vm.memorySize;
              virtualisation.diskSize = cfg.vm.diskSize;

              virtualisation.forwardPorts =
                map (p: {
                  host.port = p.host;
                  guest.port = p.guest;
                }) cfg.vm.forwardPorts
                ++ [
                  {
                    host.address = "127.0.0.1";
                    host.port = cfg.vm.sshPort;
                    guest.port = 22;
                  }
                ];

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
          runtimeInputs = [
            pkgs.coreutils
            pkgs.openssh
            pkgs.util-linux
          ];
          runtimeEnv = {
            DEVMACHINE_VM = lib.getExe config.packages.devmachine-vm;
            DEVMACHINE_SSH_PORT = toString cfg.vm.sshPort;
          };
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
