# Locally patched or re-pinned packages used by the user session. Kept out of
# the system overlay so each override only affects the consumers below instead
# of every dependent in nixpkgs.
{ inputs, pkgs }:

rec {
  go-musicfox-latest = pkgs.go-musicfox.overrideAttrs (_oldAttrs: rec {
    version = "5.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "go-musicfox";
      repo = "go-musicfox";
      rev = "v${version}";
      hash = "sha256-gM3gnUbevPSa2gmiC0DGYPrVRtwHF2TQB0Hu99ISVU8=";
    };

    vendorHash = "sha256-+lmsd7fqdlKxxXGh6Zwl9xtNXPZrR3xqgROzI9L4xls=";

    # Balance the cover/lyric group for wide terminals and bilingual lyrics.
    patches = (_oldAttrs.patches or [ ]) ++ [
      ../patches/go-musicfox-balanced-layout.patch
    ];
  });

  noctalia-with-mpris-lyrics =
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          ../patches/noctalia-mpris-lyrics.patch
          ../patches/noctalia-color-role-alpha.patch
          ../patches/noctalia-lockscreen-typography.patch
          ../patches/noctalia-hover-primary-container.patch
          ../patches/noctalia-fingerprint-release-on-abort.patch
        ];
      });

  # Codex's arboard path can miss image files copied by Nautilus on Wayland.
  # Fall back to wl-paste for image data and the two file-list MIME types
  # Nautilus commonly publishes, while leaving the native path preferred.
  codex-with-wayland-clipboard-fallback = pkgs.codex.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ../patches/codex-wayland-clipboard-fallback.patch
    ];
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace tui/src/clipboard_paste.rs \
        --replace-fail '@wl-paste@' '${pkgs.wl-clipboard}/bin/wl-paste'
    '';
  });

  # The QQ URL in the pinned nixpkgs revision was removed from Tencent's CDN.
  # Keep using the nixpkgs wrapper, but point it at a newer official package.
  # Force QQ onto XWayland so it shares one reliable clipboard path with WeChat;
  # other Chromium/Electron applications can continue using native Wayland.
  qq-xwayland-with-working-source =
    (pkgs.qq.override {
      commandLineArgs = "--ozone-platform=x11";
    }).overrideAttrs
      (_oldAttrs: {
        version = "3.2.32-2026-07-30";
        src = pkgs.fetchurl {
          url = "https://qqdl.gtimg.cn/qqfile/QQNT/9.9.33/release/c97651b2/QQ_3.2.32_260730_amd64_01.deb";
          hash = "sha256-ga4rhULvUxH8cuz1PJpSOSPINFacew2lLgv0Nguctfk=";
        };
      });

  # WeChat is an XWayland Qt application and does not use the native Wayland
  # input-method path. Select its bundled Fcitx platform input context without
  # forcing the same choice on native Wayland Qt applications.
  wechat-with-fcitx = pkgs.symlinkJoin {
    name = "wechat-with-fcitx";
    paths = [ pkgs.wechat ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/wechat --set QT_IM_MODULE fcitx
    '';
  };

  librime-with-caps-lock-resync = pkgs.librime.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ../patches/librime-resync-caps-lock.patch
    ];
  });

  fcitx5-rime-with-ice = pkgs.fcitx5-rime.override {
    librime = librime-with-caps-lock-resync;
    rimeDataPkgs = [ pkgs.rime-ice ];
  };

  # Rider already exposes its X11 libraries to child processes. Add fontconfig
  # as well so Avalonia/SkiaSharp applications launched by Rider can load their
  # bundled native renderer without setting LD_LIBRARY_PATH globally.
  rider-with-avalonia-libs = pkgs.symlinkJoin {
    name = "rider-with-avalonia-libs";
    paths = [ pkgs.jetbrains.rider ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/rider \
        --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.fontconfig ]}"
    '';
  };
}
