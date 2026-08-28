{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
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
      tuigreet = prev.tuigreet.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ./patches/tuigreet-center-time.patch
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

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    TERMINAL = "kitty";
  };

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

  # Polkit GUI authentication agent
  systemd.user.services.polkit-gnome-authentication-agent = {
    description = "Polkit authentication agent";

    wantedBy = [
      "graphical-session.target"
    ];

    partOf = [
      "graphical-session.target"
    ];

    after = [
      "graphical-session.target"
    ];

    serviceConfig = {
      Type = "simple";

      ExecStart =
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";

      Restart = "on-failure";
    };
  };

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

    # Desktop
    nautilus
    file-roller
    pavucontrol

    brightnessctl
    playerctl
    wl-clipboard

    # Browser
    firefox

    # CLI
    git
    vim
    wget
    curl
    fastfetch
    btop
    codex

    pciutils
    usbutils

    # GPU diagnostics
    vulkan-tools
    mesa-demos
    libva-utils

    # Fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
  ];

  # ============================================================
  # Fonts
  # ============================================================

  fonts.fontconfig.enable = true;

  # ============================================================
  # Compatibility
  # ============================================================

  system.stateVersion = "26.05";
}
