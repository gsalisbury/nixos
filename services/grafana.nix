{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
in
{
  environment.systemPackages = with pkgs; [
    grafana
  ];

  services.grafana = {
    enable = true;
    auth.anonymous.enable = true;
    domain = "grafana.home"
  };
}
