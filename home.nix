{ inputs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  home = {
    username = "bandifee";
    homeDirectory = "/home/bandifee";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      add_newline = false;
      command_timeout = 1000;

      character = {
        success_symbol = "[❯](bold #a6e3a1)";
        error_symbol = "[❯](bold #f38ba8)";
        vimcmd_symbol = "[❮](bold #a6e3a1)";
      };

      directory.style = "bold #89b4fa";

      git_branch = {
        symbol = " ";
        style = "bold #cba6f7";
      };

      nix_shell = {
        symbol = " ";
        style = "bold #89dceb";
      };
    };
  };

  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };

    shellIntegration.enableFishIntegration = true;

    settings = {
      # A dark glass-like surface: black tint with the wallpaper showing through.
      background_opacity = 0.70;
      background_blur = 0;
      window_padding_width = 10;
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      enabled_layouts = "splits:split_axis=auto;equalize_on_close=true,stack";

      background = "#000000";
      foreground = "#cdd6f4";
      cursor = "#f5e0dc";
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
    systemd.enable = false;
    settings = ./config/noctalia/config.toml;
  };

  xdg = {
    enable = true;

    mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/terminal" =
        [ "kitty.desktop" ];
    };

    configFile."niri/config.kdl".source = ./config/niri/config.kdl;
  };
}
