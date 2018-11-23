{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
in
{
  environment.systemPackages = with pkgs; [
    python27Packages.whisper
  ];

  services.graphite.carbon = {
    enableCache = true;
    config =
    ''
    [cache]
    UDP_RECEIVER_INTERFACE = 192.168.0.254
    PICKLE_RECEIVER_INTERFACE = 192.168.0.254
    LINE_RECEIVER_INTERFACE = 192.168.0.254
    CACHE_QUERY_INTERFACE = 127.0.0.1
    # Do not log every update
    LOG_UPDATES = False
    LOG_CACHE_HITS = False
    # Storage options
    LOCAL_DATA_DIR = /data/whisper
    '';

    storageSchemas =
    ''
    [carbon]
    pattern = ^carbon\.
    retentions = 10s:6h,1m:90d

    [dailysolar]
    pattern = ^solar\.house\.daily\.
    retentions = 1d:10y

    [solar]
    pattern = ^solar\.
    retentions = 5m:30d,30m:60d,1h:5y

    [microchip]
    pattern = ^microchip\.
    retentions = 5m:7d,30m:30d,1h:5y

    [ubiquity]
    pattern = ^ubiquity\.
    retentions = 5m:7d,30m:30d,1h:5y

    [default_1min_for_1day]
    pattern = .*
    retentions = 5m:7d,1h:2y
    '';
  };

  services.graphite.api = {
    enable = true;
    extraConfig =
    ''
    whisper:
      directories:
        - /data/whisper
    cache:
      CACHE_TYPE: 'filesystem'
      CACHE_DIR: '/tmp/graphite-api-cache'
    '';
    port = 8000;
  };
}
