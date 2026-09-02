{ pkgs, ... }:

{
  # Resolve hard-coded /bin/* and /usr/bin/* paths from the caller's PATH.
  services.envfs.enable = true;

  # Run prebuilt, dynamically linked Linux binaries such as Conda Python.
  # SkiaSharp's bundled native library also needs fontconfig at runtime.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      fontconfig
      libx11
      libice
      libsm

      # libstdc++.so.6, needed by most prebuilt C++ binaries.
      stdenv.cc.cc.lib
    ];
  };
}
