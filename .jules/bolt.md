## 2025-02-12 - Prevent redundant _process_audio_toggles() call
**Learning:** Audio settings (_process_audio_toggles()) were being applied every single physics frame (_physics_process), despite volume settings rarely changing. This redundant check wastes CPU cycles.
**Action:** Move the toggling logic to react to config changes via signals (Config.config_changed.connect) instead of continuously updating in a physics process loop.
