{
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    "${modulesPath}/profiles/qemu-guest.nix"
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];

  virtualisation.graphics = false;

  networking.hostName = lib.mkDefault "devmachine";
  networking.firewall.enable = false;

  # Boot speed and closure size optimizations
  nix.enable = lib.mkDefault false;

  networking.useNetworkd = lib.mkDefault true;
  systemd.network.wait-online.enable = lib.mkDefault false;

  boot.kernelParams = [ "udev.log_level=3" ];
  boot.consoleLogLevel = lib.mkDefault 3;
  boot.initrd.checkJournalingFS = lib.mkDefault false;

  services.timesyncd.enable = lib.mkDefault false;
  systemd.oomd.enable = lib.mkDefault false;
  systemd.coredump.enable = lib.mkDefault false;

  fonts.fontconfig.enable = lib.mkDefault false;

  # User
  users.mutableUsers = false;
  users.users.dev = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "";
  };
  security.sudo.wheelNeedsPassword = false;

  # SSH access with empty password (port is forwarded on 127.0.0.1 only)
  security.pam.services.sshd.allowNullPassword = true;
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      PermitEmptyPasswords = "yes";
      UseDns = false;
    };
  };

  # Console is used for administration, user works over SSH
  services.getty.autologinUser = "root";

  # Use a modern terminal type
  systemd.services."serial-getty@".environment.TERM = lib.mkDefault "xterm-256color";

  # Terminal multiplexer started on login
  environment.systemPackages = [ pkgs.zellij ];

  # Show configuration reload message logged by host (dev.sh) as notice in
  # zellij session.
  systemd.user.services.devmachine-notify = {
    description = "Show devmachine reload message in zellij";
    wantedBy = [ "default.target" ];
    path = [
      pkgs.jq
      pkgs.systemd
      pkgs.zellij
    ];
    serviceConfig.Restart = "always";
    script = ''
      z="zellij --session devmachine"

      # Follow new messages only, not ones logged before service start
      journalctl --follow --lines=0 --identifier=devmachine-reload --output=json |
        jq --unbuffered -r '
          (if (.PRIORITY | tonumber) <= 3 then "✘\t10s" else "✔\t3s" end)
          + "\t" + .MESSAGE' |
        while IFS=$'\t' read -r icon timeout msg; do
          # Zellij prompt must be run from an existing pane, any terminal pane
          # works (session may not be running, ignore errors)
          pane=$($z action list-panes --json |
            jq -r 'first(.[] | select(.is_plugin | not)).id') || continue
          ZELLIJ_PANE_ID=$pane $z prompt notify "$icon $msg" --title devmachine \
            --at top-right --no-pane-name --no-tab-name --timeout "$timeout" ||
            true
        done
    '';
  };

  # Execute in every interactive shell
  programs.bash.interactiveShellInit = ''
    bind -x '"\C-k": sudo poweroff'

    # Interactive SSH login shell outside zellij (not nested shells, which
    # inherit SSH_TTY), attach to devmachine zellij session or create it,
    # log out when detached. Not on consoles, autologin there would attach
    # unattended clients to the session.
    if [ -z "''${ZELLIJ:-}" ] && shopt -q login_shell && [ -n "''${SSH_TTY:-}" ] &&
      [ -t 0 ] && [ -t 1 ]; then
      cd /project
      zellij attach --create devmachine

      # Power off when session has ended (quit or killed), not when detached.
      # Query fails on sessions which are not running.
      if ! zellij --session devmachine action query-tab-names >/dev/null 2>&1; then
        sudo poweroff
      fi
      exit
    fi
  '';

  system.stateVersion = "26.11";
}
