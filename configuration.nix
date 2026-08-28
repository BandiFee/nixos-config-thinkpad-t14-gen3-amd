{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/plymouth.nix
  ];

  # ============================================================
  # Nix
  # ============================================================

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

  nixpkgs.config.allowUnfree = true;

  # Keep the clock next to the centered login form instead of at the TTY edge.
  nixpkgs.overlays = [
    (_final: prev: {
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

      tuigreet = prev.tuigreet.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ./patches/tuigreet-center-time.patch
          # While authenticating, the (now-empty) secret value is drawn over the
          # "Please wait..." answer row and recolors its tail ("t...") green.
          ./patches/tuigreet-fix-wait-color.patch
        ];
      });
    })
  ];

  # ============================================================
  # Network
  # ============================================================

  networking.hostName = "thinkpad-t14";

  networking.networkmanager.enable = true;

  # SSH Server
  services.openssh = {
    enable = true;
    openFirewall = true;

    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # ============================================================
  # Proxy
  # ============================================================

  users.groups."clash-verge" = { };

  programs.clash-verge = {
    enable = true;
    autoStart = false;
    serviceMode = true;
    tunMode = true;
    group = "clash-verge";
  };
  networking.firewall.checkReversePath = "loose";
  networking.firewall.trustedInterfaces = [ "Mihomo" ];

  # ============================================================
  # Time / Locale
  # ============================================================

  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    keyMap = "us";
    packages = [ pkgs.terminus_font ];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-v32n.psf.gz";
  };

  # ============================================================
  # User
  # ============================================================

  users.users.bandifee = {
    isNormalUser = true;

    # Fish is the interactive login shell; Bash remains installed for scripts.
    shell = pkgs.fish;

    extraGroups = [
      "wheel"
      "networkmanager"
      "clash-verge"
    ];
  };

  # ============================================================
  # ThinkPad / Power
  # ============================================================

  services.power-profiles-daemon.enable = true;

  services.fwupd.enable = true;

  zramSwap.enable = true;

  # ============================================================
  # Fingerprint reader
  # ============================================================

  # Also enables fingerprint authentication for PAM services such as
  # greetd, sudo and polkit while retaining password authentication.
  services.fprintd.enable = true;

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

  # ============================================================
  # Niri
  # ============================================================

  programs.niri.enable = true;

  # Register Fish as a system shell and provide its system-wide completions.
  programs.fish.enable = true;

  # ============================================================
  # Login
  # ============================================================

  environment.etc."tuigreet/config.toml".text = ''
    [display]
    show_time = true
    time_format = "[ %Y-%m-%d || %H:%M ]"
    greeting = """
    [+] Welcome back to NixOS on ThinkPad T14 [+]
    Authentication: fingerprint first, password fallback enabled
    """
    align_greeting = "center"

    [layout]
    width = 80
    window_padding = 1
    container_padding = 2
    prompt_padding = 1

    [layout.widgets]
    time_position = "center"
    status_position = "hidden"

    [remember]
    username = true
    session = false
    user_session = true

    [secret]
    mode = "characters"
    characters = "*"

    [theme]
    border = "green"
    text = "white"
    time = "green"
    container = "black"
    title = "green"
    greet = "green"
    prompt = "white"
    input = "green"
  '';

  services.greetd = {
    enable = true;

    # tuigreet is a TUI greeter
    useTextGreeter = true;

    settings.default_session = {
      command =
        "${pkgs.tuigreet}/bin/tuigreet --config /etc/tuigreet/config.toml --cmd ${config.programs.niri.package}/bin/niri-session";

      user = "greeter";
    };
  };

  # ============================================================
  # Desktop infrastructure
  # ============================================================

  security.polkit.enable = true;

  programs.dconf.enable = true;

  # gvfs also enables udisks2
  services.gvfs.enable = true;

  # ============================================================
  # Steam / Gaming
  # ============================================================

  programs.steam.enable = true;

  programs.gamemode.enable = true;

  # ============================================================
  # Applications
  # ============================================================

  environment.systemPackages = with pkgs; [
    # X11 compatibility
    xwayland-satellite

    # Hardware and graphics diagnostics available system-wide
    pciutils
    usbutils
    vulkan-tools
    mesa-demos
    libva-utils
  ];

  # ============================================================
  # Fonts
  # ============================================================

  fonts = {
    fontconfig = {
      enable = true;

      # Only use the Simplified Chinese (SC) variant of the Noto CJK fonts.
      # All five regional variants ship in the same package, and with a
      # non-CJK locale fontconfig picks the JP instance first, which draws
      # Chinese-only glyphs (e.g. 复) with narrow Japanese-style forms.
      # Reject the other variants so SC always wins.
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <selectfont>
            <rejectfont>
              <pattern><patelt name="family"><string>Noto Sans CJK JP</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Sans CJK KR</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Sans CJK TC</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Sans CJK HK</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Sans Mono CJK JP</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Sans Mono CJK KR</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Sans Mono CJK TC</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Sans Mono CJK HK</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Serif CJK JP</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Serif CJK KR</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Serif CJK TC</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Serif CJK HK</string></patelt></pattern>
            </rejectfont>
          </selectfont>
        </fontconfig>
      '';
    };

    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
    ];
  };

  # ============================================================
  # Compatibility
  # ============================================================

  system.stateVersion = "26.05";
}
