{
  config,
  lib,
  pkgs,
  ...
}: {
  # The shell provides its own network and bluetooth indicators.
  imports = [../hide-tray-applets.nix];

  xdg.configFile."quickshell/cestila-shell" = {
    source = ./.;
    force = true;
  };

  # Run the shell as a user service pointing directly to the workspace config
  # so code edits are immediately active with a restart (or qs reload) without
  # having to do a full nixos-rebuild for every QML tweak.
  systemd.user.services.cestila-shell = {
    Unit = {
      Description = "Cestila Shell (Quickshell top bar, sidebar and launcher)";
      PartOf = ["hyprland-session.target"];
      After = ["hyprland-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell -p %h/.config/quickshell/cestila-shell/shell.qml";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = ["hyprland-session.target"];
  };
}
