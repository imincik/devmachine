{
  lib,
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

  # Getty
  services.getty.autologinUser = "dev";
  services.getty.helpLine = ''

    ╭──────────────────────────────────────────────────────╮
    │                                                      │
    │  DevMachine VM                                       │
    │                                                      │
    │  Project directory     /project                      │
    │  Follow service logs   sudo journalctl -f            │
    │  Power off the VM      Ctrl-k                        │
    │                                                      │
    │  Run `nix run .#dev -- ssh` on your host to connect  │
    │  with better performing terminal.                    │
    │                                                      │
    ╰──────────────────────────────────────────────────────╯
  '';

  # Use a modern terminal type
  systemd.services."serial-getty@".environment.TERM = lib.mkDefault "xterm-256color";

  # Execute after login
  programs.bash.interactiveShellInit = ''
    bind -x '"\C-k": sudo poweroff'

    # Print boot time once boot has finished
    systemctl is-system-running --wait >/dev/null 2>&1
    systemd-analyze | head -1

    # Go directly to the project directory
    cd /project
  '';

  system.stateVersion = "26.11";
}
