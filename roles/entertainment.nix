{ config, pkgs, ... }:
let
  secrets = import ../secrets.nix;
in
{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    steam
  ];

  hardware = {
    opengl.driSupport = true;
    opengl.driSupport32Bit = true;
    pulseaudio.support32Bit = true;
  };
}
