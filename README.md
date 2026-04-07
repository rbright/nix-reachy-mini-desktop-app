# nix-reachy-mini-desktop-app

[![CI](https://github.com/rbright/nix-reachy-mini-desktop-app/actions/workflows/ci.yml/badge.svg)](https://github.com/rbright/nix-reachy-mini-desktop-app/actions/workflows/ci.yml)

Nix package for [Reachy Mini Desktop App](https://github.com/pollen-robotics/reachy-mini-desktop-app).

## What this repo provides

- Nix package: `reachy-mini-desktop-app` (binary: `reachy-mini-control`)
- Nix app output: `.#reachy-mini-desktop-app`
- Packaging for the upstream Linux `.deb` release
- Desktop entry for launchers like Walker/Vicinae
- Reachy Mini udev rule shipped at `lib/udev/rules.d/99-reachy-mini.rules`
- Scripted updater for version/source hash pin refresh
- Scheduled GitHub Actions updater that opens auto-mergeable PRs
- Automated GitHub release creation on `reachy-mini-desktop-app` version bumps
- Local quality gate (`just`) and GitHub Actions CI

## Upstream source pin

Current source URL:

- `https://github.com/pollen-robotics/reachy-mini-desktop-app/releases/download/v0.9.26/Reachy.Mini.Control_0.9.26_amd64.deb`

## Update workflow

```sh
# latest stable upstream release
just update

# explicit version
just update 0.9.26
```

`./scripts/update-package.sh` updates both values in `package.nix`:

- `version`
- `src.hash`

### Updater prerequisites

- `git`
- `jq`
- `nix`
- `perl`

Check script usage:

```sh
./scripts/update-package.sh --help
```

## Automated GitHub updates

Workflow: `.github/workflows/update-reachy-mini-desktop-app.yml`

- Runs every 6 hours and on manual dispatch.
- Detects the latest stable upstream tag from `pollen-robotics/reachy-mini-desktop-app`.
- If newer than `package.nix`, runs `scripts/update-package.sh` and opens/updates a PR.
- Enables auto-merge (`squash`) for that PR.

### One-time repository setup

1. Add repo secret `REACHY_MINI_DESKTOP_APP_UPDATER_TOKEN` (fine-grained PAT scoped to this repo):
   - **Contents**: Read and write
   - **Pull requests**: Read and write
2. In repository settings → **Actions → General**:
   - Set workflow permissions to **Read and write permissions**.
   - Enable **Allow GitHub Actions to create and approve pull requests**.
3. Ensure branch protection/required checks allow auto-merge after CI passes.

Manual trigger:

- Actions → **Update Reachy Mini Desktop App package** → **Run workflow**
- Optional input: `version` (accepts `0.x.y` or `v0.x.y`)

## Automated GitHub releases

Workflow: `.github/workflows/release-reachy-mini-desktop-app.yml`

- Runs on pushes to `main` when `package.nix` changes.
- Compares previous and current `package.nix` `version` values.
- Creates a GitHub release + tag named `v<version>` only when the packaged version changes.
- Skips docs-only merges and other changes that do not modify `package.nix` version.

No extra secret is required; it uses the workflow `GITHUB_TOKEN` with `contents: write`.

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
