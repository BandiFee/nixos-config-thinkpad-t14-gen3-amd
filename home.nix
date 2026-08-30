{ inputs, pkgs, ... }:

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

  noctalia-with-mpris-lyrics =
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          ./patches/noctalia-mpris-lyrics.patch
        ];
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
      pkgs.codex
      pkgs.curl
      pkgs.dotnet-sdk_10
      pkgs.fastfetch
      pkgs.ffmpeg
      pkgs.file-roller
      pkgs.gcc
      go-musicfox-latest
      pkgs.jetbrains.pycharm
      pkgs.jetbrains.rust-rover
      pkgs.libreoffice
      rider-with-avalonia-libs
      # Avoid the GNOME Keyring prompt after fingerprint login. This stores
      # Chrome's local encryption key without OS keyring protection.
      (pkgs.google-chrome.override {
        commandLineArgs = "--password-store=basic";
      })
      pkgs.micromamba
      pkgs.nautilus
      pkgs.pavucontrol
      pkgs.playerctl
      qq-xwayland-with-working-source
      pkgs.rustup
      pkgs.splayer
      pkgs.typora
      pkgs.vscode
      pkgs.wechat
      pkgs.wget
      pkgs.wl-clipboard
      pkgs.wl-mirror
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

  programs.btop.enable = true;

  programs.firefox.enable = true;

  programs.git.enable = true;

  programs.vim.enable = true;

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
        (pkgs.fcitx5-rime.override {
          rimeDataPkgs = [ pkgs.rime-ice ];
        })
        pkgs.fcitx5-mozc
        (pkgs.catppuccin-fcitx5.override { withRoundedCorners = true; })
      ];

      settings = {
        globalOptions."Hotkey/TriggerKeys"."0" = "Super+space";

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
