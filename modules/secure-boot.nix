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

  # A systemd-based initrd is required for TPM2-backed LUKS unlocking.
  boot.initrd.systemd = {
    enable = true;
    tpm2.enable = true;
  };

  environment.systemPackages = [ pkgs.sbctl ];
}
