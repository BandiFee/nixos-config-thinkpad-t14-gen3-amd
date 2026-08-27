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

  # Niri starts Noctalia with the graphical session. The upstream module
  # installs the cached package and validates this TOML during the build.
  programs.noctalia = {
    enable = true;
    systemd.enable = false;
    settings = ./config/noctalia/config.toml;
  };

  xdg = {
    enable = true;
    configFile."niri/config.kdl".source = ./config/niri/config.kdl;
  };
}
