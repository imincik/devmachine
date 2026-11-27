{
  perSystem =
    { pkgs, ... }:
    {
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

        # Host port forwarded to SSH in the VM, unique per project so VMs
        # of several projects can run at the same time
        sshPort = 28024;

        # Packages installed in the VM
        packages = [
          pkgs.git
          pkgs.vim
        ];
      };

      devmachine.shell = {
        # Packages available in the shell environment
        packages = [
          (pkgs.python3.withPackages (ps: [ ps.psycopg ]))
          pkgs.postgresql
        ];

        # Environment variables set in the shell environment
        environment = {
          PG_URI = "postgres://app@localhost/app";
        };

        # Shell hook run when entering the shell environment
        shellHook = ''
          echo -e "\nRun 'python app.py' to start web service on http://localhost:8000."
          echo "Run 'psql \$PG_URI' to connect to database."
        '';
      };
    };
}
