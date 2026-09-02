# Package customizations applied to the whole system, including Home Manager
# (the flake sets useGlobalPkgs, so this pkgs set is shared).
_final: prev: {
  # niri-session imports the complete login-shell environment, but its
  # argument-less systemctl call is deprecated. Keep the same semantics by
  # spelling out every variable name, as proposed upstream in niri#3572.
  # symlinkJoin keeps this a tiny wrapper build instead of rebuilding Niri.
  niri = prev.symlinkJoin {
    name = "${prev.niri.name}-session-env-fix";
    paths = [ prev.niri ];

    postBuild = ''
      rm "$out/bin/niri-session"
      cp ${prev.niri}/bin/niri-session "$out/bin/niri-session"
      substituteInPlace "$out/bin/niri-session" \
        --replace-fail \
          "systemctl --user import-environment" \
          "systemctl --user import-environment \$(printenv | cut -d'=' -f1 | tr '\n' ' ')"
    '';

    pname = prev.niri.pname;
    version = prev.niri.version;
    passthru = prev.niri.passthru;
    meta = prev.niri.meta;
  };

  # GParted's upstream launcher only preserves X11 access across pkexec.
  # Pass the current Wayland socket explicitly so GTK can avoid
  # xwayland-satellite's nested-popup limitations, with X11 as fallback.
  gparted = prev.gparted.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ../patches/gparted-native-wayland.patch
    ];
  });

  tuigreet = prev.tuigreet.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ../patches/tuigreet-center-time.patch
      # While authenticating, the (now-empty) secret value is drawn over the
      # "Please wait..." answer row and recolors its tail ("t...") green.
      ../patches/tuigreet-fix-wait-color.patch
    ];
  });
}
