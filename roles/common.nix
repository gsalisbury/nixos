{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
in
{
  time.timeZone = "Australia/Brisbane";

  environment.systemPackages = with pkgs; [
    usbutils pciutils nfs-utils psmisc file gptfdisk
    git gitAndTools.git-crypt gitAndTools.hub
    python ruby bundler nodejs gcc gnumake
    curl wget bind dhcp unzip
    htop tmux picocom stow duplicity
    vim
  ];

  environment.variables = {
    EDITOR = "${pkgs.vim}/bin/vim";
  };

  nix.gc.automatic = true;
  nix.useChroot = true;

  hardware.enableAllFirmware = true;

  boot.cleanTmpDir = true;

  boot.kernel.sysctl = {
    "vm.swappiness" = 20;
  };

  security = {
    sudo.enable = true;
    sudo.wheelNeedsPassword = false;
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  services.ntp.enable = true;

  users = {
    mutableUsers = false;

    users.root = {
      hashedPassword = secrets.root.hashedPassword;
      shell = "${pkgs.bash}/bin/bash";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDcd0nHFxIedlZwuUaWMAO9WEdZNNu/mJwjNR+VAnCkf"
      ];
    };

    users.gsalisbury = {
      hashedPassword = secrets.gsalisbury.hashedPassword;
      isNormalUser = true;
      shell = "${pkgs.bash}/bin/bash";
      uid = 1000;
      extraGroups = [ "wheel" "disk" "cdrom" "docker" "audio" "video" "systemd-journal" "dialout" "libvirtd"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDcd0nHFxIedlZwuUaWMAO9WEdZNNu/mJwjNR+VAnCkf"
      ];
    };
  };
}
