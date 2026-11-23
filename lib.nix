{ lib, ... }:
rec {
  mkSystem =
    { system, modules }:
    lib.nixosSystem {
      modules = [ { nixpkgs.hostPlatform = system; } ] ++ modules;
    };

  mkVM = args: (mkSystem args).config.system.build.vm;
}
