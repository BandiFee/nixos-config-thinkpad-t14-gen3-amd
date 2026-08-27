{
  # systemd in the initrd discovers the enrolled TPM2 token and falls back to
  # the existing LUKS passphrase when automatic unlocking is unavailable.
  boot.initrd.systemd = {
    enable = true;
    tpm2.enable = true;
  };

  boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [
    "tpm2-device=auto"
  ];
}
