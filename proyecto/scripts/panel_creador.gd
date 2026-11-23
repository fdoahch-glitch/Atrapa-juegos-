extends ColorRect
## Creador de personajes: elige un cuerpo, cámbiale el color y ponle un accesorio.
## Se guarda en «Mis cosas» y sirve de héroe, enemigo o decoración.

signal cerrar
signal guardado(id: String)

const Estilo := preload("res://scripts/estilo.gd")
const Assets := preload("res://scripts/assets3d.gd")
const Imp := preload("res://scripts/importar.gd")
const ACCESORIOS := ["", "🎩", "👑", "🧢", "🎓", "⛑", "🎀", "😎", "🗡", "🛡", "🪄", "🔦", "🎈", "🔥", "⭐"]
const COLORES := ["#ffffff", "#ff7b7b", "#ffb347", "#ffe066", "#7bed9f", "#70d6ff", "#b79cff", "#ff9ff3", "#8d99ae", "#444444"]

var _base := "a:explorador"
var _tinte := Color.WHITE
var _acc := ""
var _en_mano := false
var _vista: TextureRect
var _nombre: LineEdit
var _msg: Label


func _ready() -> void:
	color = Color(0.08, 0.06, 0.23, 0.62)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(680.0, maxf(320.0, size.x - 24.0)), 0)
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 26, 0, Color.TRANSPARENT, 20))
	centro.add_child(panel)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, minf(640.0, maxf(300.0, size.y - 50.0)))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	sc.add_child(v)
	_t(v, "Creador de personajes", 28, Estilo.TINTA)
	_vista = TextureRect.new()
	_vista.custom_minimum_size = Vector2(0, 170)
	_vista.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vista.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(_vista)
	_t(v, "1. Elige el cuerpo", 18, Estilo.TINTA)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 6)
	fl.add_theme_constant_override("v_separation", 6)
	v.add_child(fl)
	for p in Assets.PERSONAJES:
		var b := Button.new()
		b.icon = Datos.textura("a:" + str(p[0]))
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 48)
		b.custom_minimum_size = Vector2(60, 60)
		b.tooltip_text = str(p[1])
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func():
			_base = "a:" + str(p[0])
			_pintar())
		fl.add_child(b)
	_t(v, "2. Elige el color", 18, Estilo.TINTA)
	var fc := HFlowContainer.new()
	fc.add_theme_constant_override("h_separation", 6)
	v.add_child(fc)
	for c in COLORES:
		var b := Button.new()
		b.custom_minimum_size = Vector2(44, 44)
		b.focus_mode = Control.FOCUS_NONE
		Estilo.pintar(b, Color(c))
		b.pressed.connect(func():
			_tinte = Color(c)
			_pintar())
		fc.add_child(b)
	_t(v, "3. Ponle un accesorio", 18, Estilo.TINTA)
	var fa := HFlowContainer.new()
	fa.add_theme_constant_override("h_separation", 6)
	fa.add_theme_constant_override("v_separation", 6)
	v.add_child(fa)
	for a in ACCESORIOS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(52, 52)
		b.focus_mode = Control.FOCUS_NONE
		if a == "":
			b.text = "Nada"
		else:
			b.icon = Datos.textura(a)
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 34)
		b.pressed.connect(func():
			_acc = a
			_pintar())
		fa.add_child(b)
	var f2 := HBoxContainer.new()
	f2.add_theme_constant_override("separation", 6)
	v.add_child(f2)
	for par in [["En la cabeza", false], ["En la mano", true]]:
		var b := Button.new()
		b.text = par[0]
		b.custom_minimum_size = Vector2(0, 44)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func():
			_en_mano = par[1]
			_pintar())
		f2.add_child(b)
	_t(v, "4. Ponle nombre y guárdalo", 18, Estilo.TINTA)
	_nombre = LineEdit.new()
	_nombre.placeholder_text = "Mi personaje"
	_nombre.max_length = 14
	_nombre.custom_minimum_size = Vector2(0, 44)
	v.add_child(_nombre)
	_msg = _t(v, "", 15, Estilo.VERDE)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	var g := Button.new()
	g.text = " Guardar en Mis cosas"
	g.icon = Datos.textura("💾")
	g.expand_icon = true
	g.add_theme_constant_override("icon_max_width", 26)
	g.custom_minimum_size = Vector2(0, 50)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Estilo.pintar(g, Estilo.VERDE)
	g.pressed.connect(_guardar)
	h.add_child(g)
	var c2 := Button.new()
	c2.text = "Cerrar"
	c2.custom_minimum_size = Vector2(110, 50)
	c2.pressed.connect(func(): cerrar.emit())
	h.add_child(c2)
	_pintar()


func _t(v: Control, s: String, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	return l


func _imagen(id: String) -> Image:
	var tex: Texture2D = Datos.textura(id)
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


## Arma la imagen del personaje: cuerpo con color y accesorio encima.
func _armar() -> Image:
	var img := _imagen(_base)
	if img == null:
		return null
	var w := img.get_width()
	var h := img.get_height()
	var arriba := h
	var der := 0
	var izq := w
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a > 0.3:
				arriba = mini(arriba, y)
				izq = mini(izq, x)
				der = maxi(der, x)
			if c.a > 0.0:
				img.set_pixel(x, y, Color(c.r * _tinte.r, c.g * _tinte.g, c.b * _tinte.b, c.a))
	if _acc != "":
		var a := _imagen(_acc)
		if a != null:
			var lado := int(maxf(16.0, (der - izq) * (0.55 if not _en_mano else 0.5)))
			a.resize(lado, lado, Image.INTERPOLATE_LANCZOS)
			var px := (izq + der) / 2 - lado / 2
			var py := arriba - lado / 2
			if _en_mano:
				px = der - lado / 3
				py = (arriba + h) / 2 - lado / 2
			px = clampi(px, 0, w - lado)
			py = clampi(py, 0, h - lado)
			img.blend_rect(a, Rect2i(0, 0, lado, lado), Vector2i(px, py))
	return img


func _pintar() -> void:
	var img := _armar()
	_vista.texture = ImageTexture.create_from_image(img) if img != null else null


func _guardar() -> void:
	var img := _armar()
	if img == null:
		_msg.text = "No se pudo armar el personaje."
		return
	var id := Imp.guardar_imagen(img, _nombre.text if _nombre.text.strip_edges() != "" else "personaje")
	if id == "":
		_msg.text = "No se pudo guardar."
		return
	_msg.text = "¡Listo! Está en «Mis cosas» (como héroe, enemigo o decoración)."
	guardado.emit(id)
