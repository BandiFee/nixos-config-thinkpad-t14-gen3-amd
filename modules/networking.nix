{
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
}
