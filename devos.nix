{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];

  virtualisation.graphics = false;

  networking.firewall.enable = false;

  services.getty.autologinUser = "root";

  system.stateVersion = "26.11";

  programs.bash.shellInit = ''
    bind -x '"\C-k": poweroff'
  '';
}
