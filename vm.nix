{
  lib,
  modulesPath,
  pkgs,
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

  # Execute in every interactive shell
  programs.bash.interactiveShellInit = ''
    bind -x '"\C-k": sudo poweroff'

    # Interactive SSH login shell outside zellij (not nested shells, which
    # inherit SSH_TTY), attach to devmachine zellij session or create it, log
    # out when detached. Not on consoles, autologin there would attach
    # unattended clients to the session.
    if [ -z "''${ZELLIJ:-}" ] && shopt -q login_shell && [ -n "''${SSH_TTY:-}" ] &&
      [ -t 0 ] && [ -t 1 ]; then
      cd /project
      zellij attach --create devmachine && exit
    fi
  '';

  system.stateVersion = "26.11";
}
