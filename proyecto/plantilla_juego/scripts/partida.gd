extends Control
## Maneja una partida completa: pantalla de título, los niveles uno tras otro,
## «siguiente nivel», reintentar y la pantalla final. Se usa tanto al probar
## dentro del creador como en el juego exportado.

signal salir

const Estilo := preload("res://scripts/estilo.gd")
const Importar := preload("res://scripts/importar.gd")
const Dibujo := preload("res://scripts/dibujo.gd")
const Juego := preload("res://scripts/juego.gd")
const Juego25 := preload("res://scripts/juego25.gd")
const Juego3D := preload("res://scripts/juego3d.gd")
const JuegoAventura := preload("res://scripts/juego_aventura.gd")
const JuegoArriba := preload("res://scripts/juego_arriba.gd")
const Tienda := preload("res://scripts/tienda.gd")
const JuegoCarrera := preload("res://scripts/juego_carrera.gd")
const JuegoPelea := preload("res://scripts/juego_pelea.gd")
const Rendimiento := preload("res://scripts/rendimiento.gd")
const PortadaEd := preload("res://scripts/portada_editor.gd")

var proy: Dictionary = {}
var idx := 0
var con_salir := false
var tactil := false
var puntos_acum := 0
var _juego: Control
var _panel: Control
var _titulo: Control
var _t := 0.0
var _tema: Dictionary = {}
var _musica: AudioStreamPlayer


## Qué clase de juego corresponde a este nivel.
static func clase_para(n: Dictionary) -> GDScript:
	var modo := str(n.get("modo", "2d"))
	if modo == "3d" and str(n.get("tipo", "")) == "aventura":
		return JuegoAventura
	var est := str(n.get("estilo", ""))
	if modo == "2d" and str(n.get("tipo", "")) == "arriba":
		return JuegoCarrera if est in ["carrera", "kart"] else JuegoArriba
	if modo == "2d" and est == "pelea":
		return JuegoPelea
	return {"25d": Juego25, "3d": Juego3D}.get(modo, Juego)


func iniciar(p: Dictionary, desde: int = 0, con_titulo: bool = true, forzar_tactil: bool = false, mostrar_salir: bool = false) -> void:
	if size.x < 10.0:
		await get_tree().process_frame   # esperar a que el contenedor nos dé tamaño
	proy = p
	idx = clampi(desde, 0, proy["niveles"].size() - 1)
	tactil = forzar_tactil
	con_salir = mostrar_salir
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tema = Datos.temas.get(str(proy["niveles"][0].get("theme", "dia")), Datos.temas["dia"])
	_iniciar_musica()
	if con_titulo and bool(proy["reglas"]["titulo"]):
		_mostrar_titulo()
	else:
		_empezar(idx)


func _iniciar_musica() -> void:
	var id := str(proy["reglas"].get("musica", ""))
	if id == "":
		return
	var st := Importar.cargar_audio(id)
	if st == null:
		return
	_musica = AudioStreamPlayer.new()
	_musica.stream = st
	_musica.volume_db = -6.0
	add_child(_musica)
	_musica.play()


func _process(dt: float) -> void:
	_t += dt
	if _musica and _juego and "_sonido" in _juego and _juego._sonido:
		_musica.stream_paused = _juego._sonido.silencio
	if _titulo:
		_titulo.queue_redraw()


func _limpiar() -> void:
	if _juego:
		_juego.queue_free()
		_juego = null
	if _panel:
		_panel.queue_free()
		_panel = null
	if _titulo:
		_titulo.queue_free()
		_titulo = null


