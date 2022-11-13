{
  description = "Nixos configuration for my airgap computer";
  inputs.nixos.url = "github:nixos/nixpkgs/nixos-22.05";
  outputs = { self, nixos }: let
    pkgs = nixos.legacyPackages.x86_64-linux;
  in {
    nixosConfigurations = {
      airgap = nixos.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Modules for installed systems only.
          "${nixos}/nixos/modules/installer/cd-dvd/iso-image.nix"
           {
             isoImage.isoName = "airgap.iso";
             isoImage.appendToMenuLabel = " Airgap System";

             isoImage.squashfsCompression = "gzip -Xcompression-level 1";
             # EFI booting
             isoImage.makeEfiBootable = true;

             # USB booting
             isoImage.makeUsbBootable = true;

             # Allow automatic `root` login
             users.users.root.hashedPassword = "";
             services.getty.autologinUser = "root";
             networking.hostName = "airgap";

             environment.systemPackages = with pkgs; [
               ninvaders

               gnupg
               paperkey

               yubico-piv-tool
               yubikey-manager
               yubikey-personalization
             ];

             environment.etc.profile.text = ''
               # Play a little game to enrich the entropy pool
               ${pkgs.ninvaders}/bin/ninvaders
             '';
           }
        ];
      };
    };

    packages.x86_64-linux.default = self.nixosConfigurations.airgap.config.system.build.isoImage;

    apps.x86_64-linux.default = let
      launch-iso = pkgs.writeScriptBin "launch-iso" ''
        ${pkgs.qemu}/bin/qemu-system-x86_64 -enable-kvm -m 256 -cdrom ${self.nixosConfigurations.airgap.config.system.build.isoImage}/iso/airgap.iso
      '';
    in {
      type = "app";
      program = "${launch-iso}/bin/launch-iso";
    };
  };
}
