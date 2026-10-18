{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Pre-built Noctalia v5 binaries (the flake tracks its cached branch).
  nix.settings.extra-substituters = [ "https://noctalia.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
  ];

  # clean unused generation / store paths
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nixpkgs.config = {
    allowUnfree = true;
    # SPlayer 3.1.1 is the upstream's final release and still bundles Electron 41.
    permittedInsecurePackages = [ "electron-41.10.7" ];
  };

  nixpkgs.overlays = [ (import ../overlays) ];
}