# ------------------------------------------------------------------ título
## Portada hecha por el usuario (fondo + botones con animación y acción).
func _mostrar_portada_propia(n: Dictionary, p: Dictionary) -> void:
	var cv := Control.new()
	_titulo = cv
	add_child(cv)
	cv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vertical: bool = str(n.get("orient", "horizontal")) == "vertical"
	var ratio := 9.0 / 16.0 if vertical else 16.0 / 9.0
	cv.draw.connect(func():
		cv.draw_rect(Rect2(Vector2.ZERO, cv.size), Color.BLACK)
		var w := cv.size.x
		var h := w / ratio
		if h > cv.size.y:
			h = cv.size.y
			w = h * ratio
		var m := Rect2((cv.size - Vector2(w, h)) / 2.0, Vector2(w, h))
		var tex: Texture2D = Datos.textura(str(p["fondo"])) if str(p["fondo"]) != "" else null
		if tex:
			cv.draw_texture_rect(tex, m, false)
		else:
			cv.draw_rect(m, Color(str(p["color"])))
		var tit := str(p["titulo"])
		if tit != "":
			var fs := int(m.size.y * 0.09)
			var pos := Vector2(m.position.x, m.position.y + m.size.y * 0.22)
			cv.draw_string_outline(ThemeDB.fallback_font, pos, tit, HORIZONTAL_ALIGNMENT_CENTER, m.size.x, fs, 8, Color(0.1, 0.08, 0.3, 0.9))
			cv.draw_string(ThemeDB.fallback_font, pos, tit, HORIZONTAL_ALIGNMENT_CENTER, m.size.x, fs, Color.WHITE)
		var tt := Time.get_ticks_msec() / 1000.0
		for b in p["botones"]:
			var s := Vector2(b["w"] * m.size.x, b["h"] * m.size.y)
			var r := Rect2(m.position + Vector2(b["x"] * m.size.x, b["y"] * m.size.y) - s / 2.0, s)
			r.position += PortadaEd.anim_offset(str(b["anim"]), tt, r.size)
			PortadaEd.dibujar_boton(cv, b, r))
	cv.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var w := cv.size.x
			var h := w / ratio
			if h > cv.size.y:
				h = cv.size.y
				w = h * ratio
			var m := Rect2((cv.size - Vector2(w, h)) / 2.0, Vector2(w, h))
			for b in p["botones"]:
				var s := Vector2(b["w"] * m.size.x, b["h"] * m.size.y)
				var r := Rect2(m.position + Vector2(b["x"] * m.size.x, b["y"] * m.size.y) - s / 2.0, s)
				if r.has_point(ev.position):
					_accion_portada(str(b["accion"]))
					return)
	var t := Timer.new()
	t.wait_time = 0.03
	t.timeout.connect(func(): cv.queue_redraw())
	cv.add_child(t)
	t.start()
	if con_salir:
		var e := Button.new()
		e.text = "  Editar"
		e.icon = Datos.textura("↩")
		e.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		e.offset_left = -140.0
		e.offset_right = -15.0
		e.offset_top = 10.0
		e.offset_bottom = 56.0
		e.pressed.connect(func(): salir.emit())
		cv.add_child(e)


func _accion_portada(a: String) -> void:
	var n: int = proy["niveles"].size()
	var multi: bool = (proy["reglas"].get("jugables", []) as Array).size() > 1
	if a == "jugar":
		if multi:
			_mostrar_personajes()
		else:
			_empezar(0)
	elif a == "personajes":
		if multi:
			_mostrar_personajes()
		else:
			_empezar(0)
	elif a == "tienda":
		_mostrar_tienda()
	elif a.begins_with("mundo:"):
		_empezar(clampi(int(a.substr(6)) - 1, 0, n - 1))
	elif a == "salir":
		salir.emit()


