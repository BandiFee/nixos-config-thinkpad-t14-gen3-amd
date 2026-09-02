{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Build tools
    gnumake

    # Hardware and graphics diagnostics available system-wide
    pciutils
    usbutils
    vulkan-tools
    mesa-demos
    libva-utils
    smartmontools
    nvme-cli

    # Disk partitioning and common filesystem administration
    gparted
    gnome-disk-utility
    parted
    gptfdisk
    btrfs-progs
    e2fsprogs
    xfsprogs
    f2fs-tools
    dosfstools
    exfatprogs
    ntfs3g
  ];
}
