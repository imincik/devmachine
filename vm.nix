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
  virtualisation.cores = lib.mkDefault 2;
  virtualisation.memorySize = lib.mkDefault 2048;

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
  users.users.dev = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
  security.sudo.wheelNeedsPassword = false;

  # Getty
  services.getty.autologinUser = "dev";
  services.getty.helpLine = ''

    ╭──────────────────────────────────────────────╮
    │                                              │
    │  DevMachine VM                               │
    │                                              │
    │  Project directory     /devmachine           │
    │  Follow service logs   sudo journalctl -f    │
    │  Power off the VM      Ctrl-k                │
    │                                              │
    ╰──────────────────────────────────────────────╯
  '';

  system.stateVersion = "26.11";

  programs.bash.interactiveShellInit = ''
    bind -x '"\C-k": sudo poweroff'

    # Print boot time once boot has finished
    systemctl is-system-running --wait >/dev/null 2>&1
    systemd-analyze | head -1
  '';
}
