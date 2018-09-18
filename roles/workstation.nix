{ config, pkgs, ... }:

{
  networking.firewall = {
    enable = true;
    checkReversePath = false; # https://github.com/NixOS/nixpkgs/issues/10101
  };

  environment.etc = {
    "hosts".text =
    ''
    127.0.0.1 kube-apiserver.service.prd.consul 
    127.0.0.1 kube-apiserver.service.tst.consul 
    '';
  };

  environment.systemPackages = with pkgs; [
    firefox
    rustc rustfmt cargo racerRust
    gnupg pass
    atom lighttable
    gimp inkscape
    pitivi
    gitg gitAndTools.gitAnnex heroku
    parted gnome3.gnome-disk-utility
    sshfsFuse stow
    gnome3.gnome-boxes
    tor torbrowser pybitmessage
  ];

  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
    autoPrune.enable = true;
  };
  
  virtualisation.libvirtd.enable = true;

  services.xserver = {
    enable = true;
    layout = "us";
    videoDrivers = [ "intel" ];
    libinput.enable = true;
    displayManager.slim = {
      enable      = true;
      autoLogin   = false;
      defaultUser = "gsalisbury";
    }; 
    windowManager = {
      default = "i3";
      i3 = {
        enable = true;
        package = pkgs.i3-gaps;
      };
    };
  };

  # Note redshift doesn't support wayland
  services.redshift = {
    enable = true;
    latitude = "-25.939";
    longitude = "152.585";
    temperature.day = 6500;
    temperature.night = 2700;
  };

  services.tarsnap = {
    #enable = true;

    archives.machine.directories = [
      "/etc/nixos"
    ];

    archives.gsalisbury.directories = [
      "/home/gsalisbury/.dotfiles"
      "/home/gsalisbury/.password-store"
      "/home/gsalisbury/.gnupg2"
      "/home/gsalisbury/.ssh"
    ];
  };

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  services.printing.enable = true;

  programs.bash.enableCompletion = true;
  programs.mtr.enable = true;
  programs.ssh.startAgent = true;
}
