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
  # Escape sequences are interpreted by agetty, see `man agetty`
  services.getty.helpLine = ''

    ╭──────────────────────────────────────────────╮
    │                                              │
    │  \e{cyan}██████╗ ███████╗██╗   ██╗ ██████╗ ███████╗\e{reset}  │
    │  \e{cyan}██╔══██╗██╔════╝██║   ██║██╔═══██╗██╔════╝\e{reset}  │
    │  \e{cyan}██║  ██║█████╗  ██║   ██║██║   ██║███████╗\e{reset}  │
    │  \e{cyan}██║  ██║██╔══╝  ╚██╗ ██╔╝██║   ██║╚════██║\e{reset}  │
    │  \e{cyan}██████╔╝███████╗ ╚████╔╝ ╚██████╔╝███████║\e{reset}  │
    │  \e{cyan}╚═════╝ ╚══════╝  ╚═══╝   ╚═════╝ ╚══════╝\e{reset}  │
    │                                              │
    │  Follow service logs   \e{green}journalctl -f\e{reset}         │
    │  Power off the VM      \e{green}Ctrl-k\e{reset}                │
    │                                              │
    ╰──────────────────────────────────────────────╯
  '';

  system.stateVersion = "26.11";

  programs.bash.shellInit = ''
    bind -x '"\C-k": poweroff'
  '';
}
