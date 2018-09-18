{ config, pkgs, ... }:
let
  secrets = import ../secrets.nix;
in
{
  containers.mailserver = {
    autoStart = true;
    config = { config, pkgs, ... }: {
      services.postfix = {
        enable = true;
        domain = "mail.gsals.com";
        # relayHost = "";
        # sslCACert
        # sslCert
        # sslKey
      };


      services.dovecot2 = {
        enable = true;
      };
    };
  };
}
