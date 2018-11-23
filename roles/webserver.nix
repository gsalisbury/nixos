{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
  ports = {
    subsonic = 8001;
    grafana = 3000;
    gitlab = 8004;
  };
in
{
  environment.systemPackages = with pkgs; [
    simp_le
  ];

  services.nginx = {
    enable = true;
    httpConfig = ''
      server {
        listen 80;
        server_name _;
        location /.well-known/acme-challenge {
          root /var/www/challenges;
        }
        location / {
          return 301 https://$host$request_uri;
        }
      }

      server {
        listen 443 ssl;
        ssl_certificate /var/lib/acme/gsals.com/fullchain.pem;
        ssl_certificate_key /var/lib/acme/gsals.com/key.pem;
        root /var/www;
      }

      server {
        listen 443 ssl;
        server_name grafana.gsals.com;
        ssl_certificate /var/lib/acme/gsals.com/fullchain.pem;
        ssl_certificate_key /var/lib/acme/gsals.com/key.pem;

        location / {
          allow 192.168.0.0/24;
          deny all;

          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_pass http://127.0.0.1:${toString ports.grafana};
        }
      }

      server {
        listen 80;
        server_name grafana.home;

        location / {
          allow 192.168.0.0/24;
          deny all;

          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_pass http://127.0.0.1:${toString ports.grafana};
        }
      }

      #server {
      #  listen 443 ssl;
      #  server_name git.gsals.com;
      #  ssl_certificate /var/lib/acme/gsals.com/fullchain.pem;
      #  ssl_certificate_key /var/lib/acme/gsals.com/key.pem;

      #  location / {
      #    proxy_set_header Host $host;
      #    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      #    proxy_pass http://127.0.0.1:${toString ports.gitlab};
      #  }
      #}
    '';
  };

  security.acme.certs."gsals.com" = {
    webroot = "/var/www/challenges";
    email = "g@gsals.com";
    extraDomains = {
      "www.gsals.com" = null;
      "git.gsals.com" = null;
      "apu.gsals.com" = null;
      "grafana.gsals.com" = null;
    };
  };

  systemd.services.dyndns = {
    description = "Dynamic DNS";
    serviceConfig.Type = "oneshot";
    path = [ pkgs.curl pkgs.dnsutils ];

    script = ''
      DOMAIN=gsals.com
      NEWIP=`dig +short myip.opendns.com @resolver1.opendns.com`
      CURRENTIP=`dig +short $DOMAIN @8.8.8.8`

      if [ "$NEWIP" = "$CURRENTIP" ]
      then
        echo "IP address unchanged"
      else
        curl -4 --cacert /etc/ssl/certs/ca-certificates.crt \
          -X POST "https://${secrets.dns.dyndns.username}:${secrets.dns.dyndns.password}@${secrets.dns.dyndns.url}?hostname=$DOMAIN"
      fi
    '';

    # every 5 minutes
    startAt = "*:0/5";
  };

#  services.gitlab = {
#    enable = true;
#    port = ports.gitlab;
#    emailFrom = "gitlab@gsals.com";
#    host = "git.gsals.com";
#    databasePassword = secrets.gitlab.databasePassword;
#  };

#  services.subsonic = {
#    enable = true;
#    httpsPort = ports.subsonic;
#  };

}
