extends RefCounted
## Estilo visual infantil: botones grandes, bordes redondos, colores alegres.

const MORADO := Color("6d4aff")
const TURQUESA := Color("00c4cc")
const FONDO := Color("f1efff")
const TINTA := Color("241b4b")
const SUAVE := Color("6b6699")
const LINEA := Color("e3dfff")
const AMARILLO := Color("ffd23f")
const VERDE := Color("2ecc71")
const ROJO := Color("e5484d")


static func caja(color: Color, radio: int = 16, borde: int = 0, color_borde: Color = Color.TRANSPARENT, relleno: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radio)
	s.set_border_width_all(borde)
	s.border_color = color_borde
	s.content_margin_left = relleno
	s.content_margin_right = relleno
	s.content_margin_top = relleno * 0.6
	s.content_margin_bottom = relleno * 0.6
	return s


static func tema() -> Theme:
	var t := Theme.new()
	t.default_font_size = 20
	# Botones
	t.set_stylebox("normal", "Button", caja(Color.WHITE, 16, 2, LINEA))
	t.set_stylebox("hover", "Button", caja(Color("f6f3ff"), 16, 2, MORADO))
	t.set_stylebox("pressed", "Button", caja(Color("e6deff"), 16, 2, MORADO))
	t.set_stylebox("focus", "Button", caja(Color.TRANSPARENT, 16, 3, AMARILLO))
	t.set_stylebox("disabled", "Button", caja(Color("eeeaff"), 16, 2, LINEA))
	t.set_color("font_color", "Button", TINTA)
	t.set_color("font_hover_color", "Button", TINTA)
	t.set_color("font_pressed_color", "Button", TINTA)
	t.set_color("font_disabled_color", "Button", Color("a9a4cf"))
	t.set_constant("icon_max_width", "Button", 30)
	t.set_font_size("font_size", "Button", 20)
	# Paneles
	t.set_stylebox("panel", "PanelContainer", caja(Color.WHITE, 20, 0, Color.TRANSPARENT, 12))
	t.set_stylebox("panel", "Panel", caja(Color.WHITE, 20))
	# Texto
	t.set_color("font_color", "Label", TINTA)
	t.set_color("default_color", "RichTextLabel", TINTA)
	t.set_font_size("normal_font_size", "RichTextLabel", 20)
	t.set_font_size("bold_font_size", "RichTextLabel", 20)
	# Campo de texto
	t.set_stylebox("normal", "LineEdit", caja(Color(1, 1, 1, 0.22), 14, 0, Color.TRANSPARENT, 12))
	t.set_stylebox("focus", "LineEdit", caja(Color(1, 1, 1, 0.34), 14, 2, Color.WHITE, 12))
	t.set_color("font_color", "LineEdit", Color.WHITE)
	t.set_color("caret_color", "LineEdit", Color.WHITE)
	t.set_color("font_placeholder_color", "LineEdit", Color(1, 1, 1, 0.65))
	return t


## Pinta un botón con un color de fondo propio (para los botones importantes).
static func pintar(b: Button, fondo: Color, texto: Color = Color.WHITE) -> void:
	b.add_theme_stylebox_override("normal", caja(fondo, 16, 0, Color.TRANSPARENT, 12))
	b.add_theme_stylebox_override("hover", caja(fondo.lightened(0.12), 16, 0, Color.TRANSPARENT, 12))
	b.add_theme_stylebox_override("pressed", caja(fondo.darkened(0.12), 16, 0, Color.TRANSPARENT, 12))
	b.add_theme_stylebox_override("disabled", caja(fondo.lerp(Color.WHITE, 0.6), 16, 0, Color.TRANSPARENT, 12))
	b.add_theme_color_override("font_color", texto)
	b.add_theme_color_override("font_hover_color", texto)
	b.add_theme_color_override("font_pressed_color", texto)
	b.add_theme_color_override("font_focus_color", texto)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_disabled_color", Color(texto, 0.6))
