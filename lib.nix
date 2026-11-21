{ lib, ... }:
{
  mkVM =
    {
      system ? "x86_64-linux",
      modules,
    }:
    (lib.nixosSystem { inherit system modules; }).config.system.build.vm;
}
