{ pkgs, ... }:

{
  virtualisation.docker.enable = true;

  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      # This machine only needs native x86_64 virtualization; qemu_kvm avoids
      # pulling in emulators for unrelated CPU architectures.
      package = pkgs.qemu_kvm;

      # Required for guests such as Windows 11 that expect a TPM 2.0 device.
      swtpm.enable = true;

      # Makes high-performance host/guest directory sharing available.
      vhostUserPackages = [ pkgs.virtiofsd ];
    };
  };

  programs.virt-manager.enable = true;

  # Permit attaching local USB devices to guests through the SPICE console.
  virtualisation.spiceUSBRedirection.enable = true;
}
