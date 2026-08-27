{
  description = "NixOS configuration for ThinkPad T14 Gen 3 AMD";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixos-hardware,
      ...
    }:
    {
      # Importing this profile is all a host needs to enable Lanzaboote-based
      # Secure Boot with TPM2 support.
      nixosModules.secure-boot = {
        imports = [
          inputs.lanzaboote.nixosModules.lanzaboote
          ./modules/secure-boot.nix
        ];
      };

      nixosConfigurations.thinkpad-t14 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./configuration.nix
          nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen3
          self.nixosModules.secure-boot
        ];
      };
    };
}
