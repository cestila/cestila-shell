{
  description = "cestila-shell - Quickshell desktop shell for Hyprland";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    {
      homeManagerModules.default = {
        config,
        lib,
        pkgs,
        ...
      }: {
        xdg.configFile."quickshell/cestila-shell" = {
          source = ./.;
          force = true;
        };

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
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.default = pkgs.stdenv.mkDerivation {
        pname = "cestila-shell";
        version = "0.1.0";
        src = ./.;
        installPhase = ''
          mkdir -p $out/share/quickshell/cestila-shell
          cp -r ./* $out/share/quickshell/cestila-shell/
        '';
      };
    });
}
