{ config, lib, pkgs, ... }:

{
  imports = [
    ../roles/common.nix
    ../roles/workstation.nix
    ../roles/entertainment.nix
  ];

  system.stateVersion = "18.09";

  networking = {
    hostName = "x1cbn";
    hostId = "2f044167";
    wireless.enable = true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_4_18;
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    initrd.availableKernelModules = [ "xhci_pci" "nvme" "ehci_pci" "ahci" "usbstorage" "usbhid" "sd_mod" "rtsx_pci_sdmmc" "zfs" ];
    kernelModules = [ "kvm-intel" "tun" "virtio" ];
    supportedFilesystems = [ "zfs" ];
    zfs.enableUnstable = true;
    zfs.requestEncryptionCredentials = true;
  };

  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      frequent = 8;
      monthly = 1;
    };
  };

  services.tlp.enable = true;
  services.acpid.enable = true;
  services.fwupd.enable = true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/a98f7315-60a6-457e-a3d5-d223a5cd123c";
      fsType = "btrfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/EA94-6CA5";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-label/swap"; } ];

  nix.maxJobs = 2;
}
