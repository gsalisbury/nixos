{ config, libs, pkgs, ... }:

{

  # font configuration
  # ------------------
  fonts = {

    enableCoreFonts        = true;
    enableFontDir          = true;
    enableGhostscriptFonts = true;

    fontconfig = {
      dpi = 141;
      subpixel = {
        lcdfilter = "default";
        rgba      = "rgb";
      };
      hinting = {
        enable   = true;
        autohint = false;
      };
      enable       = true;
      antialias    = true;
      defaultFonts = {
        monospace  = [ "inconsolata" ];
      };
    };

    fonts = with pkgs; [
      corefonts
      hasklig
      inconsolata
      source-code-pro
      symbola
      ubuntu_font_family
      google-fonts

      # symbol fonts
      # ------------
      nerdfonts
      powerline-fonts
      font-awesome-ttf
      fira-code-symbols

      # shell font
      # ----------
      terminus_font
      gohufont
    ];
  };

}
