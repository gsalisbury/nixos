{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
in
{
  environment.systemPackages = with pkgs; [
    net_snmp go gcc
  ];

  systemd.services.microchip = {
    description = "microchip snmp poller";
    serviceConfig.Type = "oneshot";
    path = [ pkgs.net_snmp ];

    script = ''
      IP="192.168.0.108"
      CARBON="192.168.0.254"
      COMMUNITY="public"
      NOW=$(date +%s)

      TEMP=$(snmpget -v2c -c $COMMUNITY $IP iso.3.6.1.4.1.17095.3.7.0 | sed -r 's/.*\"(.*)\"/\1/')
      VOLTAGE=$(snmpget -v2c -c $COMMUNITY $IP iso.3.6.1.4.1.17095.3.5.0 | sed -r 's/.*\"(.*)\"/\1/')

      echo "solar.house.battery_temp $TEMP $NOW" | /run/current-system/sw/bin/nc -q 1 $CARBON 2003
      echo "solar.house.battery_voltage $VOLTAGE $NOW" | /run/current-system/sw/bin/nc -q 1 $CARBON 2003
    '';

    # every 5 minutes
    startAt = "*:0/5";
  };

  systemd.services.mppt = {
    description = "MPPT charge controller poller";
    serviceConfig.Type = "oneshot";
    path = [ pkgs.docker ];
    #environment = { GOPATH = "/root/go"; };
  
    script = ''
      docker run --rm --device /dev/ttyUSB0 mppt:latest
    '';
  
    # every 5 minutes
    startAt = "*:0/5";
  };

  systemd.services.sensors = {
    description = "apu lm_sensors poller";
    serviceConfig.Type = "oneshot";
    path = [ pkgs.lm_sensors ];

    script = ''
      CARBON="192.168.0.254"
      NOW=$(date +%s)

      CURRENT_TEMP=$(sensors | grep temp1 | grep -Eow "[0-9.]+" | head -n 1)
      HIGH_TEMP=$(sensors | grep temp1 | grep -Eow "[0-9.]+" | tail -n 1)
      POWER1=$(sensors | grep power1 | grep -Eow "[0-9.]+" | head -n 1)
      POWER1_CRIT=$(sensors | grep power1 | grep -Eow "[0-9.]+" | tail -n 1)

      echo "apu.kuil_tower.temp_current $CURRENT_TEMP $NOW" | /run/current-system/sw/bin/nc -q 1 $CARBON 2003
      echo "apu.kuil_tower.temp_high $HIGH_TEMP $NOW" | /run/current-system/sw/bin/nc -q 1 $CARBON 2003
      echo "apu.kuil_tower.power1_watts $POWER1 $NOW" | /run/current-system/sw/bin/nc -q 1 $CARBON 2003
      echo "apu.kuil_tower.power1_crit_watts $POWER1_CRIT $NOW" | /run/current-system/sw/bin/nc -q 1 $CARBON 2003
    '';

    # every 5 minutes
    startAt = "*:0/5";
  };

}
