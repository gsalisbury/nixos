{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
in
{
  services.kubernetes = {
    kubelet = {
      enable = true;
      address = "192.168.0.254";
      clusterDns = "10.0.0.53";
      extraOpts = "--fail-swap-on=false";
    };

    proxy = {
      enable = true;
      address = "192.168.0.253";
    };
  };

}
