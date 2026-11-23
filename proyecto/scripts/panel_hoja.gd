extends ColorRect
## «Animar imagen»: convierte una imagen tuya con varios dibujitos (una hoja de cuadros) en una animación.

signal cerrar

const Estilo := preload("res://scripts/estilo.gd")
const Imp := preload("res://scripts/importar.gd")

var _id := ""
var _cols: SpinBox
var _filas: SpinBox
var _fps: SpinBox
var _vista: Control


func _ready() -> void:
	color = Color(0.08, 0.06, 0.23, 0.62)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(640.0, maxf(320.0, size.x - 24.0)), 0)
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 26, 0, Color.TRANSPARENT, 20))
	centro.add_child(panel)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, minf(600.0, maxf(280.0, size.y - 60.0)))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	sc.add_child(v)
	_t(v, "Animar una imagen", 28, Estilo.TINTA)
	_t(v, "Importa una hoja con varios cuadros (por ejemplo, un personaje caminando en 4 dibujitos seguidos), elígela aquí y dile cuántas columnas y filas tiene.", 15, Estilo.SUAVE)
	var imgs: Array = Imp.listar_propios().filter(func(a): return str(a["id"]).begins_with("u:"))
	if imgs.is_empty():
		_t(v, "Todavía no tienes imágenes propias. Usa «Importar…» en Mis cosas.", 16, Estilo.ROJO)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 6)
	fl.add_theme_constant_override("v_separation", 6)
	v.add_child(fl)
	for a in imgs:
		var b := Button.new()
		b.icon = Datos.textura(a["id"])
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 56)
		b.custom_minimum_size = Vector2(64, 64)
		b.tooltip_text = str(a["n"])
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func(): _elegir(str(a["id"])))
		fl.add_child(b)
	_cols = _spin(v, "Columnas", 1, 32)
	_filas = _spin(v, "Filas", 1, 32)
	_fps = _spin(v, "Cuadros por segundo", 1, 30)
	_fps.value = 8
	_vista = Control.new()
	_vista.custom_minimum_size = Vector2(0, 150)
	_vista.draw.connect(func():
		if _id == "":
			return
		Datos.olvidar_textura(_id)
		var c := int(_cols.value)
		var f := int(_filas.value)
		var tex: Texture2D = Datos.textura(_id)
		if tex == null:
			return
		var fw := float(tex.get_width()) / c
		var fh := float(tex.get_height()) / f
		var fr := int(float(Time.get_ticks_msec()) / 1000.0 * _fps.value) % maxi(1, c * f)
		var asp := fw / maxf(1.0, fh)
		var alto := 130.0
		_vista.draw_texture_rect_region(tex, Rect2(Vector2(_vista.size.x / 2.0 - alto * asp / 2.0, 10), Vector2(alto * asp, alto)), Rect2((fr % c) * fw, (fr / c) * fh, fw, fh)))
	v.add_child(_vista)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	var g := Button.new()
	g.text = " Guardar animación"
	g.custom_minimum_size = Vector2(0, 50)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Estilo.pintar(g, Estilo.VERDE)
	g.pressed.connect(func():
		if _id != "":
			Imp.poner_hoja(_id, int(_cols.value), int(_filas.value), int(_fps.value))
			Datos.olvidar_textura(_id))
	h.add_child(g)
	var x := Button.new()
	x.text = "Cerrar"
	x.custom_minimum_size = Vector2(110, 50)
	x.pressed.connect(func(): cerrar.emit())
	h.add_child(x)


func _process(_d: float) -> void:
	if _vista != null:
		_vista.queue_redraw()


func _elegir(id: String) -> void:
	_id = id
	var h := Imp.hoja(id)
	_cols.value = float(h.get("c", 1))
	_filas.value = float(h.get("f", 1))
	_fps.value = float(h.get("fps", 8))


func _t(v: Control, s: String, tam: int, col: Color) -> void:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)


func _spin(v: Control, nombre: String, mn: int, mx: int) -> SpinBox:
	var f := HBoxContainer.new()
	var l := Label.new()
	l.text = nombre
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_color_override("font_color", Estilo.TINTA)
	f.add_child(l)
	var sb := SpinBox.new()
	sb.min_value = mn
	sb.max_value = mx
	sb.value = mn
	f.add_child(sb)
	v.add_child(f)
	return sb
