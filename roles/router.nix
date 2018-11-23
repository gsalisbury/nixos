{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
in
{
  imports =  [
    #../services/coredns.nix
    ../services/grafana.nix
    ../services/graphite.nix
    ../services/kea.nix
    #../services/kubernetes-master.nix
    #../services/kubernetes-node.nix
    ../services/ppp.nix
  ];

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq_codel";
    "net.ipv6.conf.all.accept_ra" = 2;
    "net.ipv6.conf.default.accept_ra" = 2;
    "net.ipv6.conf.enp2s0.accept_ra" = 0;
    "net.ipv6.conf.enp2s0.accept_ra_defrtr" = 0;
    "net.ipv6.conf.enp2s0.accept_ra_pinfo" = 0;
    "net.ipv6.conf.all.forwarding" = 2;
    "net.ipv6.conf.default.forwarding" = 2;
  };

  environment.etc = {
    "resolvconf.conf".text =
      ''
      name_servers_append='1.0.0.1'
      '';
  };

  networking = {
    domain = "home";
    nameservers = [ "127.0.0.1" "1.0.0.1" ]; # this doesn't do anything
    networkmanager.enable = false;
    enableIPv6 = true;

    firewall = {
      enable = true;
      allowPing = true;
      trustedInterfaces = [ "enp2s0" "enp3s0" "docker0" "wg0" ];
      checkReversePath = false; # https://github.com/NixOS/nixpkgs/issues/10101
      allowedTCPPorts = [
        22    # ssh
        80    # http
        443   # http
      ];
      # allow dhcpv6 PD and wireguard
      allowedUDPPorts = [ 546 5060 51820 ];
      logRefusedConnections = false;
      extraCommands =
      ''
        iptables -A INPUT -p udp -m comment --comment "allow DNS server replies" -m udp --sport 53 -j ACCEPT
        ip6tables -A INPUT -p udp -m comment --comment "allow DNS server replies" -m udp --sport 53 -j ACCEPT
        ip6tables -A INPUT -p udp -m comment --comment "allow DHCP server replies" -m udp --sport 547 -j ACCEPT
      '';
    };

    nat = {
      enable = true;
      internalIPs = [ "192.168.0.0/24" "192.168.1.0/24" "192.168.20.0/24" ];
      externalInterface = "ppp0";
    };

    interfaces = {
      enp1s0 = {
        useDHCP = false;
      };

      enp2s0 = {
        ipv4.addresses = [ { address = "192.168.0.254"; prefixLength = 24; } ];
        ipv6 = {
          addresses = [ { address = "2001:44b8:2147:1100::1"; prefixLength = 64; } ];
        };
      };

      enp3s0 = {
        ipv4.addresses = [ { address = "192.168.1.254"; prefixLength = 24; } ];
      };
    };
    wireguard.interfaces.wg0 = {
      ips = [ "192.168.20.1/24" ];
      peers = [ { allowedIPs = [ "192.168.20.2/32" ]; publicKey = "o1cmsDqKby/ZIEmvDGRQsyu1/0koQPyWf8G3fQjwL1A="; } ];
      privateKeyFile = "/etc/private/wireguard.key";
      listenPort = 51820;
    };
  };

  services.radvd = {
    enable = true;
    config = ''
      interface enp2s0
      {
         AdvSendAdvert on;
         prefix 2001:44b8:2147:1100::1/64
         {
            AdvOnLink on;
            AdvAutonomous on;
            AdvRouterAddr on;
         };
         RDNSS 2001:44b8:2147:1100:0:0:0:1 {
            AdvRDNSSLifetime 3600;
         };
         DNSSL home
         {
                # AdvDNSSLLifetime 3600; # Defalt is ok.
         };
       };
    '';
  };

  services.unbound = {
    enable = true;
    enableRootTrustAnchor = true;
    interfaces = [ "127.0.0.1" "::1" "192.168.0.254" "2001:44b8:2147:1100::1" ];
    allowedAccess = [ "127.0.0.0/24" "::1/128" "fe80::/10" "192.168.0.0/24" "2001:44b8:2147:1100::/56" ];
    extraConfig =
    ''
    verbosity: 1
    do-not-query-localhost: no
    qname-minimisation: yes
    private-address: 192.168.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8
    domain-insecure: "home."

    local-zone: "home." static
    local-data: "apu.home.      IN A      192.168.0.254"
    local-data: "apu.home.      IN AAAA   2001:44b8:2147:1100::1"
    local-data: "grafana.home.  IN A      192.168.0.254"
    local-data: "grafana.home.  IN AAAA   2001:44b8:2147:1100::1"
    local-data: "lopy.home.     IN A      192.168.0.20"
    local-data: "qnap.home.     IN A      192.168.0.50"
    local-data: "house-printer.home.    IN A      192.168.0.114"
    local-data: "shop-printer.home.     IN A      192.168.0.115"
    local-data: "_ipp._tcp.home.        IN PTR    house-printer._ipp._tcp.home."
    local-data: "house-printer._ipp._tcp.home.    IN SRV    0 0 631 house-printer.home."

    local-data-ptr: "192.168.0.254  apu.home"
    local-data-ptr: "192.168.0.20   lopy.home"
    local-data-ptr: "192.168.0.50   qnap.home"
    local-data-ptr: "192.168.0.114  house-printer.home"
    local-data-ptr: "192.168.0.115  shop-printer.home"
    '';
  };

  services.ppp = {
    enable = true;
    config.internode = {
      interface = "enp1s0";
      username = secrets.internode.username;
      password = secrets.internode.password;
      pppoe = true;
      extraOptions = ''
        noauth
        defaultroute
        persist
        maxfail 0
        holdoff 5
        noipdefault
        lcp-echo-interval 15
        lcp-echo-failure 3
        +ipv6 ipv6cp-use-persistent
        ipv6 ,
      '';
    };
  };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    storageDriver = "overlay2";
  };

}
