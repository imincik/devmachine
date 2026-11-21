{ inputs, ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    {
      # Allow unfree packages used in this configuration
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];
      };

      devmachine.vm = {
        # NixOS configuration of services running in the VM
        services = {
          services.postgresql = {
            enable = true;
            enableTCPIP = true;
            ensureDatabases = [ "app" ];
            ensureUsers = [
              {
                name = "app";
                ensureDBOwnership = true;
              }
            ];
            authentication = ''
              host  all  all  0.0.0.0/0  trust
            '';

            # Verbose logging, see `journalctl -f` in the VM
            settings = {
              log_statement = "all";
              log_duration = true;
              log_connections = true;
              log_disconnections = true;
              log_min_messages = "info";
              log_error_verbosity = "verbose";
              log_line_prefix = "%m [%p] %u@%d ";
            };
          };
        };

        # Ports forwarded from the host to the VM
        forwardPorts = [ 5432 ];

        # Packages installed in the VM
        packages = [
          pkgs.btop
          pkgs.claude-code
          pkgs.git
          pkgs.helix
          pkgs.zellij
        ];
      };

      devmachine.shell = {
        # Packages available in the shell environment
        packages = [ pkgs.postgresql ];

        # Environment variables set in the shell environment
        environment = {
          PG_URI = "postgres://app@localhost/app";
        };

        # Shell hook run when entering the shell environment
        shellHook = ''
          echo -e "\nRun 'psql -h localhost -U postgres' to connect to database."
        '';
      };
    };
}
