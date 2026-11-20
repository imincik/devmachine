{
  perSystem =
    { pkgs, ... }:
    {
      devos = {
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
          };

          virtualisation.forwardPorts = [
            {
              host.port = 5432;
              guest.port = 5432;
            }
          ];
        };

        # Packages available in `nix develop`
        packages = [ pkgs.postgresql ];

        # Environment variables set in `nix develop`
        environment = {
          PG_URI = "postgres://app@localhost/app";
        };

        # Shell hook run when entering `nix develop`
        shellHook = ''
          echo "Run 'devos up' to start services."
        '';
      };
    };
}
