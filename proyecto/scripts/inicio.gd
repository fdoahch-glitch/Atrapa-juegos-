extends Control
## Portada y asistente de Atrapa Juegos Estudio:
## portada → plataforma → (orientación, solo en Android) → categoría → tipo de juego.

signal crear_juego(cfg: Dictionary)
signal continuar
signal ayuda
signal abierto   # se cargó un juego desde un archivo (.atrapa.json)

const Paquete := preload("res://scripts/paquete.gd")
const Estilo := preload("res://scripts/estilo.gd")
const EditorHtml := preload("res://scripts/editor_html.gd")
const Categorias := preload("res://scripts/categorias.gd")

var _scroll: ScrollContainer
var _cfg := {"plataforma": "windows", "disp": "pc", "orient": "horizontal", "categoria": "", "subtipo": ""}
var _t := 0.0
var _en_portada := true


func _ready() -> void:
	_mostrar_portada()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw() if _en_portada else null


# ------------------------------------------------------------------ pantallas
func _nueva_pantalla() -> VBoxContainer:
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
	centro.custom_minimum_size = Vector2(0, 660)
	scroll.add_child(centro)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 18)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_child(caja)
	return caja


func _etiqueta(caja: Control, texto: String, tam: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(l)
	return l


func _boton(texto: String, emoji: String, fondo: Color, tinta: Color, ancho: float, tam: int = 22) -> Button:
	var b := Button.new()
	b.text = "  " + texto
	b.icon = Datos.textura(emoji)
	b.custom_minimum_size = Vector2(ancho, 58)
	b.focus_mode = Control.FOCUS_NONE
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 34)
	b.add_theme_font_size_override("font_size", tam)
	Estilo.pintar(b, fondo, tinta)
	return b


func _mostrar_portada() -> void:
	_en_portada = true
	var caja := _nueva_pantalla()
	var logo := TextureRect.new()
	logo.texture = Datos.textura("🎮")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(120, 120)
	logo.pivot_offset = Vector2(60, 60)
	caja.add_child(logo)
	var tw := create_tween().set_loops()
	tw.tween_property(logo, "scale", Vector2(1.1, 1.1), 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(logo, "scale", Vector2(0.95, 0.95), 0.9).set_trans(Tween.TRANS_SINE)
	var t1 := _etiqueta(caja, "Atrapa Juegos", 76)
	t1.autowrap_mode = TextServer.AUTOWRAP_OFF
	_etiqueta(caja, "ESTUDIO", 40, Estilo.AMARILLO)
	var t3 := _etiqueta(caja, "Crea tu propio videojuego arrastrando y soltando", 22, Color(1, 1, 1, 0.9))
	t3.autowrap_mode = TextServer.AUTOWRAP_OFF
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 14)
	caja.add_child(fila)
	var empezar := _boton("Empezar", "🚀", Estilo.AMARILLO, Color("4a3300"), 320, 30)
	empezar.custom_minimum_size.y = 72
	empezar.pressed.connect(_mostrar_plataformas)
	fila.add_child(empezar)
	var pie := HBoxContainer.new()
	pie.alignment = BoxContainer.ALIGNMENT_CENTER
	pie.add_theme_constant_override("separation", 12)
	caja.add_child(pie)
	if FileAccess.file_exists(Datos.GUARDADO):
		var bc := _boton("Continuar mi último juego", "▶", Color(1, 1, 1, 0.92), Estilo.TINTA, 330)
		bc.pressed.connect(func(): continuar.emit())
		pie.add_child(bc)
	var bh := _boton("Editar un juego HTML", "🌐", Color(1, 1, 1, 0.22), Color.WHITE, 300)
	bh.pressed.connect(func():
		if not OS.has_feature("web") and not EditorHtml.abrir():
			bh.text = "  No pude abrir el navegador")
	if not OS.has_feature("web"):
		pie.add_child(bh)
	var pie2 := HBoxContainer.new()
	pie2.alignment = BoxContainer.ALIGNMENT_CENTER
	pie2.add_theme_constant_override("separation", 12)
	caja.add_child(pie2)
	var estado := Label.new()
	estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	estado.custom_minimum_size = Vector2(620, 0)
	estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estado.add_theme_color_override("font_color", Color.WHITE)
	var bj := _boton("Abrir un juego guardado", "📁", Color(1, 1, 1, 0.22), Color.WHITE, 330)
	bj.pressed.connect(func():
		DisplayServer.file_dialog_show("Abrir un juego guardado", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
			PackedStringArray(["*.json;Juegos de Atrapa Juegos"]),
			func(ok: bool, rutas: PackedStringArray, _f: int) -> void:
				if ok and rutas.size() > 0:
					var r: Dictionary = Paquete.abrir_proyecto(rutas[0])
					if r["ok"]:
						abierto.emit()
					else:
						estado.text = "No pude abrirlo: " + str(r["error"])))
	var bk := _boton("Abrir un APK (decompilar)", "📱", Color(1, 1, 1, 0.22), Color.WHITE, 330)
	bk.pressed.connect(func():
		DisplayServer.file_dialog_show("Elige un APK", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
			PackedStringArray(["*.apk;Apps de Android"]),
			func(ok: bool, rutas: PackedStringArray, _f: int) -> void:
				if ok and rutas.size() > 0:
					var r: Dictionary = Paquete.abrir_apk(rutas[0])
					estado.text = Paquete.resumen_apk(r) if r["ok"] else "No pude abrir el APK: " + str(r["error"])
					if r["ok"]:
						OS.shell_open(r["carpeta"])))
	if not OS.has_feature("web"):
		pie2.add_child(bj)
		pie2.add_child(bk)
		caja.add_child(estado)
	var ba := _boton("Ayuda", "❓", Color(1, 1, 1, 0.22), Color.WHITE, 170)
	ba.pressed.connect(func(): ayuda.emit())
	pie.add_child(ba)
	_etiqueta(caja, "Hecho con el motor Godot (código libre)", 14, Color(1, 1, 1, 0.6))


