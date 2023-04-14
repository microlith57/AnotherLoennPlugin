using System;
using Microsoft.Xna.Framework;

namespace Celeste.Mod.AnotherLoennPlugin {
    public class AnotherLoennPluginModule : EverestModule {
        public static AnotherLoennPluginModule Instance { get; private set; }

        public override Type SettingsType => typeof(AnotherLoennPluginModuleSettings);
        public static AnotherLoennPluginModuleSettings Settings => (AnotherLoennPluginModuleSettings) Instance._Settings;

        public AnotherLoennPluginModule() {
            Instance = this;
#if DEBUG
            // debug builds use verbose logging
            Logger.SetLogLevel(nameof(AnotherLoennPluginModule), LogLevel.Verbose);
#else
            // release builds use info logging to reduce spam in log files
            Logger.SetLogLevel(nameof(AnotherLoennPluginModule), LogLevel.Info);
#endif
        }

        public override void Load() {
            // TODO: apply any hooks that should always be active
        }

        public override void Unload() {
            // TODO: unapply any hooks applied in Load()
        }
    }
}