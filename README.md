# airgap-iso
Nixos configuration for my airgap computer

## Build and test ISO in QEMU

```console
$ nix run .
```

## Build ISO

```console
$ nix build .
$ sudo cp ./result/iso/airgap.iso /dev/<usbdrive>
```

