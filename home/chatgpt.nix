{ pkgs }:

pkgs.stdenv.mkDerivation rec {
  pname = "chatgpt-linux";
  version = "26.908.40834";

  src = pkgs.fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${version}_amd64.deb";
    hash = "sha256-2je457zvquoBnEeMrL5sc+4d3RXg4euzx+8KQt2BisI=";
  };

  nativeBuildInputs = with pkgs; [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = with pkgs; [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libGL
    libnotify
    libusb1
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemd
  ];
  dontStrip = true;
  # Chromium ships separate optional Qt 5/6 shims. Supply their libraries
  # without combining the mutually exclusive Qt development setup hooks.
  preFixup = ''
    addAutoPatchelfSearchPath ${pkgs.lib.getLib pkgs.qt5.qtbase}/lib
    addAutoPatchelfSearchPath ${pkgs.lib.getLib pkgs.qt6.qtbase}/lib
  '';
  runtimeDependencies = with pkgs; [
    libGL
    libnotify
    systemd
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib" "$out/bin" "$out/share"
    cp -a usr/lib/chatgpt "$out/lib/"
    cp -a usr/share/{applications,pixmaps,metainfo,doc} "$out/share/"

    # These bundled Node prebuilds target other operating systems or musl.
    find "$out/lib/chatgpt" -type d -path '*/prebuilds/*' \
      ! -path '*/prebuilds/*/*' ! -name '*linux-x64*' -prune -exec rm -rf {} +
    find "$out/lib/chatgpt" -depth -name '*musl*' -exec rm -rf {} +

    makeWrapper "$out/lib/chatgpt/ChatGPT" "$out/bin/chatgpt" \
      --prefix PATH : ${
        pkgs.lib.makeBinPath [
          pkgs.bubblewrap
          pkgs.xdg-utils
          pkgs.glib
          pkgs.git
          pkgs.xz
        ]
      } \
      --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name} \
      --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib \
      --add-flags '--ozone-platform=wayland'
    substituteInPlace "$out/share/applications/chatgpt.desktop" \
      --replace-fail 'Exec=chatgpt %U' "Exec=$out/bin/chatgpt %U"
    runHook postInstall
  '';

  meta = {
    description = "Official ChatGPT desktop app for Linux";
    homepage = "https://learn.chatgpt.com/docs/linux/linux-app";
    license = pkgs.lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "chatgpt";
  };
}
