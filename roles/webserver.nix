{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
  ports = {
    subsonic = 8001;
    gitlab = 8004;
  };
in
{
  virtualisation.libvirtd.enable = true;

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
        server_name music.gsals.com;
        ssl_certificate /var/lib/acme/gsals.com/fullchain.pem;
        ssl_certificate_key /var/lib/acme/gsals.com/key.pem;

        location / {
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_pass https://127.0.0.1:${toString ports.subsonic};
        }
      }

      server {
        listen 443 ssl;
        server_name git.gsals.com;
        ssl_certificate /var/lib/acme/gsals.com/fullchain.pem;
        ssl_certificate_key /var/lib/acme/gsals.com/key.pem;

        location / {
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_pass http://127.0.0.1:${toString ports.gitlab};
        }
      }
    '';
  };

  security.acme.certs."gsals.com" = {
    webroot = "/var/www/challenges";
    email = "g@gsals.com";
    extraDomains = {
      "www.gsals.com" = null;
      "music.gsals.com" = null;
      "git.gsals.com" = null;
      "apu.gsals.com" = null;
    };
  };

  systemd.services.dyndns = {
    description = "Dynamic DNS";
    serviceConfig.Type = "oneshot";
    path = [ pkgs.curl pkgs.bind ];

    # from http://torb.at/cloudflare-dynamic-dns
    script = ''
      DOMAIN=apu.sys.gsals.com
      NEWIP=`dig +short myip.opendns.com @resolver1.opendns.com`
      CURRENTIP=`dig +short $DOMAIN @resolver1.opendns.com`

      if [ "$NEWIP" = "$CURRENTIP" ]
      then
        echo "IP address unchanged"
      else
        curl --cacert /etc/ssl/certs/ca-certificates.crt \
          -X PUT "https://api.cloudflare.com/client/v4/zones/ca0fc28b0ea163a97ed05ad2bef5d99d/dns_records/234d4c0bdeac610bac6eb9bcc6617e9d" \
          -H "X-Auth-Email: ${secrets.cloudflare.login}" \
          -H "X-Auth-Key: ${secrets.cloudflare.apiKey}" \
          -H "Content-Type: application/json" \
          --data "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$NEWIP\"}"
      fi
    '';

    # every 5 minutes
    startAt = "*:0/5";
  };

  services.gitlab = {
    enable = true;
    port = ports.gitlab;
    emailFrom = "gitlab@gsals.com";
    host = "git.gsals.com";
    databasePassword = secrets.gitlab.databasePassword;
  };

  services.subsonic = {
    enable = true;
    httpsPort = ports.subsonic;
  };

}
