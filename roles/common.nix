{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
in
{
  imports =  [
    ../programs/shell-bash.nix
    ../programs/vim.nix
  ];

  time.timeZone = "Australia/Brisbane";

  environment.systemPackages = with pkgs; [
    usbutils pciutils nfs-utils psmisc file gptfdisk
    git
    curl wget unzip dnsutils
    htop
    vim
  ];

  environment.variables = {
    EDITOR = "${pkgs.vim}/bin/vim";
  };

  nix.gc.automatic = true;

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
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDcd0nHFxIedlZwuUaWMAO9WEdZNNu/mJwjNR+VAnCkf"
      ];
    };

    users.gsalisbury = {
      hashedPassword = secrets.gsalisbury.hashedPassword;
      isNormalUser = true;
      uid = 1000;
      extraGroups = [ "wheel" "disk" "cdrom" "docker" "audio" "video" "systemd-journal" "dialout" "libvirtd"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDcd0nHFxIedlZwuUaWMAO9WEdZNNu/mJwjNR+VAnCkf"
      ];
    };
  };
}
