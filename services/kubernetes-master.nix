{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
in
{
  environment.systemPackages = with pkgs; [
    grafana
  ];

  services.kubernetes = {
    apiserver = {
      enable = true;
      bindAddress = "192.168.0.253";
      kubeletHttps = false;
      basicAuthFile = /etc/kubernetes/.basicAuthFile;
    };
    clusterCidr = "10.1.0.0/16";
    controllerManager = {
      enable = true;
    };
    dataDir = "/var/lib/kubernetes";
    scheduler = {
      enable = true;
    };
  };
}
