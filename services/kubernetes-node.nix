{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
in
{
  environment.systemPackages = with pkgs; [
    grafana
  ];

  services.kubernetes = {
    kubelet = {
      enable = true;
      address = "192.168.0.253";
      clusterDns = "10.0.0.53";
    };
    proxy = {
      enable = true;
      address = "192.168.0.253";
    };
  };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    storageDriver = "overlay2";
  };
}
