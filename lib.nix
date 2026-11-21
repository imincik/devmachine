{ lib, ... }:
{
  mkVM =
    { system, modules }:
    (lib.nixosSystem {
      modules = [ { nixpkgs.hostPlatform = system; } ] ++ modules;
    }).config.system.build.vm;
}