func _mostrar_titulo() -> void:
	_limpiar()
	var n: Dictionary = proy["niveles"][0]
	var pp: Dictionary = Datos.portada_normal(proy["reglas"].get("portada", {}))
	if (pp["botones"] as Array).size() > 0 or str(pp["fondo"]) != "":
		_mostrar_portada_propia(n, pp)
		return
	_titulo = Control.new()
	_titulo.draw.connect(func(): Dibujo.fondo_de(_titulo, n, _tema, _titulo.size, _t * 30.0, _t))
	add_child(_titulo)
	_titulo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	_titulo.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 14)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_child(caja)
	var tex: Texture2D = Datos.textura(str(n.get("hero", "🎮")))
	if tex == null:
		tex = Datos.textura("🎮")
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(150, 150)
	caja.add_child(tr)
	var l1 := Label.new()
	l1.text = str(n.get("name", "Mi juego"))
	l1.add_theme_font_size_override("font_size", 48)
	l1.add_theme_color_override("font_color", Color.WHITE)
	l1.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.3, 0.85))
	l1.add_theme_constant_override("outline_size", 10)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l1.custom_minimum_size = Vector2(minf(560.0, maxf(260.0, size.x - 60.0)), 0)
	caja.add_child(l1)
	var cant: int = proy["niveles"].size()
	if cant > 1:
		var l2 := Label.new()
		l2.text = "%d niveles" % cant
		l2.add_theme_font_size_override("font_size", 22)
		l2.add_theme_color_override("font_color", Color.WHITE)
		l2.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.3, 0.85))
		l2.add_theme_constant_override("outline_size", 6)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caja.add_child(l2)
	var b := Button.new()
	b.text = "  ¡Jugar!"
	b.icon = Datos.textura("▶")
	b.custom_minimum_size = Vector2(260, 64)
	b.add_theme_font_size_override("font_size", 28)
	Estilo.pintar(b, Estilo.AMARILLO, Color("4a3300"))
	b.pressed.connect(func(): _empezar(idx))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.add_child(b)
	if (proy["reglas"].get("jugables", []) as Array).size() > 1:
		var bp := Button.new()
		bp.text = "  Elegir dinosaurio"
		bp.icon = Datos.textura("🦖")
		bp.custom_minimum_size = Vector2(260, 54)
		bp.expand_icon = true
		bp.add_theme_constant_override("icon_max_width", 32)
		bp.add_theme_font_size_override("font_size", 22)
		Estilo.pintar(bp, Color(1, 1, 1, 0.3), Color.WHITE)
		bp.pressed.connect(_mostrar_personajes)
		bp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		caja.add_child(bp)
	if bool(proy["reglas"].get("tienda", false)) and (proy["reglas"].get("catalogo", []) as Array).size() > 0:
		var bt := Button.new()
		bt.text = "  Tienda de mascotas"
		bt.icon = Datos.textura("🛒")
		bt.custom_minimum_size = Vector2(260, 54)
		bt.add_theme_font_size_override("font_size", 22)
		Estilo.pintar(bt, Color(1, 1, 1, 0.3), Color.WHITE)
		bt.pressed.connect(_mostrar_tienda)
		bt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		caja.add_child(bt)
	if con_salir:
		var e := Button.new()
		e.text = "  Editar"
		e.icon = Datos.textura("↩")
		e.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		e.offset_left = -140.0
		e.offset_right = -15.0
		e.offset_top = 10.0
		e.offset_bottom = 56.0
		e.pressed.connect(func(): salir.emit())
		_titulo.add_child(e)
	b.grab_focus()


# ------------------------------------------------------------------ niveles
func _empezar(i: int) -> void:
	_limpiar()
	idx = i
	var n: Dictionary = (proy["niveles"][idx] as Dictionary).duplicate(true)
	n["reglas"] = Tienda.reglas_con_mascota(proy["reglas"])
	var pj := Tienda.personaje(proy["reglas"])
	if not pj.is_empty():
		n["hero"] = str(pj["id"])
	Rendimiento.aplicar(get_viewport(), proy["reglas"].get("rend", {}))
	var j: Control = clase_para(n).new()
	add_child(j)
	j.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	j.campana = true
	j.puntos_base = puntos_acum
	var cant: int = proy["niveles"].size()
	j.etiqueta_nivel = "Nivel %d de %d" % [idx + 1, cant] if cant > 1 else ""
	j.salir.connect(func(): salir.emit())
	j.nivel_terminado.connect(_al_terminar.bind(j))
	j.iniciar(n, tactil, con_salir)
	_juego = j


func _al_terminar(gano: bool, icono: String, titulo: String, sub: String, j: Control) -> void:
	var cant: int = proy["niveles"].size()
	if bool(proy["reglas"].get("tienda", false)):
		var ganadas := maxi(0, j.puntos - j.puntos_base)
		Tienda.ganar(ganadas)
		if ganadas > 0:
			sub += "  ·  +%d monedas" % ganadas
	var botones: Array = []
	if gano:
		puntos_acum = j.puntos
		if idx < cant - 1:
			icono = "🎉"
			titulo = "¡Nivel %d completado!" % (idx + 1)
			sub = "Puntos: %d" % puntos_acum
			botones.append(["Siguiente nivel", "▶", func(): _empezar(idx + 1), true])
		else:
			icono = "🏆"
			titulo = str(proy["reglas"]["final"])
			sub = "Puntos: %d" % puntos_acum
			botones.append(["Jugar otra vez", "🔁", _reiniciar, true])
	else:
		botones.append(["Reintentar", "🔁", func(): _empezar(idx), true])
		if cant > 1 or bool(proy["reglas"]["titulo"]):
			botones.append(["Volver al inicio", "🏠", _reiniciar, false])
	_mostrar_panel(icono, titulo, sub, botones)


