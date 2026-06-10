## 2025-02-12 - Prevent redundant _process_audio_toggles() call
**Learning:** Audio settings (_process_audio_toggles()) were being applied every single physics frame (_physics_process), despite volume settings rarely changing. This redundant check wastes CPU cycles.
**Action:** Move the toggling logic to react to config changes via signals (Config.config_changed.connect) instead of continuously updating in a physics process loop.

## 2024-05-18 - Optimize Godot UI Texture Generation
**Learning:** Procedural texture generation via nested GDScript loops for pixel manipulation (e.g., `Image.set_pixel`) incurs an $O(N^2)$ CPU overhead and can cause significant UI initialization or dynamic scaling latency.
**Action:** Replace manual image iteration with Godot's built-in `GradientTexture2D` and `Gradient` resources for performance-critical generated textures like sliders and radial gradients, ensuring calculations happen at the C++ engine level. Update variable type hints to `Texture2D` when converting from `ImageTexture`.
## 2024-10-31 - [Thread-safe Heavy Computations]
**Learning:** Heavy calculations in frequent loops like `_physics_process` can cause severe frame drops. Godot 4 provides `WorkerThreadPool` to easily dispatch these tasks to background threads.
**Action:** Extract heavy operations into a separate function, dispatch them via `WorkerThreadPool.add_task(func.bind(args))`, and ensure any state or UI updates are safely returned to the main thread using `call_deferred()`.
