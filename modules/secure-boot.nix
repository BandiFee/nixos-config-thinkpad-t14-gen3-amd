{ lib, pkgs, ... }:

{
  # Lanzaboote replaces the unsigned systemd-boot installation while still
  # using systemd-boot as the boot manager.
  boot.loader.systemd-boot = {
    enable = lib.mkForce false;
    configurationLimit = 10;
    # Let systemd-boot choose a readable firmware console mode while making
    # better use of the display width for long generation labels.
    consoleMode = "auto";
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
