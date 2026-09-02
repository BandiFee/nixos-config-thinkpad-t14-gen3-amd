{ customPkgs, pkgs, ... }:

let
  # Rime compares source mtimes before rebuilding schemas. Files symlinked
  # directly from the Nix store have an epoch mtime, so keep this particular
  # override mutable and compile it before Fcitx starts whenever it changes.
  rime-ice-custom = ../config/rime/rime_ice.custom.yaml;

  deploy-rime-ice = pkgs.writeShellScript "deploy-rime-ice" ''
    set -eu

    rime_dir=/home/bandifee/.local/share/fcitx5/rime
    custom_file="$rime_dir/rime_ice.custom.yaml"

    if ! ${pkgs.diffutils}/bin/cmp -s ${rime-ice-custom} "$custom_file" \
      || [ ! -e "$rime_dir/build/rime_ice.schema.yaml" ]; then
      ${pkgs.coreutils}/bin/mkdir -p "$rime_dir"
      ${pkgs.coreutils}/bin/cp --remove-destination \
        ${rime-ice-custom} "$custom_file"
      ${customPkgs.librime-with-caps-lock-resync}/bin/rime_deployer --compile \
        ${customPkgs.fcitx5-rime-with-ice}/share/rime-data/rime_ice.schema.yaml \
        "$rime_dir" \
        ${customPkgs.fcitx5-rime-with-ice}/share/rime-data \
        "$rime_dir/build"
    fi
  '';
in
{
  # Rime-based Chinese input. Home Manager starts Fcitx5 after the Niri
  # graphical session is ready, keeping its environment correct for Wayland.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      waylandFrontend = true;

      addons = [
        customPkgs.fcitx5-rime-with-ice
        pkgs.fcitx5-mozc
        (pkgs.catppuccin-fcitx5.override { withRoundedCorners = true; })
      ];

      settings = {
        globalOptions."Hotkey/TriggerKeys"."0" = "Super+space";
        # Let Rime handle a bare left Shift so commit_code can preserve the
        # raw composition instead of Fcitx temporarily deactivating Rime.
        globalOptions."Hotkey/AltTriggerKeys" = { };

        # Noctalia rewrites this theme from the current wallpaper palette.
        addons.classicui.globalSection.Theme = "noctalia-glass";

        inputMethod = {
          GroupOrder."0" = "Default";
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "rime";
          };
          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1" = {
            Layout = "us";
            Name = "rime";
          };
          "Groups/0/Items/2" = {
            Layout = "us";
            Name = "mozc";
          };
        };
      };
    };
  };

  systemd.user.services.fcitx5-daemon.Service.ExecStartPre = deploy-rime-ice;

  # Use Rime Ice's maintained Simplified Chinese dictionaries and schemas.
  xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      __include: rime_ice_suggestion:/
  '';

  xdg.configFile = {
    "noctalia/templates/fcitx5/theme.conf".source = ../config/noctalia/templates/fcitx5/theme.conf;
    "noctalia/templates/fcitx5/panel.svg".source = ../config/noctalia/templates/fcitx5/panel.svg;
    "noctalia/templates/fcitx5/highlight.svg".source =
      ../config/noctalia/templates/fcitx5/highlight.svg;

    # Home Manager already owns Fcitx5's graphical-session service. Disable
    # the package's XDG autostart entry so the two instances do not race.
    "autostart/org.fcitx.Fcitx5.desktop".text = ''
      [Desktop Entry]
      Hidden=true
    '';
  };
}
