{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
in
{
  services.grafana = {
    enable = true;
    auth.anonymous.enable = true;
    domain = "grafana.gsals.com";
  };
}