func _reiniciar() -> void:
	puntos_acum = 0
	if bool(proy["reglas"]["titulo"]):
		idx = 0
		_mostrar_titulo()
	else:
		_empezar(0)


func _mostrar_panel(icono: String, titulo: String, sub: String, botones: Array) -> void:
	if _panel:
		_panel.queue_free()
	var fondo := ColorRect.new()
	fondo.color = Color(0.08, 0.06, 0.23, 0.62)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = fondo
	var centro := CenterContainer.new()
	fondo.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	centro.add_child(caja)
	var tr := TextureRect.new()
	tr.texture = Datos.textura(icono)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(110, 110)
	caja.add_child(tr)
	var ancho := minf(560.0, maxf(240.0, size.x - 40.0))
	for par in [[titulo, 36, 1.0], [sub, 22, 0.9]]:
		var l := Label.new()
		l.text = par[0]
		l.add_theme_font_size_override("font_size", par[1])
		l.add_theme_color_override("font_color", Color(1, 1, 1, par[2]))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(ancho, 0)
		caja.add_child(l)
	for bd in botones:
		var b := Button.new()
		b.text = "  " + bd[0]
		b.icon = Datos.textura(bd[1])
		b.custom_minimum_size = Vector2(260, 58)
		b.add_theme_font_size_override("font_size", 24)
		if bd[3]:
			Estilo.pintar(b, Estilo.AMARILLO, Color("4a3300"))
		else:
			Estilo.pintar(b, Color(1, 1, 1, 0.25), Color.WHITE)
		b.pressed.connect(bd[2])
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		caja.add_child(b)
	if botones.size() > 0:
		(caja.get_child(caja.get_child_count() - botones.size()) as Control).grab_focus()


# ------------------------------------------------------------------ tienda
func _mostrar_tienda() -> void:
	if _titulo:
		_titulo.queue_free()
		_titulo = null
	if _panel:
		_panel.queue_free()
	var fondo := ColorRect.new()
	fondo.color = Color(0.12, 0.09, 0.32, 1.0)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = fondo
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	fondo.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(caja)
	var d := Tienda.leer()
	var tit := Label.new()
	tit.text = "Tienda de mascotas     Tus monedas: %d" % int(d["monedas"])
	tit.add_theme_font_size_override("font_size", 30)
	tit.add_theme_color_override("font_color", Color.WHITE)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.custom_minimum_size = Vector2(0, 70)
	tit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caja.add_child(tit)
	var rejilla := HFlowContainer.new()
	rejilla.alignment = FlowContainer.ALIGNMENT_CENTER
	rejilla.add_theme_constant_override("h_separation", 14)
	rejilla.add_theme_constant_override("v_separation", 14)
	rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_child(rejilla)
	for it in proy["reglas"]["catalogo"]:
		var tengo: bool = (d["tengo"] as Array).has(it["id"])
		var elegida: bool = str(d["elegida"]) == str(it["id"])
		var tarjeta := PanelContainer.new()
		tarjeta.custom_minimum_size = Vector2(190, 280)
		tarjeta.add_theme_stylebox_override("panel", Estilo.caja(Color(1, 1, 1, 0.95 if elegida else 0.85), 20, 4 if elegida else 0, Estilo.VERDE, 10))
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 4)
		tarjeta.add_child(v)
		var im := TextureRect.new()
		im.texture = Datos.textura(str(it["id"]))
		im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		im.custom_minimum_size = Vector2(0, 90)
		v.add_child(im)
		for par in [[str(it["n"]), 20, Estilo.TINTA], [str(it.get("desc", "")) if str(it.get("desc", "")) != "" else "Poder: " + str(Tienda.NOMBRE_PODER.get(it["poder"], "")), 14, Estilo.SUAVE]]:
			var l := Label.new()
			l.text = par[0]
			l.add_theme_font_size_override("font_size", par[1])
			l.add_theme_color_override("font_color", par[2])
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(l)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 44)
		if elegida:
			b.text = "Elegida"
			b.disabled = true
		elif tengo:
			b.text = "Elegir"
			b.pressed.connect(func():
				Tienda.elegir(str(it["id"]))
				_mostrar_tienda())
		else:
			b.text = "Comprar · %d" % int(it["precio"])
			b.disabled = int(d["monedas"]) < int(it["precio"])
			b.pressed.connect(func():
				Tienda.comprar(it)
				_mostrar_tienda())
		v.add_child(b)
		rejilla.add_child(tarjeta)
	var volver := Button.new()
	volver.text = "  Volver"
	volver.icon = Datos.textura("↩")
	volver.custom_minimum_size = Vector2(240, 56)
	volver.expand_icon = true
	volver.add_theme_constant_override("icon_max_width", 32)
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volver.add_theme_font_size_override("font_size", 22)
	Estilo.pintar(volver, Estilo.AMARILLO, Color("4a3300"))
	volver.pressed.connect(func():
		_mostrar_titulo())
	caja.add_child(volver)


