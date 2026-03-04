# nix-reachy-mini-desktop-app

[![CI](https://github.com/rbright/nix-reachy-mini-desktop-app/actions/workflows/ci.yml/badge.svg)](https://github.com/rbright/nix-reachy-mini-desktop-app/actions/workflows/ci.yml)

Nix package for [Reachy Mini Desktop App](https://github.com/pollen-robotics/reachy-mini-desktop-app).

## What this repo provides

- Nix package: `reachy-mini-desktop-app` (binary: `reachy-mini-control`)
- Nix app output: `.#reachy-mini-desktop-app`
- Packaging for the upstream Linux `.deb` release
- Desktop entry for launchers like Walker/Vicinae
- Reachy Mini udev rule shipped at `lib/udev/rules.d/99-reachy-mini.rules`
- Local quality gate (`just`) and GitHub Actions CI

## Upstream source pin

Current source URL:

- `https://github.com/pollen-robotics/reachy-mini-desktop-app/releases/download/v0.9.19/Reachy.Mini.Control_0.9.19_amd64.deb`

## Quickstart

```sh
# list commands
just --list

# full local validation gate
just check

# build
just build
```

## Build and run directly with Nix

```sh
nix build -L 'path:.#reachy-mini-desktop-app'
nix run 'path:.#reachy-mini-desktop-app'
```

## Notes

- Upstream license: Apache-2.0.
- Platform: `x86_64-linux`.
- For USB device access, add the package to `services.udev.packages` and ensure your user is in `dialout`.
- The launcher defaults `GDK_BACKEND=x11` and `WEBKIT_DISABLE_DMABUF_RENDERER=1` to avoid Hyprland/WebKitGTK protocol and blank-render issues.

## Use from another flake

```nix
{
  inputs.reachyMiniDesktopApp.url = "github:rbright/nix-reachy-mini-desktop-app";

  outputs = { self, nixpkgs, reachyMiniDesktopApp, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            reachyMiniDesktopApp.packages.${pkgs.system}."reachy-mini-desktop-app"
          ];

          services.udev.packages = [
            reachyMiniDesktopApp.packages.${pkgs.system}."reachy-mini-desktop-app"
          ];
        })
      ];
    };
  };
}
```
