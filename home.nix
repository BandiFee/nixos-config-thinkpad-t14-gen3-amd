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

  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 12;
      theme = "catppuccin-mocha";

      # Fully transparent, including cells painted by terminal applications.
      background-opacity = 0.0;
      background-opacity-cells = true;
      background-blur = false;
      window-padding-x = 12;
      window-padding-y = 10;
      window-padding-balance = true;
      window-padding-color = "extend";

      cursor-style = "block";
      cursor-style-blink = false;
      shell-integration = "fish";
      confirm-close-surface = false;
    };

    themes.catppuccin-mocha = {
      background = "1e1e2e";
      foreground = "cdd6f4";
      cursor-color = "f5e0dc";
      selection-background = "45475a";
      selection-foreground = "cdd6f4";
      palette = [
        "0=#45475a"
        "1=#f38ba8"
        "2=#a6e3a1"
        "3=#f9e2af"
        "4=#89b4fa"
        "5=#f5c2e7"
        "6=#94e2d5"
        "7=#bac2de"
        "8=#585b70"
        "9=#f38ba8"
        "10=#a6e3a1"
        "11=#f9e2af"
        "12=#89b4fa"
        "13=#f5c2e7"
        "14=#94e2d5"
        "15=#a6adc8"
      ];
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
        [ "com.mitchellh.ghostty.desktop" ];
    };

    configFile."niri/config.kdl".source = ./config/niri/config.kdl;
  };
}
