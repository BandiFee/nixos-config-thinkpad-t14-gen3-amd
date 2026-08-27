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

  # clean unused generation / store paths
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = true;

  # ============================================================
  # Network
  # ============================================================

  networking.hostName = "thinkpad-t14";

  networking.networkmanager.enable = true;

  programs.nm-applet.enable = true;

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

  console.keyMap = "us";

  # ============================================================
  # User
  # ============================================================

  users.users.bandifee = {
    isNormalUser = true;

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
  # Bluetooth
  # ============================================================

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;

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

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # ============================================================
  # Login
  # ============================================================

  services.greetd = {
    enable = true;

    # tuigreet is a TUI greeter
    useTextGreeter = true;

    settings.default_session = {
      command =
        "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${config.programs.niri.package}/bin/niri-session";

      user = "greeter";
    };
  };

  # ============================================================
  # Desktop infrastructure
  # ============================================================

  security.polkit.enable = true;

  security.pam.services.swaylock = { };

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

  # Notifications
  systemd.user.services.mako = {
    description = "Mako notification daemon";

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
      ExecStart = "${pkgs.mako}/bin/mako";
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
    # Niri essentials
    alacritty
    fuzzel
    waybar
    swaylock
    swayidle
    swaybg

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
