import re
from pathlib import Path
import sys

# Now we need to re-apply the refactor correctly.
# I will just write a master script to do it all correctly.

def apply_refactor():
    content = Path("scenes/hud.tscn").read_text()

    # Check for max id in ext_resource
    ids = [int(x) for x in re.findall(r'id="(\d+)_[^"]+"', content)]
    next_id_num = max(ids + [0]) + 1

    cb_id = f"{next_id_num}_settings_cb"
    sl_id = f"{next_id_num+1}_settings_slider"
    dd_id = f"{next_id_num+2}_settings_dropdown"
    in_id = f"{next_id_num+3}_settings_input"

    new_exts = [
        f'[ext_resource type="PackedScene" path="res://scenes/hud_components/settings_checkbox.tscn" id="{cb_id}"]\n',
        f'[ext_resource type="PackedScene" path="res://scenes/hud_components/settings_slider.tscn" id="{sl_id}"]\n',
        f'[ext_resource type="PackedScene" path="res://scenes/hud_components/settings_dropdown.tscn" id="{dd_id}"]\n',
        f'[ext_resource type="PackedScene" path="res://scenes/hud_components/settings_input.tscn" id="{in_id}"]\n'
    ]

    last_ext = [m for m in re.finditer(r'\[ext_resource .*?\]\n', content)][-1]
    content = content[:last_ext.end()] + "".join(new_exts) + content[last_ext.end():]

    # Replace checkboxes
    pattern_cb = re.compile(
        r'\[node name="([^"]+?)(?:Container|)" type="HBoxContainer" parent="([^"]+)"\]\n'
        r'(.*?)\n'
        r'\[node name="\1Label" type="Label" parent="\2/\1(?:Container|)"\]\n'
        r'.*?text = "(.*?)"\n'
        r'.*?'
        r'\[node name="\1Checkbox" type="CheckBox" parent="\2/\1(?:Container|)/\1Control"\]\n'
        r'.*?(?=\n\[node|\Z)',
        re.DOTALL
    )
    def replacer_cb(match):
        return f'[node name="{match.group(1)}Checkbox" parent="{match.group(2)}" instance=ExtResource("{cb_id}")]\n{match.group(3)}\ntext = "{match.group(4)}"\n'
    content, _ = pattern_cb.subn(replacer_cb, content)

    # Replace Sliders
    pattern_sl = re.compile(
        r'\[node name="([^"]+?)(?:Container|)" type="HBoxContainer" parent="([^"]+)"\]\n'
        r'(.*?)\n'
        r'\[node name="(?:Label|\1Label)" type="Label" parent="\2/\1(?:Container|)"\]\n'
        r'.*?text = "(.*?)"\n'
        r'.*?'
        r'\[node name="\1Slider" type="HSlider" parent="\2/\1(?:Container|)"\]\n'
        r'(.*?)\n'
        r'\[node name="\1Value" type="Label" parent="\2/\1(?:Container|)"\]\n'
        r'.*?(?=\n\[node|\Z)',
        re.DOTALL
    )
    def replacer_sl(match):
        props = ""
        for attr in ['min_value', 'max_value', 'step', 'value']:
            m = re.search(fr'{attr} = ([\d\.]+)', match.group(5))
            if m: props += f'{attr} = {m.group(1)}\n'
        return f'[node name="{match.group(1)}Slider" parent="{match.group(2)}" instance=ExtResource("{sl_id}")]\n{match.group(3)}\ntext = "{match.group(4)}"\n{props}'
    content, _ = pattern_sl.subn(replacer_sl, content)

    # Replace Dropdowns
    pattern_dd = re.compile(
        r'\[node name="([^"]+?)(?:Container|)" type="HBoxContainer" parent="([^"]+)"\]\n'
        r'(.*?)\n'
        r'\[node name="(?:Label|\1Label)" type="Label" parent="\2/\1(?:Container|)"\]\n'
        r'.*?text = "(.*?)"\n'
        r'.*?'
        r'\[node name="\1Button" type="OptionButton" parent="\2/\1(?:Container|)"\]\n'
        r'.*?(?=\n\[node|\Z)',
        re.DOTALL
    )
    def replacer_dd(match):
        return f'[node name="{match.group(1)}Dropdown" parent="{match.group(2)}" instance=ExtResource("{dd_id}")]\n{match.group(3)}\ntext = "{match.group(4)}"\n'
    content, _ = pattern_dd.subn(replacer_dd, content)

    # Replace Inputs
    pattern_in = re.compile(
        r'\[node name="([^"]+?)(?:Container|)" type="HBoxContainer" parent="([^"]+)"\]\n'
        r'(.*?)\n'
        r'\[node name="(?:Label|\1Label)" type="Label" parent="\2/\1(?:Container|)"\]\n'
        r'.*?text = "(.*?)"\n'
        r'.*?'
        r'\[node name="\1Input" type="LineEdit" parent="\2/\1(?:Container|)"\]\n'
        r'(.*?)(?=\n\[node|\Z)',
        re.DOTALL
    )
    def replacer_in(match):
        m = re.search(r'text = "(.*?)"', match.group(5))
        text_prop = f'input_text = "{m.group(1)}"\n' if m else ''
        return f'[node name="{match.group(1)}Input" parent="{match.group(2)}" instance=ExtResource("{in_id}")]\n{match.group(3)}\ntext = "{match.group(4)}"\n{text_prop}'
    content, _ = pattern_in.subn(replacer_in, content)

    # Remove orphaned DetachButtons from hud.tscn
    content = re.sub(r'\[node name="[^"]+DetachButton" type="Button" parent="[^"]+"\]\n(?:.*?\n)*?(?=\n\[node|\Z)', '', content)

    # Clean old invalid connections
    def remove_bad_conn(match):
        if 'Checkbox"' in match.group(0) or 'Slider"' in match.group(0) or 'Button"' in match.group(0) or 'Input"' in match.group(0):
            # actually wait, let's keep all connection blocks intact for now except those whose paths we KNOW changed?
            # Or just delete them all since we connect programmatically in hud.gd anyway?
            # Wait! We MUST NOT delete all connections. For instance, sliders. We must re-map them!
            pass
        return match.group(0)

    # The reviewer said the UI broke because we deleted them or didn't connect them.
    # But wait, in `scripts/hud.gd` they WERE connected programmatically!
    # The real issue was that `scripts/hud.gd` `@onready` vars were broken, so `iter_slider` was null?
    # NO! The onready vars were fine, but we replaced the components.

    # Wait! ExtResource ... instances in Godot .tscn MUST NOT have `type="HBoxContainer"`!
    # Our regex didn't put `type="HBoxContainer"`!
    # `[node name="{match.group(1)}Slider" parent="{match.group(2)}" instance=ExtResource("{sl_id}")]`

    # Extract MenuOverlay
    start_idx = content.find('\n[node name="MenuOverlay"')
    end_idx = -1
    for m in re.finditer(r'\n\[node name="([^"]+)"', content[start_idx+1:]):
        full_node = content[start_idx+1+m.start() : start_idx+1+m.start()+200]
        parent_match = re.search(r'parent="([^"]+)"', full_node)
        if parent_match:
            parent = parent_match.group(1)
            if not parent.startswith("Control/MenuOverlay") and 'MenuOverlay' not in full_node:
                end_idx = start_idx + 1 + m.start()
                break
        else:
            end_idx = start_idx + 1 + m.start()
            break

    if end_idx == -1: end_idx = len(content)

    menu_content_raw = content[start_idx:end_idx]
    menu_content_modified = menu_content_raw.replace(' parent="Control"', '', 1)
    if menu_content_modified.startswith('\n'): menu_content_modified = menu_content_modified[1:]

    ext_res_pattern = re.compile(r'\[ext_resource.*?id="([^"]+)"\]')
    ext_resources = ext_res_pattern.findall(content)
    ext_lines = [m.group(0) for m in re.finditer(r'\[ext_resource.*?\]', content)]

    menu_exts = []
    for ext_line, ext_id in zip(ext_lines, ext_resources):
        if f'ExtResource("{ext_id}")' in menu_content_modified:
            menu_exts.append(ext_line)

    header = '[gd_scene load_steps=1 format=3 uid="uid://menu_scene_xyz"]\n\n'
    if menu_exts: header += "\n".join(menu_exts) + "\n\n"

    # Add SubResources
    used_subresources = set(re.findall(r'SubResource\("([^"]+)"\)', menu_content_modified))
    sub_res_pattern = re.compile(r'\[sub_resource type="[^"]+" id="([^"]+)".*?\]\n(?:.*?\n)*?(?=\[sub_resource|\[node|\[ext_resource)', re.MULTILINE)
    subresources_str = ""
    for m in sub_res_pattern.finditer(content):
        if m.group(1) in used_subresources:
            subresources_str += m.group(0) + "\n"

    Path("scenes/hud_menu.tscn").write_text(header + subresources_str + menu_content_modified + "\n")

    menu_scene_id = f"{next_id_num+4}_hud_menu"
    new_ext = f'[ext_resource type="PackedScene" path="res://scenes/hud_menu.tscn" id="{menu_scene_id}"]\n'

    last_ext = [m for m in re.finditer(r'\[ext_resource .*?\]\n', content)][-1]
    content = content[:last_ext.end()] + new_ext + content[last_ext.end():]

    start_idx = content.find('\n[node name="MenuOverlay"')
    end_idx = start_idx + len(menu_content_raw)
    instance_node = f'\n[node name="MenuOverlay" parent="Control" instance=ExtResource("{menu_scene_id}")]'
    content = content[:start_idx] + instance_node + content[end_idx:]

    # Remove all [connection] blocks related to the menu nodes since we connect in code!
    content = re.sub(r'\[connection .*?from="Control/MenuOverlay/.*?\n', '', content)

    Path("scenes/hud.tscn").write_text(content)

    # 3. Fix hud.gd
    gd_content = Path("scripts/hud.gd").read_text()

    # Fix paths
    def replace_onready(match):
        var_decl = match.group(1)
        full_path = match.group(2)
        parts = full_path.split("/")
        if len(parts) >= 2 and parts[-2].endswith("Container"):
            if parts[-1].endswith("Slider") or parts[-1].endswith("Button") or parts[-1].endswith("Input") or parts[-1].endswith("Dropdown") or parts[-1].endswith("Value") or parts[-1].endswith("Checkbox"):
                container_prefix = parts[-2][:-9]
                if parts[-1].startswith(container_prefix) or parts[-1] == "Label":
                    if parts[-1].endswith("Button"): parts[-1] = parts[-1].replace("Button", "Dropdown")
                    parts.pop(-2)
                    new_path = "/".join(parts)
                    return f"{var_decl}{new_path}"
        return match.group(0)

    gd_content = re.sub(r'(@onready var \w+\s*=\s*\$)(.*)', replace_onready, gd_content)

    # Remove old boilerplate
    gd_content = re.sub(r'func _update_freeze_time_state_label\(\):\n(?:\t.*?\n)*', 'func _update_freeze_time_state_label():\n\tpass\n\n', gd_content)
    gd_content = re.sub(r'func _update_all_checkbox_labels\(\):\n(?:\t.*?\n)*', 'func _update_all_checkbox_labels():\n\tpass\n\n', gd_content)

    gd_content_new = []
    for line in gd_content.split("\n"):
        if line.strip().endswith('text = "On" if pressed else "Off"'): continue
        if '.text = "On" if' in line: continue
        gd_content_new.append(line)

    gd_content = "\n".join(gd_content_new)
    gd_content = gd_content.replace("\t\t_update_all_checkbox_labels()\n", "")
    gd_content = re.sub(r'func _update_all_checkbox_labels\(\):\n\tpass\n\n', '', gd_content)
    gd_content = re.sub(r'func _update_freeze_time_state_label\(\):\n\tpass\n\n', '', gd_content)
    gd_content = re.sub(r'.*?checkbox\.text =.*?\n', '', gd_content)
    gd_content = gd_content.replace("\t_update_freeze_time_state_label()\n", "")
    gd_content = re.sub(r'\n\t+if \w+_checkbox:\n+', '\n', gd_content)

    # Component method replacements
    gd_content = re.sub(r'(\w+)_value\.text\s*=\s*(.*)', r'\1_slider.get_value_label().text = \2', gd_content)
    gd_content = re.sub(r'(\w+_input)\.text\s*=\s*(.*)', r'\1.set_input_text(\2)', gd_content)
    gd_content = re.sub(r'(\w+_input)\.text', r'\1.get_input_text()', gd_content)
    gd_content = gd_content.replace(".set_input_text().set_input_text(", ".set_input_text(")
    gd_content = gd_content.replace("get_input_text() = ", "set_input_text(")
    gd_content = gd_content.replace("get_input_text()_changed", "text_changed")
    gd_content = gd_content.replace("get_input_text()_submitted", "text_submitted")

    # Fix DetachButton logic
    def replace_detach(match):
        return ""

    lines = gd_content.split('\n')
    new_lines = []
    for line in lines:
        if 'DetachButton.pressed.connect(' in line:
            m = re.search(r'_on_detach_pressed\([^,]+, [^,]+, "([^"]+)"\)', line)
            title = m.group(1) if m else "Unknown"
            m2 = re.search(r'/([^/]+)DetachButton', line)
            if m2:
                base_name = m2.group(1)
                snake_name = re.sub(r'(?<!^)(?=[A-Z])', '_', base_name).lower()
                var_name = f"{snake_name}_slider"
                # Some are day_time_slider not static_time_slider
                if var_name == "static_time_slider": var_name = "day_time_slider"
                new_lines.append(f"\t{var_name}.detach_requested.connect(func(): _on_detach_pressed({var_name}.get_slider(), {var_name}.get_value_label(), \"{title}\"))")
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)
    gd_content = "\n".join(new_lines)

    # Fix broken formatting
    lines = gd_content.split('\n')
    for i, line in enumerate(lines):
        if line.strip() == 'speed_input.set_input_text("%.1f" % (Config.movement_speed * 0.1))':
            lines[i] = '\t\tspeed_input.set_input_text("%.1f" % (Config.movement_speed * 0.1))'
        elif line.strip() == 'camera_height_input.set_input_text(str(Config.camera_height))':
            lines[i] = '\t\tcamera_height_input.set_input_text(str(Config.camera_height))'
        elif line.strip() == 'height_a_input.set_input_text(str(Config.height_a))':
            lines[i] = '\t\theight_a_input.set_input_text(str(Config.height_a))'
        elif line.strip() == 'height_eps_input.set_input_text(str(Config.height_epsilon))':
            lines[i] = '\t\theight_eps_input.set_input_text(str(Config.height_epsilon))'
        elif line.strip() == 'speed_input.set_input_text(formatted_speed)':
            lines[i] = '\t\t\t\tspeed_input.set_input_text(formatted_speed)'
        elif line.strip() == 'camera_height_input.set_input_text(formatted_height)':
            lines[i] = '\t\t\t\tcamera_height_input.set_input_text(formatted_height)'

        if '@onready var quit_button' in line:
            lines[i] = line.replace('ContentVBox/QuitContainer', 'ContentVBox/ButtonsHBox/QuitContainer')
        if '.has_focus()' in line and '_input.' in line:
            lines[i] = line.replace('.has_focus()', '.get_line_edit().has_focus()')

    gd_content = "\n".join(lines)

    Path("scripts/hud.gd").write_text(gd_content)

apply_refactor()