## Una pantalla de elección: título, tarjetas y botón «Volver».
func _eleccion(titulo: String, sub: String, opciones: Array, al_elegir: Callable, atras: Callable, ancho: float = 250) -> void:
	_en_portada = false
	var caja := _nueva_pantalla()
	_etiqueta(caja, titulo, 42)
	if sub != "":
		_etiqueta(caja, sub, 22, Color(1, 1, 1, 0.9))
	var fila := HFlowContainer.new()
	fila.alignment = FlowContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("h_separation", 20)
	fila.add_theme_constant_override("v_separation", 20)
	fila.custom_minimum_size = Vector2(1000, 0)
	caja.add_child(fila)
	for o in opciones:
		fila.add_child(_tarjeta(o, al_elegir, ancho))
	var v := _boton("Volver", "↩", Color(1, 1, 1, 0.22), Color.WHITE, 190)
	v.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.pressed.connect(atras)
	caja.add_child(v)


func _mostrar_plataformas() -> void:
	_eleccion("¿Para qué quieres tu videojuego?", "Elige dónde se va a jugar", Categorias.PLATAFORMAS, func(o):
		_cfg["plataforma"] = o["id"]
		_cfg["disp"] = o["disp"]
		if o["id"] == "android":
			_mostrar_orientacion()
		else:
			_cfg["orient"] = "horizontal"
			_mostrar_categorias(), _mostrar_portada, 230)


func _mostrar_orientacion() -> void:
	_eleccion("¿Cómo se sostiene el celular?", "", [
		{"id": "vertical", "emoji": "📱", "titulo": "Vertical", "txt": "De pie, como al mirar un video corto.", "color": Color("2ecc71")},
		{"id": "horizontal", "emoji": "↔", "titulo": "Horizontal", "txt": "Acostado, como una consola.", "color": Color("00a8b5")},
	], func(o):
		_cfg["orient"] = o["id"]
		_mostrar_categorias(), _mostrar_plataformas, 300)


func _mostrar_categorias() -> void:
	_eleccion("¿Qué categoría de juego quieres crear?", "", Categorias.CATEGORIAS, func(o):
		_cfg["categoria"] = o["id"]
		_mostrar_tipos(o), func():
		_mostrar_orientacion() if _cfg["plataforma"] == "android" else _mostrar_plataformas(), 220)


func _mostrar_tipos(cat: Dictionary) -> void:
	_eleccion("%s  ·  ¿Qué tipo?" % cat["titulo"], "", cat["tipos"], func(o):
		if not o.get("ok", true):
			return
		_cfg["subtipo"] = o["id"]
		var salida: Dictionary = _cfg.duplicate()
		salida.merge(o, true)
		salida["nombre"] = str(o["titulo"])
		crear_juego.emit(salida), _mostrar_categorias, 270)


# ------------------------------------------------------------------ tarjetas
func _tarjeta(m: Dictionary, al_elegir: Callable, ancho: float) -> Button:
	var pronto: bool = not bool(m.get("ok", true))
	var b := Button.new()
	b.custom_minimum_size = Vector2(ancho, 270)
	b.focus_mode = Control.FOCUS_NONE
	var c: Color = m.get("color", Color("8b5cf6"))
	if pronto:
		c = Color("9a9ab5")
	b.add_theme_stylebox_override("normal", Estilo.caja(Color.WHITE if not pronto else Color(1, 1, 1, 0.7), 28, 5, c, 16))
	b.add_theme_stylebox_override("hover", Estilo.caja(Color(1, 1, 1), 28, 8, c.lightened(0.15), 14))
	b.add_theme_stylebox_override("pressed", Estilo.caja(c.lightened(0.85), 28, 8, c, 14))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	b.add_child(v)
	var tr := TextureRect.new()
	tr.texture = Datos.textura(str(m["emoji"]))
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(100, 100)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.modulate = Color(1, 1, 1, 0.45) if pronto else Color.WHITE
	v.add_child(tr)
	var l1 := Label.new()
	l1.text = str(m["titulo"]) + ("  (Pronto)" if pronto else "")
	l1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l1.add_theme_font_size_override("font_size", 25)
	l1.add_theme_color_override("font_color", Estilo.TINTA if not pronto else Estilo.SUAVE)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l1)
	var l2 := Label.new()
	l2.text = str(m.get("txt", ""))
	l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l2.custom_minimum_size = Vector2(ancho - 40, 0)
	l2.add_theme_font_size_override("font_size", 16)
	l2.add_theme_color_override("font_color", Estilo.SUAVE)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l2)
	b.disabled = false
	b.pressed.connect(func(): al_elegir.call(m))
	return b


func _draw() -> void:
	var c0 := Estilo.TURQUESA
	var c1 := Estilo.MORADO
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]), PackedColorArray([c0, c1, c1, c0.lerp(c1, 0.5)]))
	for i in 9:
		var x := fmod(float(i) * 217.0 + 90.0 + sin(_t * 0.3 + i) * 40.0, maxf(size.x, 1.0))
		var y := fmod(float(i) * 131.0 + 60.0 + cos(_t * 0.25 + i) * 30.0, maxf(size.y, 1.0))
		draw_circle(Vector2(x, y), 40.0 + float(i % 3) * 30.0, Color(1, 1, 1, 0.05))
