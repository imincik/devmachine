{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];

  virtualisation.graphics = false;

  networking.hostName = lib.mkDefault "devmachine";
  networking.firewall.enable = false;

  documentation.nixos.enable = false;

  services.getty.autologinUser = "root";
  services.getty.helpLine = ''

    ╭──────────────────────────────────────────────╮
    │                                              │
    │  DevMachine VM                               │
    │                                              │
    │  Project directory     /devmachine           │
    │  Follow service logs   journalctl -f         │
    │  Power off the VM      Ctrl-k                │
    │                                              │
    ╰──────────────────────────────────────────────╯
  '';

  system.stateVersion = "26.11";

  programs.bash.shellInit = ''
    bind -x '"\C-k": poweroff'
  '';
}
