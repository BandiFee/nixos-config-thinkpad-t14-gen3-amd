{
  customPkgs,
  lib,
  pkgs,
  ...
}:

{
  programs.firefox.enable = true;

  home.packages = [ customPkgs.librepods-noctalia ];
  systemd.user.services.librepods = {
    Unit = {
      Description = "AirPods integration for Noctalia";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${customPkgs.librepods-noctalia}/bin/librepods --headless";
      Environment = [ "QT_LOGGING_RULES=openpods.debug=false" ];
      Restart = "on-failure";
      RestartSec = 5;
      UMask = "0077";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Niri starts Noctalia with the graphical session. The upstream module
  # installs the cached package and validates this TOML during the build.
  programs.noctalia = {
    enable = true;
    package = customPkgs.noctalia-with-mpris-lyrics;
    systemd.enable = false;
    settings = pkgs.replaceVars ../config/noctalia/config.toml {
      librepods_ctl = "${customPkgs.librepods-noctalia}/bin/librepods-ctl";
    };
  };

  # Noctalia stores Settings UI edits separately from the declarative config.
  # Remove only the old lockscreen widget override once so this new Nix-owned
  # layout can take effect; preserve all wallpaper, theme and other user state.
  home.activation.noctalia-lockscreen-layout-v1 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    state_dir="$HOME/.local/state/noctalia"
    settings_file="$state_dir/settings.toml"
    migration_marker="$state_dir/.nix-lockscreen-layout-v1"

    if [ -f "$settings_file" ] && [ ! -e "$migration_marker" ]; then
      run ${pkgs.coreutils}/bin/cp --preserve=mode,timestamps \
        "$settings_file" "$settings_file.before-lockscreen-layout-v1"
      run ${pkgs.gawk}/bin/awk '
        /^\[lockscreen_widgets\]$/ { skipping = 1; next }
        skipping && /^\[[^.]+\]$/ { skipping = 0 }
        !skipping { print }
      ' "$settings_file" > "$settings_file.nix-lockscreen-layout-v1"
      run ${pkgs.coreutils}/bin/mv \
        "$settings_file.nix-lockscreen-layout-v1" "$settings_file"
      run ${pkgs.coreutils}/bin/touch "$migration_marker"
    fi
  '';

  # The authorization agent belongs to the graphical user session while the
  # Polkit daemon itself remains enabled system-wide in modules/desktop.nix.
  systemd.user.services.polkit-gnome-authentication-agent = {
    Unit = {
      Description = "Polkit authentication agent";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.configFile."niri/config.kdl".source = ../config/niri/config.kdl;
}
