{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.noctalia.homeModules.default

    ./packages.nix
    ./shell.nix
    ./terminal.nix
    ./desktop.nix
    ./input-method.nix
    ./xdg.nix
  ];

  # Shared by the modules above; see home/custom-packages.nix.
  _module.args.customPkgs = import ./custom-packages.nix { inherit inputs pkgs; };

  home = {
    username = "bandifee";
    homeDirectory = "/home/bandifee";
    stateVersion = "26.05";

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
  };

  programs.home-manager.enable = true;
}
