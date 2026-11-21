{
  perSystem =
    { pkgs, ... }:
    {
      devmachine = {
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

        # Packages available in `nix develop`
        packages = [ pkgs.postgresql ];

        # Environment variables set in `nix develop`
        environment = {
          PG_URI = "postgres://app@localhost/app";
        };

        # Shell hook run when entering `nix develop`
        shellHook = ''
          echo -e "\nRun 'psql -h localhost -U postgres' to connect to database."
        '';
      };
    };
}
