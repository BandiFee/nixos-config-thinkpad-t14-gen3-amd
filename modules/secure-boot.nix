{ lib, pkgs, ... }:

{
  # Lanzaboote replaces the unsigned systemd-boot installation while still
  # using systemd-boot as the boot manager.
  boot.loader.systemd-boot = {
    enable = lib.mkForce false;
    configurationLimit = 10;
  };

  boot.loader.efi.canTouchEfiVariables = true;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  environment.systemPackages = [ pkgs.sbctl ];
}
