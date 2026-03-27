{
  description = "Nix package for Reachy Mini Desktop App";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      supportedSystems = [ "x86_64-linux" ];
    in
    flake-utils.lib.eachSystem supportedSystems (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        reachyMiniDesktopApp = pkgs.callPackage ./package.nix { };
      in
      {
        packages = {
          reachy-mini-desktop-app = reachyMiniDesktopApp;
          default = reachyMiniDesktopApp;
        };

        apps = {
          reachy-mini-desktop-app = {
            type = "app";
            program = "${reachyMiniDesktopApp}/bin/reachy-mini-control";
            meta = {
              description = "Run Reachy Mini Control";
            };
          };
          default = {
            type = "app";
            program = "${reachyMiniDesktopApp}/bin/reachy-mini-control";
            meta = {
              description = "Run Reachy Mini Control";
            };
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.bash
            pkgs.deadnix
            pkgs.git
            pkgs.jq
            pkgs.just
            pkgs.nix
            pkgs.nixfmt
            pkgs.perl
            pkgs.prek
            pkgs.ripgrep
            pkgs.shellcheck
            pkgs.statix
          ];
        };

        formatter = pkgs.nixfmt;
      }
    );
}
