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

      # Coding agent, tools and services run in the VM, isolated from the host.
      # Run `claude` in the VM and log in on first run (credentials persist in
      # the VM disk image). Run `python app.py` in another zellij pane and open
      # http://localhost:8000 on the host.
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

          # Web service configuration, listen on all interfaces so it is
          # reachable from the host through forwarded port
          environment.variables = {
            PG_URI = "postgres://app@localhost/app";
            APP_HOST = "0.0.0.0";
          };
        };

        # Ports forwarded from the host to the VM (web service)
        forwardPorts = [ 8000 ];

        # Host port forwarded to SSH in the VM, unique per project so VMs
        # of several projects can run at the same time
        sshPort = 28025;

        # Packages installed in the VM
        packages = [
          pkgs.claude-code
          pkgs.git
          pkgs.vim
          (pkgs.python3.withPackages (ps: [ ps.psycopg ]))
          pkgs.postgresql
        ];

        # Coding agent and database need more memory than default
        memorySize = 4096;
      };
    };
}
