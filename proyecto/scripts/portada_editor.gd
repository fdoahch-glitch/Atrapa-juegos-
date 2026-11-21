extends Control
## Editor de la portada: fondo, título y botones propios.
## Clic derecho sobre un botón → Animación / Acción. Arrastra para mover, esquina para agrandar.

const Estilo := preload("res://scripts/estilo.gd")
const Importar := preload("res://scripts/importar.gd")

signal cambio
signal aviso(txt: String)

var sel := -1
var _arrastre := ""   # "", "mover", "tam"
var _off := Vector2.ZERO
var _t := 0.0
var _menu: PopupMenu
var _sub_anim: PopupMenu
var _sub_acc: PopupMenu
var _formato := "webp"
var _barra: HBoxContainer
var _tit: LineEdit
var _en_fondo := false


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construir_barra()
	_construir_menu()


func _p() -> Dictionary:
	return Datos.reglas["portada"]


func _botones() -> Array:
	return _p()["botones"]


func _process(d: float) -> void:
	_t += d
	if visible:
		queue_redraw()


## Rectángulo donde se dibuja la portada (misma forma que la pantalla del juego).
func marco() -> Rect2:
	var vertical: bool = str(Datos.nivel.get("orient", "horizontal")) == "vertical"
	var ratio := 9.0 / 16.0 if vertical else 16.0 / 9.0
	var libre := Rect2(10, 122, size.x - 20, size.y - 134)
	var w := libre.size.x
	var h := w / ratio
	if h > libre.size.y:
		h = libre.size.y
		w = h * ratio
	return Rect2(libre.position + (libre.size - Vector2(w, h)) / 2.0, Vector2(w, h))


func _rect_boton(b: Dictionary, m: Rect2) -> Rect2:
	var s := Vector2(b["w"] * m.size.x, b["h"] * m.size.y)
	return Rect2(m.position + Vector2(b["x"] * m.size.x, b["y"] * m.size.y) - s / 2.0, s)


# ------------------------------------------------------------------ interfaz
func _construir_barra() -> void:
	_barra = HBoxContainer.new()
	_barra.position = Vector2(12, 12)
	_barra.add_theme_constant_override("separation", 6)
	add_child(_barra)
	_barra.add_child(_mk(" Fondo", "🖼", _elegir_fondo, "Sube una imagen de fondo"))
	var fmt := OptionButton.new()
	for f in ["webp", "png", "jpg", "original"]:
		fmt.add_item("Guardar como " + f.to_upper() if f != "original" else "Dejar como está")
	fmt.custom_minimum_size = Vector2(190, 44)
	fmt.tooltip_text = "Convierte tu imagen para que pese menos (WebP es la más liviana)"
	fmt.item_selected.connect(func(i): _formato = ["webp", "png", "jpg", "original"][i])
	_barra.add_child(fmt)
	_barra.add_child(_mk(" Botón", "➕", _nuevo_boton_texto, "Agrega un botón con texto"))
	_barra.add_child(_mk(" Botón con dibujo", "🖼", _nuevo_boton_imagen, "Agrega un botón con tu propia imagen"))
	_tit = LineEdit.new()
	_tit.placeholder_text = "Título del juego"
	_tit.custom_minimum_size = Vector2(220, 44)
	_tit.text_changed.connect(func(t): _p()["titulo"] = t; cambio.emit())
	_barra.add_child(_tit)
	var col := ColorPickerButton.new()
	col.custom_minimum_size = Vector2(60, 44)
	col.color = Color(str(_p().get("color", "#6f4ad8")))
	col.tooltip_text = "Color de fondo (si no hay imagen)"
	col.color_changed.connect(func(c): _p()["color"] = "#" + c.to_html(false); cambio.emit())
	_barra.add_child(col)


func _mk(txt: String, emoji: String, f: Callable, tip: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.icon = Datos.textura(emoji)
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 26)
	b.custom_minimum_size = Vector2(0, 44)
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = tip
	b.pressed.connect(f)
	return b


func refrescar() -> void:
	_tit.text = str(_p().get("titulo", ""))
	sel = -1
	queue_redraw()


