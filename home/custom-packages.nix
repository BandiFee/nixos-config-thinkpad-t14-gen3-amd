# Locally patched or re-pinned packages used by the user session. Kept out of
# the system overlay so each override only affects the consumers below instead
# of every dependent in nixpkgs.
{ inputs, pkgs }:

let
  codexPkgs = inputs.codex-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
rec {
  claude-code-latest = pkgs.claude-code.override {
    manifest = {
      version = "2.1.302";
      platforms.linux-x64.checksum = "60d7eb7f12fbb28a52533fe8be5884097403562aa02dc73991a021c7067e29a5";
    };
  };

  rider-latest = pkgs.jetbrains.rider.overrideAttrs (_old: {
    version = "2026.2.3.1";
    src = pkgs.fetchurl {
      url = "https://download.jetbrains.com/rider/JetBrains.Rider-2026.2.3.1.tar.gz";
      sha256 = "fa4b09a5f7cf4b6635b093adc7313991778a8dc74f25614a2b8976b04dee5d4e";
    };
    buildNumber = "262.10968.170";
  });

  pycharm-latest = pkgs.jetbrains.pycharm.overrideAttrs (_old: {
    version = "2026.2.3";
    src = pkgs.fetchurl {
      url = "https://download.jetbrains.com/python/pycharm-2026.2.3.tar.gz";
      sha256 = "e8e4fbe4dab44390d09f681e059a316e692cabd24b2e11ce98ff76c8120fa313";
    };
    buildNumber = "262.10968.92";
  });

  rust-rover-latest = pkgs.jetbrains.rust-rover.overrideAttrs (_old: {
    version = "2026.2.4";
    src = pkgs.fetchurl {
      url = "https://download.jetbrains.com/rustrover/RustRover-2026.2.4.tar.gz";
      sha256 = "4036a06f18fd03da8809cb11b56d47ffa10e62ad12a9018682010f503c5513f6";
    };
    buildNumber = "262.10968.211";
  });

  # Noctalia's AirPods plugin needs this fork's status file and control verbs.
  librepods-noctalia = pkgs.librepods.overrideAttrs (_oldAttrs: {
    version = "0.2.5-unstable-2026-10-08";
    src = pkgs.fetchFromGitHub {
      owner = "harveywuk";
      repo = "librepods";
      rev = "4ed49df0b301ac3e6fba9c81dfbbb6726cc52201";
      hash = "sha256-Ygoqz5lnGMwZkys+Q4c4pyAUI0llvpGZ/ij5E91CkAg=";
    };
    sourceRoot = "source";
    cmakeFlags = [ "-DBUILD_TESTING=OFF" ];
    # Home Manager owns the service, with an immutable executable path.
    postInstall = ''
      rm -f $out/share/systemd/user/librepods.service
    '';
  });

  chatgpt-linux = import ./chatgpt.nix { inherit pkgs; };

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
          ../patches/noctalia-launcher-usage-first.patch
        ];
      });

  # Codex's arboard path can miss image files copied by Nautilus on Wayland.
  # Fall back to wl-paste for image data and the two file-list MIME types
  # Nautilus commonly publishes, while leaving the native path preferred.
  codex-clipboard-patched =
    (codexPkgs.codex.override {
      librusty_v8 = codexPkgs.fetchurl {
        url = "https://github.com/openai/codex/releases/download/rusty-v8-v150.4.0/librusty_v8_ptrcomp_sandbox_release_x86_64-unknown-linux-gnu.a.gz";
        hash = "sha256-o1x10fJuapg4haRbM0kKTr5U8FBQVosyuJz7QhswtYM=";
      };
    }).overrideAttrs
      (oldAttrs: rec {
        version = "0.163.0";

        src = codexPkgs.fetchFromGitHub {
          owner = "openai";
          repo = "codex";
          tag = "rust-v${version}";
          hash = "sha256-Fa9dfiGJy+uqSF4A0EM6AQQhhjQdu+jfhKzqXid9PNA=";
        };

        cargoDeps = codexPkgs.rustPlatform.fetchCargoVendor {
          inherit src version;
          pname = "codex";
          sourceRoot = "${src.name}/codex-rs";
          hash = "sha256-TG1fDHQCRDDbk+G0NS/9NTouJupq0Zisi4LIJY4SgYw=";
        };

        env = (oldAttrs.env or { }) // {
          RUSTY_V8_SRC_BINDING_PATH = codexPkgs.fetchurl {
            url = "https://github.com/openai/codex/releases/download/rusty-v8-v150.4.0/src_binding_ptrcomp_sandbox_release_x86_64-unknown-linux-gnu.rs";
            hash = "sha256-dyeCauR5vbZF6Acjn7EtH44uI956bPFvXuWSaQ0dhQY=";
          };
        };

        patches = (oldAttrs.patches or [ ]) ++ [
          ../patches/codex-wayland-clipboard-fallback.patch
        ];
        postPatch = (oldAttrs.postPatch or "") + ''
          substituteInPlace tui/src/clipboard_paste.rs \
            --replace-fail '@wl-paste@' '${codexPkgs.wl-clipboard}/bin/wl-paste'
        '';
      });

  # The shared app-server daemon only starts from an official package layout:
  # the real executable at bin/codex beside codex-package.json, with rg and
  # bwrap copied in (links leaving the package are rejected). Codex adds
  # codex-path to PATH itself, so the nixpkgs PATH wrapper is not needed.
  codex-with-wayland-clipboard-fallback =
    codexPkgs.runCommand "codex-packaged-${codex-clipboard-patched.version}"
      {
        inherit (codex-clipboard-patched) version meta;
      }
      ''
        mkdir -p $out/bin $out/codex-path $out/codex-resources
        cp ${codex-clipboard-patched}/bin/.codex-wrapped $out/bin/codex
        cp ${codex-clipboard-patched}/bin/codex-code-mode-host $out/bin/
        cp ${codexPkgs.ripgrep}/bin/rg $out/codex-path/rg
        cp ${codexPkgs.bubblewrap}/bin/bwrap $out/codex-resources/bwrap
        cp -r ${codex-clipboard-patched}/share $out/share
        cat > $out/codex-package.json <<EOF
        {"layoutVersion":1,"version":"${codex-clipboard-patched.version}","target":"x86_64-unknown-linux-gnu","entrypoint":"bin/codex"}
        EOF
      '';

  # The QQ URL in the pinned nixpkgs revision was removed from Tencent's CDN.
  # Keep using the nixpkgs wrapper, but point it at a newer official package.
  # Force QQ onto XWayland so it shares one reliable clipboard path with WeChat;
  # other Chromium/Electron applications can continue using native Wayland.
  qq-xwayland-with-working-source =
    (pkgs.qq.override {
      commandLineArgs = "--ozone-platform=x11";
    }).overrideAttrs
      (_oldAttrs: {
        version = "3.2.32-2026-08-12";
        src = pkgs.fetchurl {
          url = "https://qqdl.gtimg.cn/qqfile/QQNT/9.9.33/release/3f89efc5/QQ_3.2.32_260812_amd64_01.deb";
          hash = "sha256-0IXdiTlyJQYeufGUMI9ogSmBjtRFd36XpKChbhPXsOg=";
        };
      });

  # Pin the official Linux release independently of the system package set.
  wechat-latest = pkgs.callPackage "${pkgs.path}/pkgs/by-name/we/wechat/linux.nix" {
    inherit (pkgs.wechat) pname meta;
    version = "4.1.13.26";
    src = pkgs.fetchurl {
      url = "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage";
      hash = "sha256-RSYYC8qYASh5FZmvEi/0eVACpXFaUQ9qZUgOK+aHQkQ=";
    };
  };

  # WeChat is an XWayland Qt application and does not use the native Wayland
  # input-method path. Select its bundled Fcitx platform input context without
  # forcing the same choice on native Wayland Qt applications.
  wechat-with-fcitx = pkgs.symlinkJoin {
    name = "wechat-with-fcitx";
    paths = [ wechat-latest ];
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
    paths = [ rider-latest ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/rider \
        --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.fontconfig ]}"
    '';
  };
}
