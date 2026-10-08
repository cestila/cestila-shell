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

  # Run the shell as a user service bound to the Hyprland session so it always
  # uses the declarative quickshell binary (never a stale PATH entry) and is
  # restarted if it crashes.
  systemd.user.services.cestila-shell = {
    Unit = {
      Description = "Cestila Shell (Quickshell top bar, sidebar and launcher)";
      PartOf = ["hyprland-session.target"];
      After = ["hyprland-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell -c cestila-shell";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = ["hyprland-session.target"];
  };
}