func _construir_menu() -> void:
	_menu = PopupMenu.new()
	_sub_anim = PopupMenu.new()
	_sub_anim.name = "Animacion"
	_sub_acc = PopupMenu.new()
	_sub_acc.name = "Accion"
	_menu.add_child(_sub_anim)
	_menu.add_child(_sub_acc)
	for i in Datos.ANIMACIONES.size():
		_sub_anim.add_item(Datos.ANIMACIONES[i][1], i)
	for i in Datos.ACCIONES.size():
		_sub_acc.add_item(Datos.ACCIONES[i][1], i)
	_menu.add_submenu_item("Animación", "Animacion")
	_menu.add_submenu_item("Acción", "Accion")
	_menu.add_separator()
	_menu.add_item("Cambiar texto", 100)
	_menu.add_item("Borrar botón", 101)
	add_child(_menu)
	_sub_anim.id_pressed.connect(func(i):
		if sel >= 0: _botones()[sel]["anim"] = Datos.ANIMACIONES[i][0]; cambio.emit())
	_sub_acc.id_pressed.connect(func(i):
		if sel >= 0: _botones()[sel]["accion"] = Datos.ACCIONES[i][0]; cambio.emit())
	_menu.id_pressed.connect(func(i):
		if sel < 0: return
		if i == 101:
			_botones().remove_at(sel)
			sel = -1
			cambio.emit()
		elif i == 100:
			_pedir_texto())


func _pedir_texto() -> void:
	var d := AcceptDialog.new()
	d.title = "Texto del botón"
	var le := LineEdit.new()
	le.text = str(_botones()[sel]["txt"])
	le.custom_minimum_size = Vector2(260, 0)
	d.add_child(le)
	d.confirmed.connect(func():
		if sel >= 0 and sel < _botones().size():
			_botones()[sel]["txt"] = le.text
			cambio.emit()
		d.queue_free())
	add_child(d)
	d.popup_centered()


# ------------------------------------------------------------------ imágenes
func _dialogo(titulo: String, cb: Callable) -> void:
	var filtros := PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp;Imágenes"])
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		DisplayServer.file_dialog_show(titulo, "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, filtros, cb)
	else:
		aviso.emit("Este equipo no puede abrir el selector de archivos")


func _elegir_fondo() -> void:
	_dialogo("Elige la imagen de fondo", func(ok, rutas, _f):
		if ok and rutas.size() > 0:
			var id := convertir_e_importar(rutas[0], _formato)
			if id == "":
				aviso.emit("No pude leer esa imagen")
				return
			_p()["fondo"] = id
			cambio.emit()
			aviso.emit("Fondo puesto"))


func _nuevo_boton_texto() -> void:
	_botones().append({"txt": "Jugar", "img": "", "x": 0.5, "y": 0.5, "w": 0.4, "h": 0.1, "anim": "latir", "accion": "jugar"})
	sel = _botones().size() - 1
	cambio.emit()


func _nuevo_boton_imagen() -> void:
	_dialogo("Elige el dibujo del botón", func(ok, rutas, _f):
		if ok and rutas.size() > 0:
			var id := convertir_e_importar(rutas[0], _formato)
			if id == "":
				aviso.emit("No pude leer esa imagen")
				return
			_botones().append({"txt": "", "img": id, "x": 0.5, "y": 0.6, "w": 0.4, "h": 0.12, "anim": "flotar", "accion": "ninguna"})
			sel = _botones().size() - 1
			cambio.emit())


## Abre la imagen, la convierte (webp/png/jpg) y la guarda en «Mis cosas».
## Devuelve el id, o "" si falla. Si el motor no sabe guardar WebP usa PNG.
static func convertir_e_importar(ruta: String, formato: String) -> String:
	if formato == "original":
		return Importar.importar_archivo(ruta)
	var img := Image.load_from_file(ruta)
	if img == null or img.is_empty():
		return Importar.importar_archivo(ruta)
	if img.get_width() > 2048 or img.get_height() > 2048:
		var e := 2048.0 / maxf(img.get_width(), img.get_height())
		img.resize(int(img.get_width() * e), int(img.get_height() * e), Image.INTERPOLATE_LANCZOS)
	var base := ruta.get_file().get_basename()
	var tmp := OS.get_cache_dir().path_join(base + "." + formato)
	var err := ERR_UNAVAILABLE
	match formato:
		"webp":
			err = img.save_webp(tmp, false, 0.85)
			if err != OK:
				tmp = OS.get_cache_dir().path_join(base + ".png")
				err = img.save_png(tmp)
		"jpg":
			err = img.save_jpg(tmp, 0.9)
		_:
			err = img.save_png(tmp)
	if err != OK:
		return Importar.importar_archivo(ruta)
	var id := Importar.importar_archivo(tmp)
	DirAccess.remove_absolute(tmp)
	return id


# ------------------------------------------------------------------ dibujo
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.1, 0.28))
	var m := marco()
	var fondo := str(_p().get("fondo", ""))
	var tex: Texture2D = Datos.textura(fondo) if fondo != "" else null
	if tex:
		draw_texture_rect(tex, m, false)
	else:
		draw_rect(m, Color(str(_p().get("color", "#6f4ad8"))))
	var fuente := ThemeDB.fallback_font
	var tit := str(_p().get("titulo", ""))
	if tit != "":
		var fs := int(m.size.y * 0.09)
		draw_string_outline(fuente, Vector2(m.position.x, m.position.y + m.size.y * 0.22), tit, HORIZONTAL_ALIGNMENT_CENTER, m.size.x, fs, 8, Color(0.1, 0.08, 0.3, 0.9))
		draw_string(fuente, Vector2(m.position.x, m.position.y + m.size.y * 0.22), tit, HORIZONTAL_ALIGNMENT_CENTER, m.size.x, fs, Color.WHITE)
	for i in _botones().size():
		var b: Dictionary = _botones()[i]
		var r := _rect_boton(b, m)
		r.position += anim_offset(str(b["anim"]), _t, r.size)
		dibujar_boton(self, b, r)
		if i == sel:
			draw_rect(r.grow(4), Estilo.AMARILLO, false, 3.0)
			draw_circle(r.end, 9.0, Color.WHITE)
			draw_arc(r.end, 9.0, 0, TAU, 16, Estilo.MORADO, 3.0)
	draw_rect(m, Color(1, 1, 1, 0.6), false, 2.0)
	var pie := "Portada · clic derecho en un botón para darle animación y acción"
	draw_string(fuente, Vector2(14, size.y - 8), pie, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.8))


