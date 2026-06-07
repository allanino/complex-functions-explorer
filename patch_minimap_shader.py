import sys

filepath = 'ui/minimap.gdshader'
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace(
    'uniform int visited_zeros_size;',
    'uniform int visited_zeros_size;\nuniform int accented_zero_index = -1;'
)

search_str = """
    if (show_hud_zeros && visited_zeros_size > 0) {
        float core_intensity = 0.0;
        float border_intensity = 0.0;
        float glow_intensity = 0.0;
        float scale = zoom_factor * 32.0;

        float r_core = 0.10 * scale;
        float border_width = 0.05 * scale;
        float r_total = r_core + border_width;
        float r_glow = r_total + 0.20 * scale;

        float pulse = 0.5 + 0.5 * sin(TIME * 5.0);

        for (int i = 0; i < visited_zeros_size; i++) {
            vec2 p = vec2(visited_zeros[i].x * 10.0 * zoom_factor, -visited_zeros[i].y * 10.0 * zoom_factor);

            float d_center = length(world_pos - p);
            float aa = fwidth(d_center);

            float core_val = 1.0 - smoothstep(r_core - aa, r_core + aa, d_center);
            float total_val = 1.0 - smoothstep(r_total - aa, r_total + aa, d_center);
            float border_val = clamp(total_val - core_val, 0.0, 1.0);

            // Pulsing glow outside the circle boundary
            float glow_val = (1.0 - smoothstep(r_total - aa, r_glow + aa, d_center)) * (1.0 - total_val);

            core_intensity = max(core_intensity, core_val);
            border_intensity = max(border_intensity, border_val);
            glow_intensity = max(glow_intensity, glow_val);
        }

        if (core_intensity > 0.0 || border_intensity > 0.0 || glow_intensity > 0.0) {
            vec3 bright_gold = vec3(1.0, 0.84, 0.3); // Bright gold
            vec3 dark_gold = vec3(0.5, 0.35, 0.05);   // Darker gold tone

            // First mix the pulsing glow outside the circle
            base_color = mix(base_color, bright_gold, glow_intensity * pulse * 0.7);

            // Then mix the dark gold outline
            base_color = mix(base_color, dark_gold, clamp(border_intensity, 0.0, 1.0));

            // Overlay the bright gold core with a subtle brightness pulse
            vec3 pulsed_core_color = bright_gold * (1.0 + 0.25 * pulse);
            base_color = mix(base_color, pulsed_core_color, clamp(core_intensity, 0.0, 1.0));
        }
    }
"""

replace_str = """
    if (show_hud_zeros && visited_zeros_size > 0) {
        float core_intensity = 0.0;
        float border_intensity = 0.0;
        float glow_intensity = 0.0;

        float accented_core_intensity = 0.0;
        float accented_border_intensity = 0.0;
        float accented_glow_intensity = 0.0;

        float scale = zoom_factor * 32.0;

        float r_core = 0.10 * scale;
        float border_width = 0.05 * scale;
        float r_total = r_core + border_width;
        float r_glow = r_total + 0.20 * scale;

        float acc_r_core = 0.15 * scale;
        float acc_r_total = acc_r_core + border_width;
        float acc_r_glow = acc_r_total + 0.30 * scale;

        float pulse = 0.5 + 0.5 * sin(TIME * 5.0);
        float fast_pulse = 0.5 + 0.5 * sin(TIME * 15.0);

        for (int i = 0; i < visited_zeros_size; i++) {
            vec2 p = vec2(visited_zeros[i].x * 10.0 * zoom_factor, -visited_zeros[i].y * 10.0 * zoom_factor);

            float d_center = length(world_pos - p);
            float aa = fwidth(d_center);

            bool is_accented = (i == accented_zero_index);

            float cur_r_core = is_accented ? acc_r_core : r_core;
            float cur_r_total = is_accented ? acc_r_total : r_total;
            float cur_r_glow = is_accented ? acc_r_glow : r_glow;

            float core_val = 1.0 - smoothstep(cur_r_core - aa, cur_r_core + aa, d_center);
            float total_val = 1.0 - smoothstep(cur_r_total - aa, cur_r_total + aa, d_center);
            float border_val = clamp(total_val - core_val, 0.0, 1.0);

            // Pulsing glow outside the circle boundary
            float glow_val = (1.0 - smoothstep(cur_r_total - aa, cur_r_glow + aa, d_center)) * (1.0 - total_val);

            if (is_accented) {
                accented_core_intensity = max(accented_core_intensity, core_val);
                accented_border_intensity = max(accented_border_intensity, border_val);
                accented_glow_intensity = max(accented_glow_intensity, glow_val);
            } else {
                core_intensity = max(core_intensity, core_val);
                border_intensity = max(border_intensity, border_val);
                glow_intensity = max(glow_intensity, glow_val);
            }
        }

        vec3 bright_gold = vec3(1.0, 0.84, 0.3); // Bright gold
        vec3 dark_gold = vec3(0.5, 0.35, 0.05);   // Darker gold tone

        if (core_intensity > 0.0 || border_intensity > 0.0 || glow_intensity > 0.0) {
            // First mix the pulsing glow outside the circle
            base_color = mix(base_color, bright_gold, glow_intensity * pulse * 0.7);

            // Then mix the dark gold outline
            base_color = mix(base_color, dark_gold, clamp(border_intensity, 0.0, 1.0));

            // Overlay the bright gold core with a subtle brightness pulse
            vec3 pulsed_core_color = bright_gold * (1.0 + 0.25 * pulse);
            base_color = mix(base_color, pulsed_core_color, clamp(core_intensity, 0.0, 1.0));
        }

        if (accented_core_intensity > 0.0 || accented_border_intensity > 0.0 || accented_glow_intensity > 0.0) {
            // First mix the pulsing glow outside the circle
            base_color = mix(base_color, bright_gold, accented_glow_intensity * fast_pulse * 0.7);

            // Then mix the dark gold outline
            base_color = mix(base_color, dark_gold, clamp(accented_border_intensity, 0.0, 1.0));

            // Overlay the bright gold core with a subtle brightness pulse
            vec3 pulsed_core_color = bright_gold * (1.0 + 0.25 * fast_pulse);
            base_color = mix(base_color, pulsed_core_color, clamp(accented_core_intensity, 0.0, 1.0));
        }
    }
"""

content = content.replace(search_str, replace_str)

with open(filepath, 'w') as f:
    f.write(content)
