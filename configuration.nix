{
  imports = [
    ./hardware-configuration.nix

    ./modules/nix.nix
    ./modules/networking.nix
    ./modules/locale.nix
    ./modules/users.nix
    ./modules/hardware.nix
    ./modules/virtualisation.nix
    ./modules/desktop.nix
    ./modules/greetd.nix
    ./modules/plymouth.nix
    ./modules/packages.nix
    ./modules/compat.nix
  ];

  system.stateVersion = "26.05";
}