static func anim_offset(a: String, t: float, s: Vector2) -> Vector2:
	match a:
		"flotar": return Vector2(0, sin(t * 2.0) * s.y * 0.12)
		"balancear": return Vector2(sin(t * 2.5) * s.x * 0.04, 0)
		"rebotar": return Vector2(0, -absf(sin(t * 3.0)) * s.y * 0.3)
	return Vector2.ZERO


## Dibuja un botón de portada (usado por el editor y por el juego).
static func dibujar_boton(ci: CanvasItem, b: Dictionary, r: Rect2, t: float = 0.0) -> void:
	var a := str(b.get("anim", "ninguna"))
	if a == "latir":
		var k := 1.0 + sin(Time.get_ticks_msec() / 1000.0 * 3.0) * 0.06
		r = Rect2(r.get_center() - r.size * k / 2.0, r.size * k)
	var img := str(b.get("img", ""))
	var tex: Texture2D = Datos.textura(img) if img != "" else null
	var mod := Color.WHITE
	if a == "brillar":
		var l := 0.85 + 0.25 * sin(Time.get_ticks_msec() / 1000.0 * 4.0)
		mod = Color(l, l, l)
	if tex:
		ci.draw_texture_rect(tex, r, false, mod)
	else:
		var c := Color("ffc93c") * mod
		c.a = 1.0
		ci.draw_rect(r, c)
		ci.draw_rect(r, Color("4a3300"), false, 3.0)
	var txt := str(b.get("txt", ""))
	if txt != "":
		var fs := int(clampf(r.size.y * 0.5, 12, 60))
		ci.draw_string(ThemeDB.fallback_font, Vector2(r.position.x, r.get_center().y + fs * 0.35), txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, Color("4a3300") if tex == null else Color.WHITE)


# ------------------------------------------------------------------ ratón
func _gui_input(ev: InputEvent) -> void:
	var m := marco()
	if ev is InputEventMouseButton:
		if ev.pressed:
			var hit := -1
			for i in range(_botones().size() - 1, -1, -1):
				if _rect_boton(_botones()[i], m).grow(6).has_point(ev.position):
					hit = i
					break
			sel = hit
			if hit >= 0 and ev.button_index == MOUSE_BUTTON_RIGHT:
				_menu.popup(Rect2i(Vector2i(get_global_mouse_position()), Vector2i.ZERO))
			elif hit >= 0 and ev.button_index == MOUSE_BUTTON_LEFT:
				var r := _rect_boton(_botones()[hit], m)
				if ev.position.distance_to(r.end) < 16.0:
					_arrastre = "tam"
				else:
					_arrastre = "mover"
					_off = ev.position - (r.position + r.size / 2.0)
		else:
			if _arrastre != "":
				cambio.emit()
			_arrastre = ""
	elif ev is InputEventMouseMotion and _arrastre != "" and sel >= 0:
		var b: Dictionary = _botones()[sel]
		if _arrastre == "mover":
			var c: Vector2 = ev.position - _off
			b["x"] = clampf((c.x - m.position.x) / m.size.x, 0.0, 1.0)
			b["y"] = clampf((c.y - m.position.y) / m.size.y, 0.0, 1.0)
		else:
			var ctr := m.position + Vector2(b["x"] * m.size.x, b["y"] * m.size.y)
			b["w"] = clampf(absf(ev.position.x - ctr.x) * 2.0 / m.size.x, 0.05, 1.0)
			b["h"] = clampf(absf(ev.position.y - ctr.y) * 2.0 / m.size.y, 0.03, 1.0)