# ------------------------------------------------------------------ elegir personaje jugable
func _mostrar_personajes() -> void:
	if _titulo:
		_titulo.queue_free()
		_titulo = null
	if _panel:
		_panel.queue_free()
	var fondo := ColorRect.new()
	fondo.color = Color(0.12, 0.09, 0.32, 1.0)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = fondo
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	fondo.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(caja)
	var tit := Label.new()
	tit.text = "¿Con qué dinosaurio quieres correr?"
	tit.add_theme_font_size_override("font_size", 30)
	tit.add_theme_color_override("font_color", Color.WHITE)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.custom_minimum_size = Vector2(0, 70)
	tit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caja.add_child(tit)
	var rejilla := HFlowContainer.new()
	rejilla.alignment = FlowContainer.ALIGNMENT_CENTER
	rejilla.add_theme_constant_override("h_separation", 14)
	rejilla.add_theme_constant_override("v_separation", 14)
	rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_child(rejilla)
	var actual := str(Tienda.personaje(proy["reglas"]).get("id", ""))
	for it in proy["reglas"]["jugables"]:
		var elegido: bool = actual == str(it["id"])
		var tarjeta := PanelContainer.new()
		tarjeta.custom_minimum_size = Vector2(200, 270)
		tarjeta.add_theme_stylebox_override("panel", Estilo.caja(Color(1, 1, 1, 0.95 if elegido else 0.85), 20, 4 if elegido else 0, Estilo.VERDE, 10))
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 4)
		tarjeta.add_child(v)
		var im := TextureRect.new()
		im.texture = Datos.textura(str(it["id"]))
		im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		im.custom_minimum_size = Vector2(0, 100)
		v.add_child(im)
		for par in [[str(it["n"]), 22, Estilo.TINTA], [str(it.get("desc", "")), 14, Estilo.SUAVE]]:
			var l := Label.new()
			l.text = par[0]
			l.add_theme_font_size_override("font_size", par[1])
			l.add_theme_color_override("font_color", par[2])
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(l)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 44)
		b.text = "Elegido" if elegido else "Elegir"
		b.disabled = elegido
		b.pressed.connect(func():
			Tienda.elegir_personaje(str(it["id"]))
			_mostrar_personajes())
		v.add_child(b)
		rejilla.add_child(tarjeta)
	var volver := Button.new()
	volver.text = "  Volver"
	volver.icon = Datos.textura("↩")
	volver.custom_minimum_size = Vector2(240, 56)
	volver.expand_icon = true
	volver.add_theme_constant_override("icon_max_width", 32)
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volver.add_theme_font_size_override("font_size", 22)
	Estilo.pintar(volver, Estilo.AMARILLO, Color("4a3300"))
	volver.pressed.connect(func(): _mostrar_titulo())
	caja.add_child(volver)
