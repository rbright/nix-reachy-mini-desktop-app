{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  gtk3,
  libsoup_3,
  openssl,
  portaudio,
  systemd,
  webkitgtk_4_1,
  zlib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "reachy-mini-desktop-app";
  version = "0.9.29";

  src = fetchurl {
    url = "https://github.com/pollen-robotics/reachy-mini-desktop-app/releases/download/v${version}/Reachy.Mini.Control_${version}_amd64.deb";
    hash = "sha256-j5m6WfmmVe7yC79EtZ/W5lMzYuGzj2z99m83neu/YWo=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    gtk3
    libsoup_3
    openssl
    portaudio
    systemd
    webkitgtk_4_1
    zlib
  ];

  # Python's sounddevice backend loads libportaudio dynamically at runtime.
  runtimeDependencies = [ portaudio ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    dpkg-deb -x "$src" unpacked
    cp -r unpacked/usr/. "$out/"

    rule_source=""
    for candidate in \
      "unpacked/usr/share/reachy-mini-control/99-reachy-mini.rules" \
      "unpacked/etc/udev/rules.d/99-reachy-mini.rules"
    do
      if [ -f "$candidate" ]; then
        rule_source="$candidate"
        break
      fi
    done

    if [ -z "$rule_source" ]; then
      echo "Missing Reachy Mini udev rule in extracted package" >&2
      exit 1
    fi

    install -Dm644 \
      "$rule_source" \
      "$out/lib/udev/rules.d/99-reachy-mini.rules"

    # Work around Hyprland/WebKitGTK rendering issues (Wayland protocol error
    # and blank panes from failed GBM allocation). Users can still override.
    mv "$out/bin/reachy-mini-control" "$out/bin/.reachy-mini-control-unwrapped"
    makeWrapper "$out/bin/.reachy-mini-control-unwrapped" "$out/bin/reachy-mini-control" \
      --set-default GDK_BACKEND x11 \
      --set-default WEBKIT_DISABLE_DMABUF_RENDERER 1

    # Normalize desktop file naming for launcher discovery consistency.
    if [ -f "$out/share/applications/Reachy Mini Control.desktop" ]; then
      mv \
        "$out/share/applications/Reachy Mini Control.desktop" \
        "$out/share/applications/reachy-mini-control.desktop"
    fi

    runHook postInstall
  '';

  meta = {
    description = "Desktop control app for Reachy Mini";
    homepage = "https://github.com/pollen-robotics/reachy-mini-desktop-app";
    mainProgram = "reachy-mini-control";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
}
