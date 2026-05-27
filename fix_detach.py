from pathlib import Path

hud = Path("scenes/hud.tscn").read_text()
# Add back the ExitDetachButton
btn = """[node name="ExitDetachButton" type="Button" parent="Control/DetachOverlay/MarginContainer/HBox"]
layout_mode = 2
size_flags_vertical = 4
theme_override_styles/normal = SubResource("StyleBoxFlat_btn_normal")
theme_override_styles/hover = SubResource("StyleBoxFlat_btn_hover")
theme_override_styles/pressed = SubResource("StyleBoxFlat_btn_pressed")
text = "Exit"
"""

hud = hud.replace(
    '[node name="MorphOverlay" type="PanelContainer" parent="Control"]',
    btn + '\n[node name="MorphOverlay" type="PanelContainer" parent="Control"]'
)
Path("scenes/hud.tscn").write_text(hud)
print("restored")
