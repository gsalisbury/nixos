{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
in
{
  imports =  [
    ../services/ppp.nix
  ];

  networking = {
    domain = "home";
    nameservers = [ "127.0.0.1" "8.8.8.8" ];
    networkmanager.enable = false;
    enableIPv6 = true;

    firewall = {
      enable = true;
      allowPing = true;
      trustedInterfaces = [ "enp2s0" "enp3s0" ];
      checkReversePath = false; # https://github.com/NixOS/nixpkgs/issues/10101
      allowedTCPPorts = [
        22    # ssh
      ];
      allowedUDPPorts = [ ];
    };

    nat = {
      enable = true;
      internalIPs = [ "192.168.0.0/24" "192.168.1.0/24" ];
      externalInterface = "ppp0";
    };

    interfaces = {
      enp1s0 = {
        useDHCP = false;
      };

      enp2s0 = {
        ipv4.addresses = [ { address = "192.168.0.253"; prefixLength = 24; } ];
      };

      enp3s0 = {
        ipv4.addresses = [ { address = "192.168.1.253"; prefixLength = 24; } ];
      };
    };

  };

  services.dnsmasq = {
    enable = true;
    servers = [ "192.168.0.253" "1.1.1.1" ];
    extraConfig = ''
      domain=home
      interface=enp2s0
      interface=enp3s0
      bind-interfaces
      dhcp-range=192.168.0.150,192.168.0.199,24h
      dhcp-range=192.168.1.10,192.168.1.254,24h
    '';
  };

  services.unbound = {
    enable = true;
    interfaces = ["127.0.0.1" "::1"];
    extraConfig =
    ''
      verbosity: 1
      do-not-query-localhost: no
      qname-minimisation: yes
      domain-insecure: "home"

    forward-zone:
      name: "home"
      forward-addr: 127.0.0.1@1053
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
        lcp-echo-interval 15
        lcp-echo-failure 3
      '';
    };
  };

}
