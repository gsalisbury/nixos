{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
in
{
  environment.systemPackages = with pkgs; [
    coredns
  ];

  environment.etc = {
    "coredns/Corefile".text = ''
      home:1053 {
	  file db.home
	  log
	  errors
	  health :8081
      }

      0.168.192.in-addr.arpa:1053 {
	  file db.0.168.192.in-addr.arpa
	  log
	  errors
	  health :8082
      }

      168.192.in-addr.arpa:1053 {
	  file db.168.192.in-addr.arpa
	  log
	  errors
      }
    '';
    "coredns/db.0.168.192.in-addr.arpa".text = ''
      $ORIGIN 0.168.192.in-addr.arpa.
      @       3600 IN SOA sns.dns.icann.org. noc.dns.icann.org. (
				      2018070101 ; serial
				      7200       ; refresh (2 hours)
				      3600       ; retry (1 hour)
				      1209600    ; expire (2 weeks)
				      3600       ; minimum (1 hour)
				      )

	      3600 IN NS apu.home.

      254     IN PTR     apu.home.
    '';
    "coredns/db.168.192.in-addr.arpa".text = ''
      $ORIGIN 168.192.in-addr.arpa.
      @       3600 IN SOA sns.dns.icann.org. noc.dns.icann.org. (
				      2018070201 ; serial
				      7200       ; refresh (2 hours)
				      3600       ; retry (1 hour)
				      1209600    ; expire (2 weeks)
				      3600       ; minimum (1 hour)
				      )

	      3600 IN NS apu.home.
    '';
    "coredns/db.home".text = ''
      $ORIGIN home.
      @       3600 IN SOA sns.dns.icann.org. noc.dns.icann.org. (
				      2018070301 ; serial
				      7200       ; refresh (2 hours)
				      3600       ; retry (1 hour)
				      1209600    ; expire (2 weeks)
				      3600       ; minimum (1 hour)
				      )

	      7200 IN NS apu.home.

      apu     IN A     192.168.0.254
              IN AAAA  2001:44b8:2147:1100::1
      lopy    IN A     192.168.0.20
      qnap    IN A     192.168.0.50
    '';
  };
}
