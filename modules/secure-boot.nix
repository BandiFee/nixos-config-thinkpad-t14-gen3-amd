{ lib, pkgs, ... }:

{
  # Lanzaboote replaces the unsigned systemd-boot installation while still
  # using systemd-boot as the boot manager.
  boot.loader.systemd-boot = {
    enable = lib.mkForce false;
    configurationLimit = 10;
    # 80x50 is closer to the 32px Linux console font than the oversized 80x25
    # mode, while remaining a firmware-provided text mode.
    consoleMode = "1";
  };

  # Boot the newest generation immediately; hold Space to show the menu.
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  environment.systemPackages = [ pkgs.sbctl ];
}
