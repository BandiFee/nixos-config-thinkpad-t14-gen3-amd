{ pkgs, ... }:

{
  programs.niri.enable = true;

  # Niri discovers this package and starts XWayland on demand.
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  security.polkit.enable = true;

  programs.dconf.enable = true;

  # gvfs also enables udisks2
  services.gvfs.enable = true;

  # ============================================================
  # Steam / Gaming
  # ============================================================

  programs.steam.enable = true;

  programs.gamemode.enable = true;
}
