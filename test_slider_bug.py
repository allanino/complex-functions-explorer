import re

# In menu.gd:
# 565: iter_slider.min_value = iters_range[0]
# 566: iter_slider.max_value = iters_range[1]
# 567: iter_slider.step = iters_range[2]
# 570: iter_slider.value = Config.iterations

print("If we assign to iter_slider.min_value, in slider.gd:")
print("""
@export var min_value: float = 0.0:
	set(v):
		min_value = v
		if is_inside_tree():
			$Slider.min_value = v
""")

print("When $Slider.min_value is set, Godot HSlider updates its current value to respect the new bounds.")
print("If the new min_value is greater than the current value, value becomes min_value. If max_value is less than current value, value becomes max_value.")
print("And updating the value of HSlider can trigger `value_changed` signal!")
