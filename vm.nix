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
  systemd.services.node-red.environment = {
    #MING_NODERED_INFLUXDB_PORT = "8086";
    #MING_NODERED_INFLUXDB_ADDRESS = "localhost";
    MING_NODERED_INFLUXDB_URL = "http://localhost:8086";
    MING_NODERED_INFLUXDB_TOKEN_FILE = "/run/super-secret-place";
  };
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
