extends Control
## Pantalla de inicio de Atrapa Juegos Studio: elegir qué tipo de juego crear.

signal crear(modo: String, config: Dictionary)
signal continuar
signal ayuda
signal dinorun

const Estilo := preload("res://scripts/estilo.gd")

const MODOS := [
	{"id": "2d", "emoji": "🍄", "titulo": "Plataformas 2D", "txt": "Salta, recoge monedas y vence enemigos. El clásico de siempre.", "color": Color("2ecc71")},
	{"id": "25d", "emoji": "🧊", "titulo": "Plataformas 2.5D", "txt": "Lo mismo, pero con bloques con profundidad y cámara en 3D.", "color": Color("00c4cc")},
	{"id": "3d", "emoji": "🏃", "titulo": "Juego 3D", "txt": "Corre por pistas o camina libre por un mundo 3D: aventura o corredor.", "color": Color("ff8a3d")},
]


var _scroll: ScrollContainer


func _ready() -> void:
	_construir_inicio()


func _construir_inicio() -> void:
	if _scroll:
		_scroll.queue_free()
	var scroll := ScrollContainer.new()
	_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centro.custom_minimum_size = Vector2(0, 640)
	scroll.add_child(centro)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 18)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_child(caja)
	var logo := TextureRect.new()
	logo.texture = Datos.textura("🎮")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(110, 110)
	caja.add_child(logo)
	var tit := Label.new()
	tit.text = "Atrapa Juegos Studio"
	tit.add_theme_font_size_override("font_size", 56)
	tit.add_theme_color_override("font_color", Color.WHITE)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(tit)
	var sub := Label.new()
	sub.text = "Crea tu propio videojuego arrastrando y soltando.\n¿Qué quieres crear hoy?"
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(sub)
	var fila := HFlowContainer.new()
	fila.alignment = FlowContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("h_separation", 22)
	fila.add_theme_constant_override("v_separation", 22)
	fila.custom_minimum_size = Vector2(980, 0)
	caja.add_child(fila)
	for m in MODOS:
		fila.add_child(_tarjeta(m))
	var pie := HBoxContainer.new()
	pie.alignment = BoxContainer.ALIGNMENT_CENTER
	pie.add_theme_constant_override("separation", 12)
	caja.add_child(pie)
	if FileAccess.file_exists(Datos.GUARDADO):
		var bc := Button.new()
		bc.text = "  Continuar mi último juego"
		bc.icon = Datos.textura("▶")
		bc.custom_minimum_size = Vector2(300, 54)
		bc.focus_mode = Control.FOCUS_NONE
		Estilo.pintar(bc, Estilo.AMARILLO, Color("4a3300"))
		bc.add_theme_font_size_override("font_size", 22)
		bc.pressed.connect(func(): continuar.emit())
		pie.add_child(bc)
	var bd := Button.new()
	bd.text = "  Abrir Dino Run"
	bd.icon = Datos.textura("🦖")
	bd.custom_minimum_size = Vector2(260, 54)
	bd.focus_mode = Control.FOCUS_NONE
	Estilo.pintar(bd, Color("2ecc71"), Color.WHITE)
	bd.add_theme_font_size_override("font_size", 22)
	bd.pressed.connect(func(): dinorun.emit())
	pie.add_child(bd)
	var ba := Button.new()
	ba.text = "  Ayuda"
	ba.icon = Datos.textura("❓")
	ba.custom_minimum_size = Vector2(160, 54)
	ba.focus_mode = Control.FOCUS_NONE
	Estilo.pintar(ba, Color(1, 1, 1, 0.22))
	ba.add_theme_font_size_override("font_size", 22)
	ba.pressed.connect(func(): ayuda.emit())
	pie.add_child(ba)
	var cred := Label.new()
	cred.text = "Hecho con el motor Godot (código libre)"
	cred.add_theme_font_size_override("font_size", 14)
	cred.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	cred.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(cred)


func _tarjeta(m: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 300)
	b.focus_mode = Control.FOCUS_NONE
	b.clip_text = false
	var c: Color = m["color"]
	b.add_theme_stylebox_override("normal", Estilo.caja(Color.WHITE, 28, 5, c, 16))
	b.add_theme_stylebox_override("hover", Estilo.caja(Color(1, 1, 1), 28, 8, c.lightened(0.15), 14))
	b.add_theme_stylebox_override("pressed", Estilo.caja(c.lightened(0.85), 28, 8, c, 14))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 8)
	b.add_child(v)
	var tr := TextureRect.new()
	tr.texture = Datos.textura(m["emoji"])
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(120, 120)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tr)
	var l1 := Label.new()
	l1.text = m["titulo"]
	l1.add_theme_font_size_override("font_size", 28)
	l1.add_theme_color_override("font_color", Estilo.TINTA)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l1)
	var l2 := Label.new()
	l2.text = m["txt"]
	l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l2.custom_minimum_size = Vector2(250, 0)
	l2.add_theme_font_size_override("font_size", 17)
	l2.add_theme_color_override("font_color", Estilo.SUAVE)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l2)
	b.pressed.connect(func(): _mostrar_config(m))
	return b


