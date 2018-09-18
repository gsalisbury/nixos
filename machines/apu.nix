{ config, lib, pkgs, ... }:

{
  imports = [
    ../roles/common.nix
    ../roles/router.nix
  ];

  networking = {
    hostName = "apu";
    hostId = "";
  };

  boot = {
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
      extraConfig = "serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1; terminal_input serial; terminal_output serial";
    };

    kernelParams = [ "console=tty0" "console=ttyS0,115200n8" ];
    initrd.availableKernelModules = [ "ahci" "ohci_pci" "ehci_pci" "usb_storage" ];
    kernelModules = [ "kvm-amd" "tun" "virtio" ];
  };

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  system.stateVersion = "18.03";
  system.autoUpgrade.enable = true;

  services.haveged.enable = true;
}
