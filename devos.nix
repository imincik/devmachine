{ lib, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];

  virtualisation.graphics = false;

  networking.hostName = lib.mkDefault "devos";
  networking.firewall.enable = false;

  documentation.nixos.enable = false;

  services.getty.autologinUser = "root";
  services.getty.helpLine = ''

  ======================================
    DevOS VM

    Press Ctrl-k to power off the VM.
  ======================================
  '';

  system.stateVersion = "26.11";

  programs.bash.shellInit = ''
    bind -x '"\C-k": poweroff'
  '';
}
