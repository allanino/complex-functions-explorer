extends Node
class_name ThemeColors

static var theme: Theme = preload("res://ui/theme/theme.tres")

static var real: Color = theme.get_color("font_color", "ValueRealLabel")
static var imaginary: Color = theme.get_color("font_color", "ValueImaginaryLabel")
static var gold: Color = theme.get_color("font_color", "ValueGoldLabel")

static var CLR_REAL: String = "#" + real.to_html(false)
static var CLR_IMAGINARY: String = "#" + imaginary.to_html(false)
static var CLR_IMAGINARY_DIM: String = CLR_IMAGINARY + "b3"
static var CLR_GOLD: String = "#" + gold.to_html(false)
static var CLR_DIM: String = "#e7e4dc80" # ink_dim (50% alpha)
static var CLR_RED: String = "#d65c5c" # less saturated red
