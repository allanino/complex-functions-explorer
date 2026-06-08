extends HBoxContainer

@export var text: String = "Label":
	set(v):
		text = v
		if is_inside_tree():
			$Label.text = v

static var _arrow_initialized: bool = false

func _ready():
	$Label.text = text

	if not _arrow_initialized:
		_arrow_initialized = true
		var arrow_size = 16
		var img = Image.create(arrow_size, arrow_size, false, Image.FORMAT_RGBA8)
		var gold_color = Color(0.784314, 0.662745, 0.431373, 1.0)
		for y in range(arrow_size):
			for x in range(arrow_size):
				if y >= 6 and y <= 10:
					var half_w = (10 - y)
					var center_x = 8.0
					var dist_x = abs(float(x) - center_x)
					if dist_x <= half_w:
						img.set_pixel(x, y, gold_color)
					elif dist_x < half_w + 0.8:
						var alpha = (half_w + 0.8 - dist_x) / 0.8
						img.set_pixel(x, y, Color(gold_color.r, gold_color.g, gold_color.b, alpha))
					else:
						img.set_pixel(x, y, Color(0, 0, 0, 0))
				else:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
					
		var arrow_tex = ImageTexture.create_from_image(img)
		var global_theme = preload("res://ui/theme/theme.tres")
		global_theme.set_icon("arrow", "OptionButton", arrow_tex)

		# Generate radio_checked and radio_unchecked textures for PopupMenu/OptionButton
		var radio_size = 16
		var img_radio_checked = Image.create(radio_size, radio_size, false, Image.FORMAT_RGBA8)
		var img_radio_unchecked = Image.create(radio_size, radio_size, false, Image.FORMAT_RGBA8)
		var radio_center = Vector2(7.5, 7.5)
		
		for y in range(radio_size):
			for x in range(radio_size):
				var d = radio_center.distance_to(Vector2(x + 0.5, y + 0.5))
				
				# Unchecked outline (gold outline with 0.3 alpha)
				if d >= 5.5 and d <= 6.5:
					img_radio_unchecked.set_pixel(x, y, Color(gold_color.r, gold_color.g, gold_color.b, 0.3))
				elif d > 6.5 and d < 7.0:
					var alpha = (7.0 - d) / 0.5
					img_radio_unchecked.set_pixel(x, y, Color(gold_color.r, gold_color.g, gold_color.b, alpha * 0.3))
				elif d > 5.0 and d < 5.5:
					var alpha = (d - 5.0) / 0.5
					img_radio_unchecked.set_pixel(x, y, Color(gold_color.r, gold_color.g, gold_color.b, alpha * 0.3))
				else:
					img_radio_unchecked.set_pixel(x, y, Color(0, 0, 0, 0))
				
				# Checked: outer ring and inner dot
				var check_color = Color(0, 0, 0, 0)
				if d >= 5.5 and d <= 6.5:
					check_color = gold_color
				elif d > 6.5 and d < 7.0:
					var alpha = (7.0 - d) / 0.5
					check_color = Color(gold_color.r, gold_color.g, gold_color.b, alpha)
				elif d > 5.0 and d < 5.5:
					var alpha = (d - 5.0) / 0.5
					check_color = Color(gold_color.r, gold_color.g, gold_color.b, alpha)
				elif d <= 2.2:
					check_color = gold_color
				elif d > 2.2 and d < 2.7:
					var alpha = (2.7 - d) / 0.5
					check_color = Color(gold_color.r, gold_color.g, gold_color.b, alpha)
					
				img_radio_checked.set_pixel(x, y, check_color)

		var radio_checked_tex = ImageTexture.create_from_image(img_radio_checked)
		var radio_unchecked_tex = ImageTexture.create_from_image(img_radio_unchecked)
		
		# Override both radio and standard checkbox icons for PopupMenu and OptionButton to be golden circles
		global_theme.set_icon("radio_checked", "PopupMenu", radio_checked_tex)
		global_theme.set_icon("radio_unchecked", "PopupMenu", radio_unchecked_tex)
		global_theme.set_icon("radio_checked_disabled", "PopupMenu", radio_checked_tex)
		global_theme.set_icon("radio_unchecked_disabled", "PopupMenu", radio_unchecked_tex)
		
		global_theme.set_icon("checked", "PopupMenu", radio_checked_tex)
		global_theme.set_icon("unchecked", "PopupMenu", radio_unchecked_tex)
		global_theme.set_icon("checked_disabled", "PopupMenu", radio_checked_tex)
		global_theme.set_icon("unchecked_disabled", "PopupMenu", radio_unchecked_tex)
		
		global_theme.set_icon("radio_checked", "OptionButton", radio_checked_tex)
		global_theme.set_icon("radio_unchecked", "OptionButton", radio_unchecked_tex)
		global_theme.set_icon("checked", "OptionButton", radio_checked_tex)
		global_theme.set_icon("unchecked", "OptionButton", radio_unchecked_tex)

func get_option_button() -> OptionButton:
	return $OptionButton
