{ pkgs, config, lib, node-red-contrib-influxdb, ... }:
{

  virtualisation = {
    forwardPorts = [
      { from = "host"; host.port = 1880; guest.port = 1880; }
      { from = "host"; host.port = 1883; guest.port = 1883; }
      { from = "host"; host.port = 3000; guest.port = 3000; }
      { from = "host"; host.port = 8086; guest.port = 8086; }
    ];
  };

  environment.systemPackages = with pkgs; [
    bore-cli
    vim
    git
  ];
  networking = {
    firewall.allowedTCPPorts = [ 1883 ];
  };
  systemd.services.node-red.preStart = let
    baseFlowsJsonFile = builtins.toFile "flows.json" baseFlowsJson;
    baseFlowsJson = builtins.toJSON {
      id = "32deae1cf6a499f8";
      type = "influxdb";
      hostname = "127.0.0.1";
      port = "8086";
      protocol = "http";
      database = "database";
      name = "ming";
      usetls = "false";
      tls = "";
      influxdbVersion = "2.0";
      url = "http://localhost:8086";
      rejectUnauthorized = true;
    };
  in
  ''
    if [ ! -d "${config.services.node-red.userDir}/flows.json" ]
    then
      ${pkgs.jq}/bin/jq -s '.' < ${baseFlowsJsonFile} > ${config.services.node-red.userDir}/flows.json
    else
      ${pkgs.jq}/bin/jq --slurpfile new_values ${baseFlowsJsonFile} 'map(if .id == "32deae1cf6a499f8" then . += $new_values[0] else . end)' ${config.services.node-red.userDir}/flows.json
    fi
  '';
  systemd.tmpfiles.rules = [
    "L+ ${config.services.node-red.userDir}/node_modules 0755 ${config.services.node-red.user} ${config.services.node-red.group} - ${node-red-contrib-influxdb}/lib/node_modules"
  ];

  services = {
    grafana = {
      enable = true;
      settings = {
        analytics.reporting_enabled = false;
        server = {
          http_addr = "0.0.0.0";
          domain = "0.0.0.0";
        };
        security = {
          admin_user = "testadmin";
          admin_password = "snakeoilpwd";
        };
      };
    };
    node-red = {
      enable = true;
    };
    influxdb2 = {
      enable = true;
      provision = {
        enable = true;
        initialSetup = {
          organization = "default";
          bucket = "default";
          passwordFile = pkgs.writeText "admin-pw" "ExAmPl3PA55W0rD";
          tokenFile = pkgs.writeText "admin-token" "verysecureadmintoken";
        };
        organizations.ming = {
          buckets.mingBucket = {
            retention = 2592000; # 30 Days
          };
          auths.mingToken = {
            description = "some auth token";
            readBuckets = ["mingBucket"];
            writeBuckets = ["mingBucket"];
          };
        };
        users = {
          ming = {
            present = true;
            passwordFile = pkgs.writeText "tmp-pw" "abcgoiuhaoga";
          };
        };
      };
    };
    mosquitto = {
      enable = true;
      settings.max_keepalive = 300;
      listeners = [
        {
          port = 1883;
          omitPasswordAuth = true;
          users = {};
          settings = {
            allow_anonymous = true;
          };
          acl = [ "topic readwrite #" "pattern readwrite #" ];
        }
      ];
    };
  };
}
