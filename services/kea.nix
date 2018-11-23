{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
in
{
  environment.systemPackages = with pkgs; [
    kea
  ];

  environment.etc = {
    "kea/kea-dhcp4.conf".text =
      ''
      {
        # DHCPv4 configuration starts here.
        "Dhcp4":
        {
          # Add names of interfaces to listen on.
          "interfaces-config": {
            "interfaces": [ "enp2s0" ]
          },

          # Use Memfile lease database backend to store leases in a CSV file.
          "lease-database": {
            "type": "memfile",
            "persist": true,
            "name": "/var/lib/kea/dhcp4.leases",
            "lfc-interval": 1800
          },

          "expired-leases-processing": {
            "reclaim-timer-wait-time": 10,
            "flush-reclaimed-timer-wait-time": 25,
            "hold-reclaimed-time": 3600,
            "max-reclaim-leases": 100,
            "max-reclaim-time": 250,
            "unwarned-reclaim-cycles": 5
          },

          # Global (inherited by all subnets) lease lifetime is mandatory parameter.
          "valid-lifetime": 4000,

          "subnet4": [
            {    "subnet": "192.168.0.0/24",
                 "pools": [ { "pool": "192.168.0.150 - 192.168.0.240" } ] }
          ],

          # DHCP Options
          # Domain name
          "option-data": [
            {
              "name": "domain-name-servers",
              "data": "192.168.0.254, 1.1.1.1"
            },
            {
              "name": "routers",
              "data": "192.168.0.254"
            },
            {
              "name": "domain-name",
              "data": "home."
            }
          ]
        },

        "Logging":
        {
          "loggers": [
            {
              "name": "kea-dhcp4",
              "output_options": [
                {
                  "output": "/var/log/kea-dhcp4.log"
                }
              ],
              "severity": "INFO",
              "debuglevel": 0
            }
          ]
        }
      }
      '';
  };

  systemd.services.kea = {
    description = "ISC KEA IPv4 DHCP daemon";
    documentation = [ "man:kea-dhcp4(8)" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "time-sync.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.kea}/bin/kea-dhcp4 -c /etc/kea/kea-dhcp4.conf";
      ExecStartPre = [ "-${pkgs.coreutils}/bin/mkdir -p /run/kea" "-${pkgs.coreutils}/bin/mkdir -p /var/kea" "-${pkgs.coreutils}/bin/mkdir -p /var/lib/kea" ];
    };
    wantedBy = [ "multi-user.target" ];
  }; 
}
