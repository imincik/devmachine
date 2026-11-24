# Development environment of devmachine itself
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
        # Packages installed in the VM
        packages = [
          pkgs.claude-code
          pkgs.git
          pkgs.helix
          pkgs.python3
          pkgs.zellij

          # Tools used to develop and check dev.sh and Nix files
          pkgs.nixfmt-tree
          pkgs.shellcheck
        ];

        # Start zellij with coding agent and system journal below it, attach to
        # existing session on reconnect
        shellHook =
          let
            layout = pkgs.writeText "devmachine-layout.kdl" ''
              layout {
                default_tab_template {
                  pane size=1 borderless=true {
                    plugin location="zellij:tab-bar"
                  }
                  children
                  pane size=2 borderless=true {
                    plugin location="zellij:status-bar"
                  }
                }
                tab name="devmachine" {
                  pane command="claude" focus=true
                  pane command="sudo" size="20%" {
                    args "journalctl" "-f"
                  }
                }
              }
            '';
          in
          ''
            zellij attach devmachine 2>/dev/null \
              || zellij --session devmachine --new-session-with-layout ${layout}
          '';
      };
    };
}
