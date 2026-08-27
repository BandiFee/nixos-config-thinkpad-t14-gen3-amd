{
  description = "NixOS configuration for ThinkPad T14 Gen 3 AMD";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-hardware = {
    url = "github:NixOS/nixos-hardware";
    inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixos-hardware,
      ...
    }:
    {
      nixosConfigurations.thinkpad-t14 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./configuration.nix
          nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen3
        ];
      };
    };
}
