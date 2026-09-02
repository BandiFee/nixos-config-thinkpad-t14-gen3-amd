{
  inputs,
  lib,
  pkgs,
  ...
}:

let
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
      ./patches/go-musicfox-balanced-layout.patch
    ];
  });

  noctalia-color-role-alpha-patch = pkgs.writeText "noctalia-color-role-alpha.patch" ''
    diff --git a/src/config/config_types.cpp b/src/config/config_types.cpp
    --- a/src/config/config_types.cpp
    +++ b/src/config/config_types.cpp
    @@ -45,3 +45,21 @@
    -    if (auto role = colorRoleFromToken(trimmed)) {
    -      return colorSpecFromRole(*role);
    +
    +    std::string_view roleToken = trimmed;
    +    float alpha = 1.0F;
    +    if (const auto slash = roleToken.find('/'); slash != std::string_view::npos) {
    +      if (roleToken.find('/', slash + 1) != std::string_view::npos) {
    +        throw std::runtime_error(colorSpecError(raw, context));
    +      }
    +      const std::string_view alphaToken = roleToken.substr(slash + 1);
    +      roleToken = roleToken.substr(0, slash);
    +      char trailing = '\0';
    +      if (alphaToken.empty()
    +          || std::sscanf(std::string(alphaToken).c_str(), "%f%c", &alpha, &trailing) != 1
    +          || alpha < 0.0F
    +          || alpha > 1.0F) {
    +        throw std::runtime_error(colorSpecError(raw, context));
    +      }
    +    }
    +
    +    if (auto role = colorRoleFromToken(roleToken)) {
    +      return colorSpecFromRole(*role, alpha);
         }
    @@ -579,1 +597,5 @@
    -    return std::string(colorRoleToken(*spec.role));
    +    std::string result(colorRoleToken(*spec.role));
    +    if (spec.alpha < 0.999F) {
    +      result += "/" + std::to_string(spec.alpha);
    +    }
    +    return result;
  '';

  noctalia-lockscreen-typography-patch = pkgs.writeText "noctalia-lockscreen-typography.patch" ''
    diff --git a/src/shell/desktop/widgets/desktop_label_widget.cpp b/src/shell/desktop/widgets/desktop_label_widget.cpp
    --- a/src/shell/desktop/widgets/desktop_label_widget.cpp
    +++ b/src/shell/desktop/widgets/desktop_label_widget.cpp
    @@ -33,7 +33,7 @@
           .out = &m_titleLabel,
           .text = m_title,
           .fontSize = titleFontSize(contentScale()),
    -      .fontWeight = FontWeight::Bold,
    +      .fontWeight = FontWeight::Medium,
           .color = m_color,
           .maxLines = 3,
           .textAlign = TextAlign::Start,
    diff --git a/src/shell/desktop/widgets/desktop_clock_widget.cpp b/src/shell/desktop/widgets/desktop_clock_widget.cpp
    --- a/src/shell/desktop/widgets/desktop_clock_widget.cpp
    +++ b/src/shell/desktop/widgets/desktop_clock_widget.cpp
    @@ -219,7 +219,7 @@
       auto label = ui::label({
           .out = &m_label,
           .fontSize = clockFontSize(contentScale()),
    -      .fontWeight = FontWeight::Bold,
    +      .fontWeight = FontWeight::Light,
           .color = m_color,
       });
       m_digitalRoot->addChild(std::move(label));
    @@ -574,7 +574,7 @@
         for (char digit = '0'; digit <= '9'; ++digit) {
           const std::string glyph(1, digit);
           const float advance =
    -          renderer.measureText(glyph, fontSize, FontWeight::Bold, 0.0F, 0, TextAlign::Start, m_fontFamily).width;
    +          renderer.measureText(glyph, fontSize, FontWeight::Light, 0.0F, 0, TextAlign::Start, m_fontFamily).width;
           if (advance > widest) {
             widest = advance;
             m_widestDigit = digit;
    @@ -597,7 +597,7 @@
       m_stableSample = sample;

       const float width =
    -      renderer.measureText(sample, fontSize, FontWeight::Bold, 0.0F, 0, TextAlign::Start, m_fontFamily).width;
    +      renderer.measureText(sample, fontSize, FontWeight::Light, 0.0F, 0, TextAlign::Start, m_fontFamily).width;
       if (std::abs(width - m_stableWidth) > 0.5F) {
         m_stableWidth = width;
         m_label->setMinWidth(m_stableWidth);
  '';

  noctalia-with-mpris-lyrics =
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          ./patches/noctalia-mpris-lyrics.patch
          noctalia-color-role-alpha-patch
          noctalia-lockscreen-typography-patch
          ./patches/noctalia-hover-primary-container.patch
          ./patches/noctalia-fingerprint-release-on-abort.patch
        ];
      });

  # Codex's arboard path can miss image files copied by Nautilus on Wayland.
  # Fall back to wl-paste for image data and the two file-list MIME types
  # Nautilus commonly publishes, while leaving the native path preferred.
  codex-with-wayland-clipboard-fallback = pkgs.codex.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./patches/codex-wayland-clipboard-fallback.patch
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
      ./patches/librime-resync-caps-lock.patch
    ];
  });

  fcitx5-rime-with-ice = pkgs.fcitx5-rime.override {
    librime = librime-with-caps-lock-resync;
    rimeDataPkgs = [ pkgs.rime-ice ];
  };

  # Rime compares source mtimes before rebuilding schemas. Files symlinked
  # directly from the Nix store have an epoch mtime, so keep this particular
  # override mutable and compile it before Fcitx starts whenever it changes.
  rime-ice-custom = ./config/rime/rime_ice.custom.yaml;

  deploy-rime-ice = pkgs.writeShellScript "deploy-rime-ice" ''
    set -eu

    rime_dir=/home/bandifee/.local/share/fcitx5/rime
    custom_file="$rime_dir/rime_ice.custom.yaml"

    if ! ${pkgs.diffutils}/bin/cmp -s ${rime-ice-custom} "$custom_file" \
      || [ ! -e "$rime_dir/build/rime_ice.schema.yaml" ]; then
      ${pkgs.coreutils}/bin/mkdir -p "$rime_dir"
      ${pkgs.coreutils}/bin/cp --remove-destination \
        ${rime-ice-custom} "$custom_file"
      ${librime-with-caps-lock-resync}/bin/rime_deployer --compile \
        ${fcitx5-rime-with-ice}/share/rime-data/rime_ice.schema.yaml \
        "$rime_dir" \
        ${fcitx5-rime-with-ice}/share/rime-data \
        "$rime_dir/build"
    fi
  '';

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
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  home = {
    username = "bandifee";
    homeDirectory = "/home/bandifee";
    stateVersion = "26.05";

    packages = [
      pkgs.brightnessctl
      pkgs.claude-code
      codex-with-wayland-clipboard-fallback
      pkgs.curl
      pkgs.deadnix
      pkgs.dotnet-sdk_10
      pkgs.fastfetch
      pkgs.fd
      pkgs.ffmpeg
      pkgs.file-roller
      pkgs.gcc
      go-musicfox-latest
      pkgs.google-chrome
      pkgs.hyperfine
      pkgs.inter
      pkgs.jetbrains.pycharm
      pkgs.jetbrains.rust-rover
      pkgs.jq
      pkgs.just
      pkgs.libreoffice
      pkgs.loupe
      rider-with-avalonia-libs
      pkgs.micromamba
      pkgs.mpv
      # Video wallpaper renderer used by Noctalia's official mpvpaper plugin.
      pkgs.mpvpaper
      pkgs.nautilus
      pkgs.nixd
      pkgs.nixfmt
      pkgs.nix-output-monitor
      pkgs.nix-tree
      pkgs.obs-studio
      pkgs.p7zip
      pkgs.papers
      pkgs.pavucontrol
      pkgs.playerctl
      qq-xwayland-with-working-source
      pkgs.ripgrep
      pkgs.rustup
      pkgs.shellcheck
      pkgs.shfmt
      pkgs.splayer
      pkgs.statix
      pkgs.typora
      pkgs.unzip
      pkgs.vscode
      wechat-with-fcitx
      pkgs.wget
      pkgs.wl-clipboard
      pkgs.wl-mirror
      pkgs.zip
    ];

    pointerCursor = {
      enable = true;
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 24;
    };

    sessionVariables = {
      BROWSER = "google-chrome-stable";
      NIXOS_OZONE_WL = "1";
      TERMINAL = "kitty";
    };

    # Prefer the locally patched musicfox even before a system-level
    # nixos-rebuild updates /etc/profiles/per-user.
    sessionPath = [ "${go-musicfox-latest}/bin" ];
  };

  programs.home-manager.enable = true;

  programs.bat.enable = true;

  programs.btop.enable = true;

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };

  programs.eza = {
    enable = true;

    # Keep the traditional ls command and its existing behavior available.
    enableFishIntegration = false;
  };

  programs.firefox.enable = true;

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.gh.enable = true;

  programs.git.enable = true;

  programs.lazygit = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.nh = {
    enable = true;
    osFlake = "/etc/nixos";
  };

  programs.vim.enable = true;

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # Terminal file manager. The Fish integration provides `y`, which returns
  # the shell to Yazi's current directory when Yazi exits.
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";

    settings.mgr = {
      # Give the current directory and preview more room than the parent pane.
      ratio = [
        1
        3
        4
      ];
      sort_by = "natural";
      sort_sensitive = false;
      sort_reverse = false;
      sort_dir_first = true;
      linemode = "size";
      show_hidden = false;
      show_symlink = true;
      scrolloff = 5;
    };
  };

  # Rime-based Chinese input. Home Manager starts Fcitx5 after the Niri
  # graphical session is ready, keeping its environment correct for Wayland.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      waylandFrontend = true;

      addons = [
        fcitx5-rime-with-ice
        pkgs.fcitx5-mozc
        (pkgs.catppuccin-fcitx5.override { withRoundedCorners = true; })
      ];

      settings = {
        globalOptions."Hotkey/TriggerKeys"."0" = "Super+space";
        # Let Rime handle a bare left Shift so commit_code can preserve the
        # raw composition instead of Fcitx temporarily deactivating Rime.
        globalOptions."Hotkey/AltTriggerKeys" = { };

        # Noctalia rewrites this theme from the current wallpaper palette.
        addons.classicui.globalSection.Theme = "noctalia-glass";

        inputMethod = {
          GroupOrder."0" = "Default";
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "rime";
          };
          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1" = {
            Layout = "us";
            Name = "rime";
          };
          "Groups/0/Items/2" = {
            Layout = "us";
            Name = "mozc";
          };
        };
      };
    };
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting

      # Pick up the patched musicfox immediately, even when this shell inherited
      # session variables from before the latest Home Manager activation.
      if not contains -- ${go-musicfox-latest}/bin $PATH
        set -gx PATH ${go-musicfox-latest}/bin $PATH
      end

      # Micromamba
      set -gx MAMBA_ROOT_PREFIX $HOME/.mamba
      micromamba shell hook --shell fish | source
    '';
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ./config/starship.toml);
  };

  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };

    shellIntegration.enableFishIntegration = true;

    settings = {
      # A dark glass-like surface: black tint with the wallpaper showing through.
      background_opacity = 0.70;
      background_blur = 1;
      window_padding_width = 10;
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      enabled_layouts = "splits:split_axis=auto;equalize_on_close=true,stack";

      # Keep Nerd Font icons consistent across Linux and macOS. Without this,
      # the patched JetBrains Mono face may render private-use glyphs itself
      # instead of letting Kitty use its bundled Symbols Nerd Font.
      symbol_map = "U+e000-U+e00a,U+e0a0-U+e0a2,U+e0a3,U+e0b0-U+e0b3,U+e0b4-U+e0c8,U+e0ca,U+e0cc-U+e0d7,U+e200-U+e2a9,U+e300-U+e3e3,U+e5fa-U+e6b7,U+e700-U+e8ef,U+ea60-U+ec1e,U+ed00-U+efce,U+f000-U+f2ff,U+f300-U+f381,U+f400-U+f533,U+f0001-U+f1af0 Symbols Nerd Font Mono";

      background = "#000000";
      foreground = "#cdd6f4";
      cursor = "#f5e0dc";
      # Animate jumps of the text cursor so movement stays easy to follow.
      cursor_trail = 3;
      cursor_trail_decay = "0.1 0.4";
      cursor_trail_start_threshold = 2;
      selection_background = "#45475a";
      selection_foreground = "#cdd6f4";
      active_border_color = "#cba6f7";
      inactive_border_color = "#45475a";

      color0 = "#45475a";
      color1 = "#f38ba8";
      color2 = "#a6e3a1";
      color3 = "#f9e2af";
      color4 = "#89b4fa";
      color5 = "#f5c2e7";
      color6 = "#94e2d5";
      color7 = "#bac2de";
      color8 = "#585b70";
      color9 = "#f38ba8";
      color10 = "#a6e3a1";
      color11 = "#f9e2af";
      color12 = "#89b4fa";
      color13 = "#f5c2e7";
      color14 = "#94e2d5";
      color15 = "#a6adc8";
    };

    keybindings = {
      "ctrl+shift+o" = "launch --cwd=current --location=vsplit";
      "ctrl+shift+e" = "launch --cwd=current --location=hsplit";
      "ctrl+alt+left" = "neighboring_window left";
      "ctrl+alt+down" = "neighboring_window down";
      "ctrl+alt+up" = "neighboring_window up";
      "ctrl+alt+right" = "neighboring_window right";
      "ctrl+shift+enter" = "toggle_layout stack";
    };

  };

  # Niri starts Noctalia with the graphical session. The upstream module
  # installs the cached package and validates this TOML during the build.
  programs.noctalia = {
    enable = true;
    package = noctalia-with-mpris-lyrics;
    systemd.enable = false;
    settings = ./config/noctalia/config.toml;
  };

  # Noctalia stores Settings UI edits separately from the declarative config.
  # Remove only the old lockscreen widget override once so this new Nix-owned
  # layout can take effect; preserve all wallpaper, theme and other user state.
  home.activation.noctalia-lockscreen-layout-v1 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    state_dir="$HOME/.local/state/noctalia"
    settings_file="$state_dir/settings.toml"
    migration_marker="$state_dir/.nix-lockscreen-layout-v1"

    if [ -f "$settings_file" ] && [ ! -e "$migration_marker" ]; then
      run ${pkgs.coreutils}/bin/cp --preserve=mode,timestamps \
        "$settings_file" "$settings_file.before-lockscreen-layout-v1"
      run ${pkgs.gawk}/bin/awk '
        /^\[lockscreen_widgets\]$/ { skipping = 1; next }
        skipping && /^\[[^.]+\]$/ { skipping = 0 }
        !skipping { print }
      ' "$settings_file" > "$settings_file.nix-lockscreen-layout-v1"
      run ${pkgs.coreutils}/bin/mv \
        "$settings_file.nix-lockscreen-layout-v1" "$settings_file"
      run ${pkgs.coreutils}/bin/touch "$migration_marker"
    fi
  '';

  # The authorization agent belongs to the graphical user session while the
  # Polkit daemon itself remains enabled system-wide in configuration.nix.
  systemd.user.services.polkit-gnome-authentication-agent = {
    Unit = {
      Description = "Polkit authentication agent";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart =
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.fcitx5-daemon.Service.ExecStartPre = deploy-rime-ice;

  xdg = {
    enable = true;

    # Use Rime Ice's maintained Simplified Chinese dictionaries and schemas.
    dataFile."fcitx5/rime/default.custom.yaml".text = ''
      patch:
        __include: rime_ice_suggestion:/
    '';

    mimeApps = {
      enable = true;
      defaultApplications = {
        "image/avif" = [ "org.gnome.Loupe.desktop" ];
        "image/bmp" = [ "org.gnome.Loupe.desktop" ];
        "image/gif" = [ "org.gnome.Loupe.desktop" ];
        "image/heic" = [ "org.gnome.Loupe.desktop" ];
        "image/heif" = [ "org.gnome.Loupe.desktop" ];
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        "image/png" = [ "org.gnome.Loupe.desktop" ];
        "image/svg+xml" = [ "org.gnome.Loupe.desktop" ];
        "image/tiff" = [ "org.gnome.Loupe.desktop" ];
        "image/webp" = [ "org.gnome.Loupe.desktop" ];
        "text/html" = [ "google-chrome.desktop" ];
        "x-scheme-handler/http" = [ "google-chrome.desktop" ];
        "x-scheme-handler/https" = [ "google-chrome.desktop" ];
        "x-scheme-handler/terminal" = [ "kitty.desktop" ];
      };
    };

    configFile."niri/config.kdl".source = ./config/niri/config.kdl;
    configFile."noctalia/templates/fcitx5/theme.conf".source =
      ./config/noctalia/templates/fcitx5/theme.conf;
    configFile."noctalia/templates/fcitx5/panel.svg".source =
      ./config/noctalia/templates/fcitx5/panel.svg;
    configFile."noctalia/templates/fcitx5/highlight.svg".source =
      ./config/noctalia/templates/fcitx5/highlight.svg;
    # Home Manager already owns Fcitx5's graphical-session service. Disable
    # the package's XDG autostart entry so the two instances do not race.
    configFile."autostart/org.fcitx.Fcitx5.desktop".text = ''
      [Desktop Entry]
      Hidden=true
    '';
    configFile."go-musicfox/config.toml".text = ''
      [main.notification]
      enable = false
      inApp = false

      [main.lyric.cover]
      show = true
      widthRatio = 0.22
      cornerRadius = 10
      spin = false

      [theme]
      centerEverything = true
    '';
    configFile."fastfetch/config.jsonc".source =
      ./config/fastfetch/config.jsonc;
    configFile."fastfetch/logo.png".source = ./config/fastfetch/logo.png;
  };
}
