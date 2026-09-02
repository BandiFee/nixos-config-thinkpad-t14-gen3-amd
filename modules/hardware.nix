{
  # ============================================================
  # ThinkPad / Power
  # ============================================================

  services.power-profiles-daemon.enable = true;

  services.fwupd.enable = true;

  zramSwap.enable = true;

  # Verify Btrfs checksums monthly and monitor drive health continuously.
  # autoScrub deduplicates the root, home and nix subvolumes because they
  # reside on the same encrypted Btrfs filesystem.
  services.btrfs.autoScrub.enable = true;
  services.smartd.enable = true;

  # ============================================================
  # Fingerprint reader
  # ============================================================

  # Also enables fingerprint authentication for PAM services such as sudo,
  # polkit and the lock screen while retaining password authentication.
  services.fprintd.enable = true;

  # The greeter is deliberately excluded. fprintd only reports whether the
  # finger matches, so a fingerprint login hands pam_gnome_keyring nothing to
  # decrypt the login keyring with, and it stays locked for the rest of the
  # session -- every libsecret consumer then prompts for the password on first
  # use. Collecting the password here unlocks the keyring as part of the login.
  security.pam.services.greetd.fprintAuth = false;

  # ============================================================
  # Bluetooth
  # ============================================================

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;

  # Battery state is consumed directly by Noctalia.
  services.upower.enable = true;

  # ============================================================
  # Audio
  # ============================================================

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;

    alsa = {
      enable = true;
      support32Bit = true;
    };

    pulse.enable = true;
  };
}
