{ config, lib, pkgs, ... }:

{
  imports = [
    ../roles/common.nix
    ../roles/router.nix
  ];

  networking = {
    hostName = "apu";
    hostId = "fb53bd29";
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

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/ba7bf7cf-7b9e-44f5-97ea-e86123becc4c";
      fsType = "ext4";
    };

  fileSystems."/data" =
    { device = "/dev/disk/by-uuid/dcc428dc-abbb-47b9-bc63-d8cd7a1a20d5";
      fsType = "xfs";
    };

  fileSystems."/var" =
    { device = "/dev/disk/by-uuid/2ff0f3e5-1236-4c3c-b7fa-4077a9343cba";
      fsType = "xfs";
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/68bdf8e9-87b0-4f56-bc09-dfb2a3fa14dd";
      fsType = "ext4";
    };

  fileSystems."/var/lib/docker" =
    { device = "/dev/disk/by-partlabel/containers";
      fsType = "xfs";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/b41264d7-2f43-4794-8b92-24df1f226f83"; }
    ];

  system.stateVersion = "18.09";
  system.autoUpgrade.enable = true;

  services.haveged.enable = true;

  nix.maxJobs = lib.mkDefault 2;
}
