{ lib, pkgs, ... }:

let
  shutdownTargets = [
    "halt.target"
    "kexec.target"
    "poweroff.target"
    "reboot.target"
  ];

  finalShutdownServices = [
    "systemd-halt.service"
    "systemd-kexec.service"
    "systemd-poweroff.service"
    "systemd-reboot.service"
  ];

  shutdownPlymouthServices = [
    "plymouth-halt.service"
    "plymouth-kexec.service"
    "plymouth-poweroff.service"
    "plymouth-reboot.service"
  ];

  noctaliaBootTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "noctalia-boot-plymouth-theme";
    version = "1.0.0";

    src = ../config/plymouth/noctalia-boot;

    nativeBuildInputs = [
      pkgs.imagemagick
      pkgs.librsvg
    ];

    installPhase = ''
      runHook preInstall

      themeDir="$out/share/plymouth/themes/noctalia-boot"
      mkdir -p "$themeDir"

      install -m444 noctalia-boot.script "$themeDir/noctalia-boot.script"
      install -m444 noctalia-boot.plymouth "$themeDir/noctalia-boot.plymouth"

      base64 --decode center-logo.png.base64 > center-logo.png

      rsvg-convert --width 1920 --height 1200 \
        background.svg > "$themeDir/background.png"
      # Keep the replacement horizontal logo at the original 360x101 canvas.
      install -m444 brand-logo.png "$themeDir/brand-logo.png"
      rsvg-convert --width 760 --height 180 \
        dialog-panel.svg > "$themeDir/dialog-panel.png"

      for index in $(seq 0 71); do
        angle=$((index * 5))
        magick center-logo.png \
          -filter Lanczos \
          -resize 192x192 \
          -background none \
          -gravity center \
          -extent 240x240 \
          -virtual-pixel transparent \
          -distort SRT "$angle" \
          "$themeDir/spinner-$index.png"
      done

      runHook postInstall
    '';
  };
in
{
  boot.plymouth = {
    enable = true;
    theme = "noctalia-boot";
    themePackages = [ noctaliaBootTheme ];
    font = "${pkgs.inter}/share/fonts/truetype/InterVariable.ttf";
  };

  # Plymouth owns the display between the firmware and tuigreet. Keep normal
  # boot messages available behind Esc without flashing them during startup.
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 0;
  boot.kernelParams = [
    "quiet"
    # Unlike quiet's automatic mode, never reveal unit status messages when a
    # service is slow or fails while Plymouth owns the display.
    "systemd.show_status=false"
    "rd.systemd.show_status=false"
    "udev.log_level=3"
    "logo.nologo"
    "vt.global_cursor_default=0"
    # Without this, fbcon can bind after greetd has already drawn tuigreet and
    # reinterpret part of its backing buffer as a grid of corrupted glyphs.
    "fbcon=nodefer"
    # Match the 16x32 Terminus console font used by tuigreet from first bind.
    "fbcon=font:TER16x32"
  ];

  systemd.services =
    # greetd stops before Plymouth because the vendor units are ordered after
    # display-manager.service.  The actual Niri session lives in user@1000,
    # however, so include it explicitly to avoid both processes racing for DRM.
    lib.genAttrs
      [
        "plymouth-halt"
        "plymouth-kexec"
        "plymouth-poweroff"
        "plymouth-reboot"
      ]
      (_: {
        # These units come from the Plymouth package, so extend them with a
        # drop-in instead of competing with the vendor unit file.
        overrideStrategy = "asDropin";
        after = [ "user@1000.service" ];
      })
    // {
      # Plymouth upstream installs this hand-off alongside every shutdown
      # target.  NixOS currently ships the unit but does not enable its stage-2
      # target links, so add them and wait until the shutdown ramfs exists.
      plymouth-switch-root-initramfs = {
        overrideStrategy = "asDropin";
        wantedBy = shutdownTargets;
        after = [
          "generate-shutdown-ramfs.service"
          "plymouth-shutdown-polish.service"
        ];
        before = finalShutdownServices;
      };

      # Once Plymouth has acquired DRM, silence only the final manager output.
      # The manager returns to its normal log target on the next boot.
      plymouth-shutdown-polish = {
        description = "Polish Plymouth shutdown transition";
        wantedBy = shutdownTargets;
        after = shutdownPlymouthServices ++ [ "user@1000.service" ];
        before = [ "plymouth-switch-root-initramfs.service" ] ++ finalShutdownServices;

        unitConfig.DefaultDependencies = false;
        serviceConfig.Type = "oneshot";

        script = ''
          ${pkgs.plymouth}/bin/plymouth show-splash || true
          ${pkgs.systemd}/bin/systemctl log-target null || true
        '';
      };
    };
}
