{ pkgs, ... }:

{
  users.users.bandifee = {
    isNormalUser = true;

    # Fish is the interactive login shell; Bash remains installed for scripts.
    shell = pkgs.fish;

    extraGroups = [
      "wheel"
      "networkmanager"
      "clash-verge"
      "docker"
      "libvirtd"
    ];
  };

  # Register Fish as a system shell and provide its system-wide completions.
  programs.fish.enable = true;
}
