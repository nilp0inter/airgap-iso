{
  description = "Nixos configuration for my airgap computer";
  inputs.kbd-intl-ng-repo = {
    url = "github:Duncaen/kbd-intl-ng";
    flake = false;
  };
  inputs.nixos.url = "github:nixos/nixpkgs/nixos-22.05";
  outputs = { self, nixos, kbd-intl-ng-repo }: let
    pkgs = nixos.legacyPackages.x86_64-linux;
    kbd-intl-ng = (pkgs.stdenv.mkDerivation rec {
        name = "kbd-intl-ng";
        src = kbd-intl-ng-repo;
        installPhase = ''
          mkdir -p $out/share/keymaps
          gzip -dc ${pkgs.kbd}/share/keymaps/i386/qwerty/us.map.gz > $out/share/keymaps/us-intl.map
          cat $src/us-intl.map >> $out/share/keymaps/us-intl.map
          gzip $out/share/keymaps/us-intl.map
        '';
      });
    airgap-menu = pkgs.writeScriptBin "airgap" ''
      ${pkgs.just}/bin/just --justfile ${./airgap-menu.just} "$@"
    '';
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
             isoImage.makeEfiBootable = false;

             # USB booting
             isoImage.makeUsbBootable = true;

             time.timeZone = "Europe/Madrid";
             time.hardwareClockInLocalTime = true;

             console.font = "eurlatgr";
             console.keyMap = "${kbd-intl-ng}/share/keymaps/us-intl.map.gz";

             # Needed by yubikey tools
             services.pcscd.enable = true;

             # Enable mouse
             services.gpm.enable = true;

             # Allow automatic `root` login
             users.users.root.hashedPassword = "";
             services.getty.autologinUser = "root";
             networking.hostName = "airgap";

             environment.systemPackages = with pkgs; [
               kbd-intl-ng

               ninvaders

               cryptsetup

               paperkey

               yubico-piv-tool
               yubikey-manager
               yubikey-personalization

               airgap-menu

               rsync
               vim
             ];

             programs.git = {
               enable = true;
               config = {
                 user.email = "airgap@system";
                 user.name = "Airgap System";
               };
             };

             environment.etc.profile.text = ''
               export EDITOR=${pkgs.vim}/bin/vim
               # Interpret the RTC clock (just set by the user in the BIOS) in the
               # current time zone
               hwclock --hctosys --localtime
               hwclock --systohc --localtime

               clear
               echo "Check the date and time, and press Enter"
               date
               read
               echo "Play a game to feed the entropy pool"
               read
               ${pkgs.ninvaders}/bin/ninvaders
               clear
               echo "You can run 'airgap' to see a list of options"

             '';

             programs.gnupg.agent = {
               enable = true;
               pinentryFlavor = "tty";
             };
           }
        ];
      };
    };

    packages.x86_64-linux.default = self.nixosConfigurations.airgap.config.system.build.isoImage;

    apps.x86_64-linux.default = let
      launch-iso = pkgs.writeScriptBin "launch-iso" ''
        ${pkgs.qemu}/bin/qemu-system-x86_64 -enable-kvm -m 2048 -cdrom ${self.nixosConfigurations.airgap.config.system.build.isoImage}/iso/airgap.iso
        # sudo ${pkgs.qemu}/bin/qemu-system-x86_64 -enable-kvm -m 2048 -cdrom ${self.nixosConfigurations.airgap.config.system.build.isoImage}/iso/airgap.iso -hda /dev/sda  # Enable thumbdrive
      '';
    in {
      type = "app";
      program = "${launch-iso}/bin/launch-iso";
    };
  };
}
