## 2025-02-12 - Prevent redundant _process_audio_toggles() call
**Learning:** Audio settings (_process_audio_toggles()) were being applied every single physics frame (_physics_process), despite volume settings rarely changing. This redundant check wastes CPU cycles.
**Action:** Move the toggling logic to react to config changes via signals (Config.config_changed.connect) instead of continuously updating in a physics process loop.


## 2024-05-18 - Optimize Godot UI Texture Generation with byte-array mapping
**Learning:** Procedural texture generation via nested GDScript loops for pixel manipulation (e.g., `Image.set_pixel`) incurs an $O(N^2)$ CPU overhead. While `GradientTexture2D` bypasses this, it lacks sub-pixel anti-aliasing precision which can introduce square-ish artifacts on small circular elements. Additionally, for circular mathematical coverage checks, distances must be measured from the pixel center (`float(x) + 0.5`) rather than the pixel origin (`float(x)`) to prevent asymmetric coordinate distortion.
**Action:** Replace `Image.set_pixel()` with direct 1D indexing into a `PackedByteArray` to bypass GDScript's object overhead, achieving near-native performance while retaining precise custom mathematical anti-aliasing.