func _draw() -> void:
	var c0 := Estilo.TURQUESA
	var c1 := Estilo.MORADO
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]), PackedColorArray([c0, c1, c1, c0.lerp(c1, 0.5)]))
	for i in 7:
		var x := fmod(float(i) * 217.0 + 90.0, maxf(size.x, 1.0))
		var y := fmod(float(i) * 131.0 + 60.0, maxf(size.y, 1.0))
		draw_circle(Vector2(x, y), 40.0 + float(i % 3) * 30.0, Color(1, 1, 1, 0.05))


# ------------------------------------------------------------ configurar el juego nuevo
var _cfg := {"disp": "pc", "orient": "horizontal", "tipo": "corredor"}


func _mostrar_config(m: Dictionary) -> void:
	_scroll.queue_free()
	var scroll := ScrollContainer.new()
	_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centro.custom_minimum_size = Vector2(0, 640)
	scroll.add_child(centro)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 16)
	centro.add_child(caja)
	var tit := Label.new()
	tit.text = "%s  ·  Tu juego nuevo" % m["titulo"]
	tit.add_theme_font_size_override("font_size", 40)
	tit.add_theme_color_override("font_color", Color.WHITE)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(tit)
	caja.add_child(_grupo("¿Para qué dispositivo?", "disp", [["pc", "🖥", "Computador"], ["movil", "📱", "Celular o tablet"]]))
	caja.add_child(_grupo("¿Cómo se sostiene la pantalla?", "orient", [["horizontal", "↔", "Horizontal"], ["vertical", "↕", "Vertical"]]))
	_cfg["tipo"] = "corredor" if m["id"] == "3d" else "plataformas"
	if m["id"] == "2d":
		caja.add_child(_grupo("¿Qué tipo de juego 2D?", "tipo", [["plataformas", "🍄", "Plataformas (saltar)"], ["arriba", "🗺", "Vista desde arriba"]]))
	if m["id"] == "3d":
		caja.add_child(_grupo("¿Qué tipo de juego 3D?", "tipo", [["corredor", "🏃", "Corredor (3 carriles)"], ["aventura", "🗺", "Aventura (camina libre)"]]))
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 14)
	caja.add_child(fila)
	var atras := Button.new()
	atras.text = "  Volver"
	atras.icon = Datos.textura("↩")
	atras.custom_minimum_size = Vector2(170, 58)
	atras.focus_mode = Control.FOCUS_NONE
	Estilo.pintar(atras, Color(1, 1, 1, 0.22))
	atras.add_theme_font_size_override("font_size", 22)
	atras.pressed.connect(_construir_inicio)
	fila.add_child(atras)
	var ok := Button.new()
	ok.text = "  ¡Crear mi juego!"
	ok.icon = Datos.textura("🚀")
	ok.custom_minimum_size = Vector2(300, 58)
	ok.focus_mode = Control.FOCUS_NONE
	Estilo.pintar(ok, Estilo.AMARILLO, Color("4a3300"))
	ok.add_theme_font_size_override("font_size", 24)
	ok.pressed.connect(func(): crear.emit(m["id"], _cfg.duplicate()))
	fila.add_child(ok)


func _grupo(titulo: String, clave: String, opciones: Array) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var l := Label.new()
	l.text = titulo
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 12)
	v.add_child(fila)
	var botones: Array[Button] = []
	for o in opciones:
		var b := Button.new()
		b.text = "  " + o[2]
		b.icon = Datos.textura(o[1])
		b.custom_minimum_size = Vector2(280, 66)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_constant_override("icon_max_width", 40)
		fila.add_child(b)
		botones.append(b)
		b.pressed.connect(func():
			_cfg[clave] = o[0]
			_pintar_grupo(botones, opciones, clave))
	_pintar_grupo(botones, opciones, clave)
	return v


func _pintar_grupo(botones: Array[Button], opciones: Array, clave: String) -> void:
	for i in botones.size():
		if _cfg[clave] == opciones[i][0]:
			Estilo.pintar(botones[i], Estilo.AMARILLO, Color("4a3300"))
		else:
			Estilo.pintar(botones[i], Color(1, 1, 1, 0.9), Estilo.TINTA)
