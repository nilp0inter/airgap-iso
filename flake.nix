{
  description = "Nixos configuration for my airgap computer";
  inputs.kbd-intl-ng-repo = {
    url = "github:Duncaen/kbd-intl-ng";
    flake = false;
  };
  inputs.nixos.url = "github:nixos/nixpkgs/nixos-24.11";
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
    airgap-menu = pkgs.callPackage ./airgap {};
  in {
    devShell.x86_64-linux = pkgs.mkShell {
      buildInputs = [
      ];
      inputsFrom = [
        airgap-menu
      ];
    };
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

             # Enable Infinite Noise TRNG
             services.infnoise.enable = true;
             services.infnoise.fillDevRandom = true;

             # Allow automatic `root` login
             users.users.root.hashedPassword = "";
             services.getty.autologinUser = "root";
             networking.hostName = "airgap";

             environment.systemPackages = with pkgs; [
               kbd-intl-ng

               ninvaders
               infnoise

               cryptsetup
               utillinux
               ssss

               enscript
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
                 init.defaultBranch = "main";
                 user.email = "airgap@system";
                 user.name = "Airgap System";
               };
             };

             environment.etc.profile.text = ''
               mkdir /mnt
               ${airgap-menu}/bin/airgap gpg.init
               source <(${airgap-menu}/bin/airgap --print-completion-script=bash)
               export EDITOR=${pkgs.vim}/bin/vim

               # Interpret the RTC clock (just set by the user in the BIOS) in the
               # current time zone
               hwclock --hctosys --localtime
               hwclock --systohc --localtime

               clear
               echo "Check the date and time, and press Enter"
               date
               read
               # ${pkgs.ninvaders}/bin/ninvaders
               clear
               echo "You can run 'airgap' to see a list of options"

             '';

             programs.gnupg.agent = {
               enable = true;
               pinentryPackage = pkgs.pinentry-tty;
             };

             hardware.gpgSmartcards.enable = true;

             # HP LaserJet 1100
             services.printing = {
               enable = true;
               drivers = with pkgs; [
                 gutenprint
               ];
             };
             hardware.printers.ensureDefaultPrinter = "hpLaserJet1100";
             hardware.printers.ensurePrinters = [
               {
                 name = "hpLaserJet1100";
                 model = "gutenprint.5.3://hp-lj_1100/expert";
                 description = "HP LaserJet 1100";
                 deviceUri = "usb://HP/LaserJet%201100";
                 ppdOptions = {
                   PageSize = "A4";
                   Resolution = "600dpi";
                 };
               }
             ];

             system.stateVersion = "22.05";
           }
        ];
      };
    };

    packages.x86_64-linux.default = self.nixosConfigurations.airgap.config.system.build.isoImage;

    apps.x86_64-linux.default = let
      launch-iso = pkgs.writeScriptBin "launch-iso" ''
        [ ! -f /tmp/airgap.drive ] && dd if=/dev/zero of=/tmp/airgap.drive bs=1M count=64
        ${pkgs.qemu}/bin/qemu-system-x86_64 -device qemu-xhci,id=xhci -device usb-host,bus=xhci.0,vendorid=0x0403,productid=0x6015 -enable-kvm -m 2048 -cdrom ${self.nixosConfigurations.airgap.config.system.build.isoImage}/iso/airgap.iso -hda /tmp/airgap.drive
      '';
    in {
      type = "app";
      program = "${launch-iso}/bin/launch-iso";
    };
  };
}
