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

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # This branch always points at an upstream revision with cached binaries.
    # Keep its nixpkgs independent or the Noctalia cache will not match.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixos-hardware,
      home-manager,
      ...
    }:
    {
      # Lanzaboote-based Secure Boot and its signing tooling.
      nixosModules.secure-boot = {
        imports = [
          inputs.lanzaboote.nixosModules.lanzaboote
          ./modules/secure-boot.nix
        ];
      };

      # TPM2-backed automatic unlocking for the cryptroot LUKS mapping.
      nixosModules.tpm-unlock = {
        imports = [ ./modules/tpm-unlock.nix ];
      };

      nixosConfigurations.thinkpad-t14 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./configuration.nix
          nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen3
          self.nixosModules.secure-boot
          self.nixosModules.tpm-unlock
          home-manager.nixosModules.home-manager

          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              extraSpecialArgs = { inherit inputs; };
              users.bandifee = import ./home;
            };
          }
        ];
      };
    };
}
