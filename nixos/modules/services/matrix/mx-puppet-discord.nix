{
  config,
  pkgs,
  lib,
  ...
}:
let
  dataDir = "/var/lib/mx-puppet-discord";
  registrationFile = "${dataDir}/discord-registration.yaml";
  cfg = config.services.mx-puppet-discord;
  settingsFormat = pkgs.formats.json { };
  settingsFile = settingsFormat.generate "mx-puppet-discord-config.json" cfg.settings;

in
{
  options = {
    services.mx-puppet-discord = {
      enable = lib.mkEnableOption ''
        mx-puppet-discord is a discord puppeting bridge for matrix.
        It handles bridging private and group DMs, as well as Guilds (servers)
      '';

      settings = lib.mkOption rec {
        apply = lib.recursiveUpdate default;
        inherit (settingsFormat) type;
        default = {
          bridge.port = 8434;
          presence = {
            enabled = true;
            interval = 500;
          };
          provisioning.whitelist = [ ];
          relay.whitelist = [ ];

          # variables are preceded by a colon.
          namePatterns = {
            user = ":name";
            userOverride = ":displayname";
            room = ":name";
            group = ":name";
          };

          #defaults to sqlite but can be configured to use postgresql with
          #connstring
          database.filename = "${dataDir}/database.db";
          logging = {
            console = "info";
            lineDateFormat = "MMM-D HH:mm:ss.SSS";
          };
        };
        example = lib.literalExpression ''
          {
            bridge = {
              bindAddress = "localhost";
              domain = "example.com";
              homeserverUrl = "https://example.com";
            };

            provisioning.whitelist = [ "@admin:example.com" ];
            relay.whitelist = [ "@.*:example.com" ];
          }
        '';
        description = ''
          {file}`config.yaml` configuration as a Nix attribute set.
          Configuration options should match those described in
          [
          sample.config.yaml](https://github.com/matrix-discord/mx-puppet-discord/blob/master/sample.config.yaml).
        '';
      };
      serviceDependencies = lib.mkOption {
        type = with lib.types; listOf str;
        default = lib.optional config.services.matrix-synapse.enable config.services.matrix-synapse.serviceUnit;
        defaultText = lib.literalExpression ''
          lib.optional config.services.matrix-synapse.enable config.services.matrix-synapse.serviceUnit
        '';
        description = ''
          List of Systemd services to require and wait for when starting the application service.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.mx-puppet-discord = {
      description = "Matrix to Discord puppeting bridge";

      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ] ++ cfg.serviceDependencies;
      after = [ "network-online.target" ] ++ cfg.serviceDependencies;

      preStart = ''
        # generate the appservice's registration file if absent
        if [ ! -f '${registrationFile}' ]; then
          ${pkgs.mx-puppet-discord}/bin/mx-puppet-discord -r -c ${settingsFile} \
          -f ${registrationFile}
        fi
      '';

      serviceConfig = {
        Type = "simple";
        Restart = "always";

        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;

        DynamicUser = true;
        PrivateTmp = true;
        WorkingDirectory = pkgs.mx-puppet-discord;
        StateDirectory = baseNameOf dataDir;
        UMask = "0027";

        ExecStart = ''
          ${pkgs.mx-puppet-discord}/bin/mx-puppet-discord \
            -c ${settingsFile} \
            -f ${registrationFile}
        '';
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ govanify ];
}
