{
  config,
  lib,
  pkgs,
  ...
}: {
  xdg.configFile."quickshell/cestila-shell" = {
    source = ./.;
    force = true;
  };
}
