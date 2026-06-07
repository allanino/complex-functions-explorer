1. **Prevent slider binding signals during bound update**: The slider bound change (setting `min_value` or `max_value`) causes Godot's built-in `HSlider` to auto-adjust its `value` if it is out of the new bounds. This auto-adjustment emits `value_changed` which triggers the `SLIDER_BINDINGS` handler `_on_generic_slider_changed` and ultimately modifies `Config.iterations`.
2. **Use `set_value_no_signal`**: Inside `_on_func_selected`, `iter_slider.value = Config.iterations` assigns value directly, triggering the generic change listener. It should use `iter_slider.set_value_no_signal(Config.iterations)` and manually update the text. However, a better approach is to use a block flag, such as `_syncing_ui` inside `_on_generic_slider_changed`.
3. **Plan detail**:
   - In `ui/menu.gd`, modify `_on_generic_slider_changed` to check `if _syncing_ui: return`.
   - Update `_on_func_selected` to temporarily set `_syncing_ui = true` before modifying the slider `min_value`, `max_value`, `step`, and `value`, then revert `_syncing_ui = false` after. Additionally, we need to ensure the value label is updated.
4. **Pre commit instructions**: Use pre-commit steps.
