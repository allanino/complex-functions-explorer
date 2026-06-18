## 2025-02-12 - Prevent redundant _process_audio_toggles() call
**Learning:** Audio settings (_process_audio_toggles()) were being applied every single physics frame (_physics_process), despite volume settings rarely changing. This redundant check wastes CPU cycles.
**Action:** Move the toggling logic to react to config changes via signals (Config.config_changed.connect) instead of continuously updating in a physics process loop.

## 2024-05-18 - Optimize Godot UI Texture Generation
**Learning:** Procedural texture generation via nested GDScript loops for pixel manipulation (e.g., `Image.set_pixel`) incurs an $O(N^2)$ CPU overhead and can cause significant UI initialization or dynamic scaling latency.
**Action:** Replace manual image iteration with Godot's built-in `GradientTexture2D` and `Gradient` resources for performance-critical generated textures like sliders and radial gradients, ensuring calculations happen at the C++ engine level. Update variable type hints to `Texture2D` when converting from `ImageTexture`.
## 2024-10-31 - [Thread-safe Heavy Computations]
**Learning:** Heavy calculations in frequent loops like `_physics_process` can cause severe frame drops. Godot 4 provides `WorkerThreadPool` to easily dispatch these tasks to background threads.
**Action:** Extract heavy operations into a separate function, dispatch them via `WorkerThreadPool.add_task(func.bind(args))`, and ensure any state or UI updates are safely returned to the main thread using `call_deferred()`.
## 2024-05-19 - Enforce Camera Height Boundary via target_y
**Learning:** To properly restrict the camera from exceeding the world height limit without corrupting physical player position logic, the boundary check must evaluate `target_y` (terrain + base camera height + user offset) rather than just the raw `terrain_h`.
**Action:** When implementing camera position constraints, mathematically clamp the variable components that contribute to the target offset (e.g., `height_offset`) instead of artifically altering physical world states (`terrain_h`).
## 2025-02-12 - UI Process Suspension
**Learning:** Heavy UI processing (like phase angle math and raymarching/shader setups) executing inside  for components that are hidden by the user wastes considerable CPU time. Components like  and  were continually checking values while hidden.
**Action:** Use  to hook into  and dynamically apply . This disables the process loop completely when the element is turned off in settings.
## 2025-02-12 - UI Process Suspension
**Learning:** Heavy UI processing (like phase angle math and raymarching/shader setups) executing inside `_process` for components that are hidden by the user wastes considerable CPU time. Components like `phase_wheel.gd` and `minimap.gd` were continually checking values while hidden.
**Action:** Use `_notification` to hook into `NOTIFICATION_VISIBILITY_CHANGED` and dynamically apply `set_process(is_visible_in_tree())`. This disables the process loop completely when the element is turned off in settings.
## 2025-02-12 - Prevent portal math calculations when not in portal mode
**Learning:** `terrain/portal/portal.gd` evaluated mathematical scaling factors and config variables (`is_multivalued`) in `_process` for every single frame across the lifetime of the game, even for functions where portals are completely disabled.
**Action:** Use `set_process(false)` and bind to `Config.config_changed` to only enable the `_process` block when a multivalued function is actively selected.
## 2025-03-01 - Suspend MainUI _process when inactive
**Learning:** In Godot, leaving `_process` running with conditional early returns based on timers (e.g., `_height_protection_timer`) still consumes CPU cycles for script execution and variable checking every frame.
**Action:** Use `set_process(false)` by default for UI components that only need `_process` during temporary state changes. Explicitly call `set_process(true)` when the event triggers the timer, and disable it again once the timers expire.
## 2025-03-01 - Suspend UI Menu _process when idle
**Learning:** The `ui/menu.gd` script used its `_process(delta)` loop entirely for decrementing a click timer (`_title_click_timer`). Because Godot calls `_process` every frame, this wasted CPU cycles when no title clicks were active (which is >99.9% of the time).
**Action:** Suspend the script's processing via `set_process(false)` in `_ready()` and immediately after the timer expires. Only call `set_process(true)` when a user registers the first click.
## 2025-03-02 - Optimize GDScript Array Copying
**Learning:** Copying GDScript arrays (like `Array[float]` or `Array[Vector2]`) into typed `Packed*Array` using `for val in array: packed.append(val)` incurs significant performance overhead due to the GDScript loop interpreter executing per-element.
**Action:** Always instantiate typed `Packed*Array` using their direct constructors (e.g., `PackedFloat32Array(source_array)`) or `append_array()` to bypass the interpreter and execute the copy natively in Godot's C++ backend.

## 2025-03-02 - Optimize LineEdit IME process checking
**Learning:** In `ui/components/text_input.gd`, `_process` ran every frame checking `has_ime_text()` and calling `$LineEdit`, wasting CPU cycles. Since IME checking is only needed while the input is actively being used, the process loop can be suspended entirely when the user is not focused on the text field.
**Action:** Cache the LineEdit node with `@onready`, initialize with `set_process(false)`, and toggle `set_process(true/false)` by hooking into the LineEdit's `focus_entered` and `focus_exited` signals.

## 2025-03-02 - Optimize Spatial Distance Checks
**Learning:** For spatial distance comparisons inside tight loops (like physics processing or convergence checks), calling `distance_to()` computes a costly and unnecessary square root operation.
**Action:** Replace `distance_to()` with `distance_squared_to()` and compare it against the threshold squared (`threshold ** 2`) to optimize CPU usage.
