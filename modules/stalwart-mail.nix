{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nix-stalwart-mail;
  configFormat = pkgs.formats.toml { };
in
{
  options.services.nix-stalwart-mail = {
    enable = mkEnableOption (mdDoc "the Stalwart all-in-one email server");
    package = mkPackageOption pkgs "stalwart-mail" { };

    settings =
      let
        serverOptions = { ... }: {
          freeformType = with types; attrsOf anything;
          options = {
            bind = mkOption {
              type = with types; listOf str;
              default = null;
            };

            protocol = mkOption {
              type = types.enum [
                "smtp"
                "lmtp"
                "jmap"
                "imap"
                "http"
                "managesieve"
              ];
              default = null;
            };

            tls.implicit = mkOption {
              type = types.bool;
              default = false;
            };
          };
        };
      in
      {
        server.listener = mkOption {
          type = types.attrsOf (types.submodule serverOptions);
          default = { };
        };
      };

    extraSettings = mkOption {
      inherit (configFormat) type;
      default = { };
    };
  };

  config =
    let
      configFile = configFormat.generate "stalwart-mail.toml" cfg.settings;
    in
    mkIf cfg.enable {
      systemd.services.nix-stalwart-mail = {
        wantedBy = [ "multi-user.target" ];
        after = [ "local-fs.target" "network.target" ];

        serviceConfig = {
          ExecStart = "${cfg.package}/bin/stalwart-mail --config=${configFile}";

          Type = "simple";
          LimitNOFILE = 65536;
          KillMode = "process";
          KillSignal = "SIGINT";
          Restart = "on-failure";
          RestartSec = 5;
          StandardOutput = "syslog";
          StandardError = "syslog";
          SyslogIdentifier = "stalwart-mail";

          DynamicUser = true;
          User = "stalwart-mail";
          StateDirectory = "stalwart-mail";

          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];

          DeviceAllow = [ "" ];
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          PrivateDevices = true;
          PrivateUsers = false;
          ProcSubset = "pid";
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          ProtectSystem = "strict";
          RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [ "@system-service" "~@privileged" ];
          UMask = "0077";
        };
      };
    };
}
