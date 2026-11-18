extends Control
## El creador: barra superior, biblioteca (personajes, fondos, objetos,
## decoración), escenario, tutorial y exportación con el botón mágico.

const Estilo := preload("res://scripts/estilo.gd")
const Escenario := preload("res://scripts/escenario.gd")
const Ficha := preload("res://scripts/ficha.gd")
const Tutorial := preload("res://scripts/tutorial.gd")
const Juego := preload("res://scripts/juego.gd")
const Juego25 := preload("res://scripts/juego25.gd")
const Juego3D := preload("res://scripts/juego3d.gd")
const JuegoAventura := preload("res://scripts/juego_aventura.gd")

signal volver
signal reabrir
const ExportadorScript := preload("res://scripts/exportador.gd")
const Assets3D := preload("res://scripts/assets3d.gd")
const Importar := preload("res://scripts/importar.gd")
const Partida := preload("res://scripts/partida.gd")

var tab := "pers"
var _esc: Control
var _rejilla: GridContainer
var _tabs := {}
var _nombre: LineEdit
var _btn_undo: Button
var _btn_redo: Button
var _t_mover: Button
var _t_borrar: Button
var _largo: OptionButton
var _chip_caja: CenterContainer
var _chip_txt: Label
var _props_caja: CenterContainer
var _props_fila: HBoxContainer
var _aviso_caja: CenterContainer
var _aviso_txt: Label
var _aviso_tween: Tween
var _tut: Control
var _exp: Node
var _jugando: Control
var _modal: Control
var _estado_exp: Label
var _botones_exp: Array[Button] = []
var _objetivos := {}
var _ajustes := ConfigFile.new()
var _construido := false
var _titulo: Label
var _modo_txt: Label
var _niveles_fila: HFlowContainer
var _borrar_pend := false
var _modal_es_reglas := false
var _prev_audio: AudioStreamPlayer
var _prev_id := ""
var modo := "2d"
var _textos_barra: Array = []


func _clave_tutorial() -> String:
	return "visto" if modo == "2d" else "visto_" + modo


func _ready() -> void:
	modo = str(Datos.nivel.get("modo", "2d"))
	_exp = ExportadorScript.new()
	add_child(_exp)
	_exp.terminado.connect(_al_exportar)
	_construir()
	Datos.nivel_cambiado.connect(_refrescar)
	_cambiar_tab("pers")
	_refrescar()
	_ajustes.load("user://ajustes.cfg")
	if not bool(_ajustes.get_value("tutorial", _clave_tutorial(), false)):
		await get_tree().create_timer(0.8).timeout
		_iniciar_tutorial()


# ------------------------------------------------------------------ construcción
func _boton(texto: String, emoji: String = "", fondo: Variant = null, tinta: Color = Color.WHITE, ancho: float = 0.0) -> Button:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	if emoji != "":
		b.icon = Datos.textura(emoji)
	if fondo != null:
		Estilo.pintar(b, fondo, tinta)
	b.custom_minimum_size = Vector2(ancho, 46)
	return b


func _marcar(b: Button, activo: bool) -> void:
	if activo:
		Estilo.pintar(b, Estilo.MORADO)
	else:
		for n in ["normal", "hover", "pressed", "disabled"]:
			b.remove_theme_stylebox_override(n)
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			b.remove_theme_color_override(c)


func _construir() -> void:
	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 0)
	add_child(raiz)
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# ---------------- barra superior
	var barra := PanelContainer.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Estilo.TURQUESA, Estilo.MORADO])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	gt.width = 256
	gt.height = 8
	var st := StyleBoxTexture.new()
	st.texture = gt
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	barra.add_theme_stylebox_override("panel", st)
	raiz.add_child(barra)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	barra.add_child(fila)
	var logo := TextureRect.new()
	logo.texture = Datos.textura("🎮")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(40, 40)
	fila.add_child(logo)
	var titulo := Label.new()
	titulo.text = "Atrapa Juegos Studio"
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.add_theme_color_override("font_color", Color.WHITE)
	fila.add_child(titulo)
	_titulo = titulo
	_modo_txt = Label.new()
	var nombre_modo: String = {"2d": "Vista desde arriba" if str(Datos.nivel.get("tipo", "")) == "arriba" else "Plataformas 2D", "25d": "Plataformas 2.5D", "3d": "Corredor 3D" if Datos.tipo_3d() == "corredor" else "Aventura 3D"}.get(modo, "")
	_modo_txt.text = "· %s · %s · %s" % [nombre_modo, "Celular" if Datos.nivel.get("disp", "pc") == "movil" else "PC", "Vertical" if Datos.nivel.get("orient", "horizontal") == "vertical" else "Horizontal"]
	_modo_txt.add_theme_font_size_override("font_size", 20)
	_modo_txt.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	fila.add_child(_modo_txt)
	_nombre = LineEdit.new()
	_nombre.placeholder_text = "Nombre de tu juego"
	_nombre.custom_minimum_size = Vector2(250, 46)
	_nombre.max_length = 40
	_nombre.text_changed.connect(func(t: String): Datos.nivel["name"] = t)
	_nombre.text_submitted.connect(func(_t: String): Datos.confirmar(); _nombre.release_focus())
	_nombre.focus_exited.connect(Datos.confirmar)
	fila.add_child(_nombre)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(sp)
	var c_claro := Color(1, 1, 1, 0.2)
	var b_inicio := _boton(" Inicio", "🏠", c_claro)
	b_inicio.pressed.connect(func(): volver.emit())
	fila.add_child(b_inicio)
	_textos_barra.append([b_inicio, " Inicio"])
	var b_tipo := _boton(" Tipo de juego", "🎮", c_claro)
	b_tipo.pressed.connect(_abrir_tipos)
	fila.add_child(b_tipo)
	_textos_barra.append([b_tipo, " Tipo de juego"])
	var b_nuevo := _boton(" Nuevo", "📄", c_claro)
	b_nuevo.pressed.connect(_nuevo)
	fila.add_child(b_nuevo)
	_textos_barra.append([b_nuevo, " Nuevo"])
	_btn_undo = _boton("", "↩", c_claro, Color.WHITE, 52)
	_btn_undo.tooltip_text = "Deshacer"
	_btn_undo.pressed.connect(func(): _esc.sel = null; Datos.deshacer())
	fila.add_child(_btn_undo)
	_btn_redo = _boton("", "↪", c_claro, Color.WHITE, 52)
	_btn_redo.tooltip_text = "Rehacer"
	_btn_redo.pressed.connect(func(): _esc.sel = null; Datos.rehacer())
	fila.add_child(_btn_redo)
	var b_ayuda := _boton(" Ayuda", "❓", c_claro)
	b_ayuda.pressed.connect(_iniciar_tutorial)
	fila.add_child(b_ayuda)
	_textos_barra.append([b_ayuda, " Ayuda"])
	var b_jugar := _boton(" ¡Jugar!", "▶", Estilo.VERDE, Color.WHITE, 130)
	b_jugar.add_theme_font_size_override("font_size", 22)
	b_jugar.pressed.connect(_jugar)
	fila.add_child(b_jugar)
	var b_exp := _boton(" Exportar", "🚀", Estilo.AMARILLO, Color("4a3300"), 140)
	b_exp.add_theme_font_size_override("font_size", 22)
	b_exp.pressed.connect(_abrir_exportar)
	fila.add_child(b_exp)
	_objetivos["btn_jugar"] = b_jugar
	_objetivos["btn_exportar"] = b_exp
	# ---------------- cuerpo
	var principal := HBoxContainer.new()
	principal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	principal.add_theme_constant_override("separation", 0)
	raiz.add_child(principal)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(350, 0)
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 0, 0, Color.TRANSPARENT, 10))
	principal.add_child(panel)
	_objetivos["biblioteca"] = panel
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var fila_tabs := HBoxContainer.new()
	fila_tabs.add_theme_constant_override("separation", 6)
	v.add_child(fila_tabs)
	for d in [["pers", "Personajes", "🐱"], ["fondos", "Fondos", "🖼"], ["objetos", "Objetos", "🧱"], ["deco", "Decorar", "🌳"], ["mis", "Mis cosas", "📁"]]:
		var b := Button.new()
		b.text = d[1]
		b.icon = Datos.textura(d[2])
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.custom_minimum_size = Vector2(0, 66)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 14)
		b.add_theme_constant_override("icon_max_width", 30)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_cambiar_tab.bind(d[0]))
		fila_tabs.add_child(b)
		_tabs[d[0]] = b
		_objetivos["tab_" + ("pers" if d[0] == "pers" else d[0])] = b
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_rejilla = GridContainer.new()
	_rejilla.columns = 3
	_rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rejilla.add_theme_constant_override("h_separation", 8)
	_rejilla.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_rejilla)
	# ---------------- escenario
	var zona := Control.new()
	zona.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zona.clip_contents = true
	principal.add_child(zona)
	_esc = Escenario.new()
	zona.add_child(_esc)
	_esc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_esc.agregado.connect(_al_agregar)
	_esc.seleccionado.connect(func(_i): _refrescar_props(); if _i != null: _tut.avisar("select"))
	_esc.cambio.connect(_refrescar_props)
	_objetivos["escenario"] = zona
	# herramientas
	var herr := HBoxContainer.new()
	herr.position = Vector2(12, 12)
	herr.add_theme_constant_override("separation", 6)
	zona.add_child(herr)
	_t_mover = _boton(" Mover", "✋")
	_t_mover.pressed.connect(func(): _usar_herramienta("mover"))
	herr.add_child(_t_mover)
	_t_borrar = _boton(" Borrar", "🧽")
	_t_borrar.pressed.connect(func(): _usar_herramienta("borrar"))
	herr.add_child(_t_borrar)
	var zmenos := _boton("", "➖", null, Color.WHITE, 46)
	zmenos.pressed.connect(func(): _esc.zoom = clampf(_esc.zoom - 0.2, 0.6, 1.8))
	herr.add_child(zmenos)
	var zmas := _boton("", "➕", null, Color.WHITE, 46)
	zmas.pressed.connect(func(): _esc.zoom = clampf(_esc.zoom + 0.2, 0.6, 1.8))
	herr.add_child(zmas)
	_largo = OptionButton.new()
	_largo.custom_minimum_size = Vector2(130, 46)
	_largo.add_item("Nivel corto", 0)
	_largo.add_item("Nivel medio", 1)
	_largo.add_item("Nivel largo", 2)
	_largo.focus_mode = Control.FOCUS_NONE
	_largo.item_selected.connect(_cambiar_largo)
	herr.add_child(_largo)
	_usar_herramienta("mover")
	# niveles del juego y reglas
	_niveles_fila = HFlowContainer.new()
	_niveles_fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_niveles_fila.add_theme_constant_override("h_separation", 6)
	_niveles_fila.add_theme_constant_override("v_separation", 4)
	zona.add_child(_niveles_fila)
	_niveles_fila.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_niveles_fila.offset_left = 12
	_niveles_fila.offset_right = -12
	_niveles_fila.offset_top = 64
	_objetivos["niveles"] = _niveles_fila
	# etiqueta "colocando..."
	_chip_caja = CenterContainer.new()
	_chip_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zona.add_child(_chip_caja)
	_chip_caja.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_chip_caja.offset_top = 118
	_chip_caja.offset_bottom = 168
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", Estilo.caja(Estilo.TINTA, 30, 0, Color.TRANSPARENT, 14))
	_chip_caja.add_child(chip)
	var chip_f := HBoxContainer.new()
	chip.add_child(chip_f)
	_chip_txt = Label.new()
	_chip_txt.add_theme_color_override("font_color", Color.WHITE)
	chip_f.add_child(_chip_txt)
	var listo := Button.new()
	listo.text = "Listo"
	listo.focus_mode = Control.FOCUS_NONE
	listo.pressed.connect(func(): _esc.stamp = {}; _refrescar_chip(); _marcar_fichas())
	chip_f.add_child(listo)
	# propiedades del objeto elegido
	_props_caja = CenterContainer.new()
	_props_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zona.add_child(_props_caja)
	_props_caja.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_props_caja.offset_top = -92
	_props_caja.offset_bottom = -14
	var pp := PanelContainer.new()
	pp.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 22, 0, Color.TRANSPARENT, 12))
	_props_caja.add_child(pp)
	_props_fila = HBoxContainer.new()
	_props_fila.add_theme_constant_override("separation", 10)
	pp.add_child(_props_fila)
	# avisos
	_aviso_caja = CenterContainer.new()
	_aviso_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aviso_caja.modulate.a = 0.0
	zona.add_child(_aviso_caja)
	_aviso_caja.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_aviso_caja.offset_top = -150
	_aviso_caja.offset_bottom = -104
	var ap := PanelContainer.new()
	ap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ap.add_theme_stylebox_override("panel", Estilo.caja(Estilo.TINTA, 30, 0, Color.TRANSPARENT, 16))
	_aviso_caja.add_child(ap)
	_aviso_txt = Label.new()
	_aviso_txt.add_theme_color_override("font_color", Color.WHITE)
	ap.add_child(_aviso_txt)
	# tutorial (siempre encima)
	_tut = Tutorial.new()
	add_child(_tut)
	_tut.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tut.objetivos = _objetivos
	if modo == "3d" and Datos.tipo_3d() == "corredor":
		_tut.pasos = _tut.PASOS_3D
	_construido = true
	resized.connect(_adaptar)
	_adaptar()


## En pantallas angostas la barra superior muestra solo íconos.
func _adaptar() -> void:
	# En celular la pantalla física es pequeña aunque el ancho lógico sea grande: también cuenta.
	var compacto := size.x < 1400.0 or float(get_window().size.x) < 1000.0
	_titulo.visible = not compacto
	_modo_txt.visible = size.x > 1250.0
	_nombre.custom_minimum_size.x = 150.0 if compacto else 250.0
	for par in _textos_barra:
		par[0].text = "" if compacto else par[1]
		par[0].custom_minimum_size.x = 52.0 if compacto else 0.0


# ------------------------------------------------------------------ biblioteca
func _defs(que: String) -> Array:
	var r: Array = []
	match que:
		"pers":
			r.append({"enc": "Personajes"})
			for h in Assets3D.PERSONAJES:
				r.append({"id": "ha:" + h[0], "n": h[1], "t": "hero", "e": "a:" + h[0]})
			if modo != "3d" or Datos.tipo_3d() == "aventura":
				r.append({"enc": "Enemigos"})
				for e in Assets3D.ENEMIGOS:
					r.append({"id": "ea:" + e[0], "n": e[1], "t": "enemy", "e": "a:" + e[0], "fly": e[2], "sp": e[3]})
			r.append({"enc": "Divertidos"})
			for h in Datos.heroes:
				r.append({"id": "h" + h[1], "n": h[0], "t": "hero", "e": h[1]})
			if modo != "3d" or Datos.tipo_3d() == "aventura":
				r.append({"enc": "Enemigos divertidos"})
				for e in Datos.enemigos:
					r.append({"id": "e" + e[1], "n": e[0], "t": "enemy", "e": e[1], "fly": e[2], "sp": e[3]})
		"fondos":
			for k in Datos.temas:
				r.append({"id": k, "n": Datos.temas[k]["n"], "t": "tema"})
			r.append({"enc": "Mis fondos"})
			r.append({"id": "importar", "n": "Importar…", "t": "importar"})
			var imgs := Importar.listar().filter(func(a): return str(a["id"]).begins_with("u:"))
			if not imgs.is_empty():
				r.append({"id": "fondo_ninguno", "n": "Del tema", "t": "fondo_img", "e": ""})
				for a in imgs:
					r.append({"id": "f" + a["id"], "n": a["n"], "t": "fondo_img", "e": a["id"]})
		"objetos":
			var lista := [["plat", "Plataforma"], ["coin", "Moneda"], ["star", "Estrella"], ["gem", "Gema"], ["spike", "Pinchos"], ["spring", "Resorte"], ["goal", "Meta"], ["player", "Inicio"]]
			if modo == "2d" and str(Datos.nivel.get("tipo", "")) == "arriba":
				lista = [["plat", "Pared"], ["coin", "Moneda"], ["star", "Estrella"], ["gem", "Gema"], ["spike", "Pinchos"], ["goal", "Meta"], ["player", "Inicio"]]
			elif modo == "3d" and Datos.tipo_3d() == "aventura":
				lista = [["plat", "Bloque"], ["coin", "Moneda"], ["star", "Estrella"], ["gem", "Gema"], ["spike", "Pinchos"], ["goal", "Meta"], ["player", "Inicio"]]
			elif modo == "3d":
				lista = [["valla", "Valla"], ["pared", "Pared"], ["viga", "Viga"], ["coin", "Moneda"], ["star", "Estrella"], ["gem", "Gema"], ["goal", "Meta"]]
			for d in lista:
				r.append({"id": d[0], "n": d[1], "t": d[0]})
		"deco":
			for cat in Assets3D.OBJETOS:
				r.append({"enc": cat})
				for o in Assets3D.OBJETOS[cat]:
					r.append({"id": "da:" + o[0], "n": o[1], "t": "deco", "e": "a:" + o[0], "s": Assets3D.cuadro_px(o[0])})
			r.append({"enc": "Divertidas"})
			for d in Datos.decoraciones:
				r.append({"id": "d" + d[1], "n": d[0], "t": "deco", "e": d[1], "s": d[2]})
		"mis":
			r.append({"id": "importar", "n": "Importar…", "t": "importar"})
			var mias := Importar.listar()
			var modelos_ok := modo != "2d"
			var util := mias.filter(func(a): return not Importar.es_audio(a["id"]) and (modelos_ok or not Importar.es_modelo(a["id"])))
			var sonidos := mias.filter(func(a): return Importar.es_audio(a["id"]))
			if not util.is_empty():
				r.append({"enc": "Como decoración"})
				for a in util:
					r.append({"id": "du" + a["id"], "n": a["n"], "t": "deco", "e": a["id"], "s": 64})
				r.append({"enc": "Como héroe"})
				for a in util:
					r.append({"id": "hu" + a["id"], "n": a["n"], "t": "hero", "e": a["id"]})
				r.append({"enc": "Como enemigo"})
				for a in util:
					r.append({"id": "eu" + a["id"], "n": a["n"], "t": "enemy", "e": a["id"], "fly": false, "sp": 60})
			if not sonidos.is_empty():
				r.append({"enc": "Música (toca para oírla; se elige en Reglas)"})
				for a in sonidos:
					r.append({"id": "au" + a["id"], "n": a["n"], "t": "audio", "e": a["id"]})
	return r


func _cambiar_tab(nombre: String) -> void:
	tab = nombre
	for k in _tabs:
		_marcar(_tabs[k], k == tab)
	_construir_biblioteca()
	_tut.avisar("tab:" + nombre)


func _relleno() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(98, 0)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


func _construir_biblioteca() -> void:
	for c in _rejilla.get_children():
		_rejilla.remove_child(c)
		c.queue_free()
	var n := 0
	var tactil := DisplayServer.is_touchscreen_available()
	for d in _defs(tab):
		if d.has("enc"):
			while n % 3 != 0:
				_rejilla.add_child(_relleno())
				n += 1
			var l := Label.new()
			l.text = d["enc"]
			l.add_theme_color_override("font_color", Estilo.SUAVE)
			l.add_theme_font_size_override("font_size", 16)
			_rejilla.add_child(l)
			_rejilla.add_child(_relleno())
			_rejilla.add_child(_relleno())
			n += 3
			continue
		var f := Ficha.new()
		_rejilla.add_child(f)
		f.configurar(d, not tactil)
		f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f.pressed.connect(_tocada.bind(d))
		n += 1
	_marcar_fichas()


func _es_marcada(d: Dictionary) -> bool:
	match d["t"]:
		"tema":
			return Datos.nivel["theme"] == d["id"]
		"hero":
			return Datos.nivel["hero"] == d["e"]
		"fondo_img":
			return str(Datos.nivel.get("fondo", "")) == d["e"]
	return _esc != null and _esc.stamp.get("id", "") == d["id"]


func _marcar_fichas() -> void:
	for f in _rejilla.get_children():
		if f is Button and f.get("def") != null:
			f.marcada = _es_marcada(f.def)


func _tocada(d: Dictionary) -> void:
	match d["t"]:
		"importar":
			_importar()
			return
		"fondo_img":
			if str(d["e"]) == "":
				Datos.nivel.erase("fondo")
			else:
				Datos.nivel["fondo"] = d["e"]
			Datos.confirmar()
			_aviso("Fondo cambiado")
			return
		"audio":
			_probar_audio(str(d["e"]))
			return
		"tema":
			Datos.nivel.erase("fondo")
			Datos.nivel["theme"] = d["id"]
			Datos.confirmar()
			_tut.avisar("tema")
		"hero":
			Datos.nivel["hero"] = d["e"]
			Datos.confirmar()
			_aviso("Tu héroe es: " + d["n"])
			_tut.avisar("hero")
		_:
			if _esc.stamp.get("id", "") == d["id"]:
				_esc.stamp = {}
			else:
				_esc.stamp = d
				_esc.sel = null
				_usar_herramienta("mover")
				var pista := {"valla": "Valla: el corredor la SALTA", "pared": "Pared: hay que ESQUIVARLA", "viga": "Viga: hay que AGACHARSE"}
				_aviso(pista.get(d["t"], "") if modo == "3d" and pista.has(d["t"]) else "Toca el escenario para poner: " + d["n"])
			_refrescar_chip()
			_refrescar_props()
	_marcar_fichas()


func _importar() -> void:
	var filtros := PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp,*.glb,*.gltf,*.ogg,*.mp3,*.wav;Dibujos, modelos 3D y música"])
	if modo == "2d":
		filtros = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp,*.ogg,*.mp3,*.wav;Dibujos y música"])
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		DisplayServer.file_dialog_show("Elige tus dibujos o modelos 3D", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILES, filtros, _al_elegir_archivos)
	else:
		_aviso("Este equipo no puede abrir el selector de archivos")


func _al_elegir_archivos(ok: bool, rutas: PackedStringArray, _f: int) -> void:
	if not ok:
		return
	var n := 0
	for r in rutas:
		n += await _incorporar(r)
	if _modal != null and _modal_es_reglas:
		_abrir_reglas()
	else:
		_cambiar_tab(tab)
	_aviso("Listo: %d cosas nuevas en Mis cosas" % n if n > 0 else "No pude leer ese archivo")


func _probar_audio(id: String) -> void:
	if _prev_audio == null:
		_prev_audio = AudioStreamPlayer.new()
		add_child(_prev_audio)
	if _prev_audio.playing and _prev_id == id:
		_prev_audio.stop()
		return
	var st := Importar.cargar_audio(id)
	if st == null:
		_aviso("No pude abrir ese sonido")
		return
	_prev_id = id
	_prev_audio.stream = st
	_prev_audio.play()


func _incorporar(ruta: String) -> int:
	var id := Importar.importar_archivo(ruta)
	if id == "":
		return 0
	if Importar.es_modelo(id):
		await Importar.hacer_miniatura(get_tree(), id)
	return 1


# ------------------------------------------------------------------ barra de herramientas
func _usar_herramienta(h: String) -> void:
	_esc.herramienta = h
	if h == "borrar":
		_esc.stamp = {}
		_esc.sel = null
		_refrescar_chip()
		_marcar_fichas()
	_marcar(_t_mover, h == "mover")
	_marcar(_t_borrar, h == "borrar")
	if _construido:
		_refrescar_props()


func _cambiar_largo(i: int) -> void:
	var cols: int = [30, 45, 60][i]
	Datos.nivel["cols"] = cols
	var resto: Array = []
	for it in Datos.nivel["items"]:
		if it["x"] < cols:
			if it["t"] == "plat":
				it["w"] = mini(it["w"], cols - it["x"])
			resto.append(it)
	Datos.nivel["items"] = resto
	Datos.confirmar()


# ------------------------------------------------------------------ niveles y reglas
func _refrescar_niveles() -> void:
	if _niveles_fila == null:
		return
	for c in _niveles_fila.get_children():
		_niveles_fila.remove_child(c)
		c.queue_free()
	var n := Datos.num_niveles()
	var et := Label.new()
	et.text = "Niveles:"
	et.add_theme_color_override("font_color", Estilo.TINTA)
	et.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	et.add_theme_constant_override("outline_size", 6)
	_niveles_fila.add_child(et)
	for i in n:
		var b := Button.new()
		b.text = str(i + 1)
		b.custom_minimum_size = Vector2(44, 40)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = "Nivel %d" % (i + 1)
		if i == Datos.idx:
			Estilo.pintar(b, Estilo.MORADO)
		b.pressed.connect(_ir_nivel.bind(i))
		_niveles_fila.add_child(b)
	var mas := _boton("", "➕", null, Color.WHITE, 44)
	mas.custom_minimum_size.y = 40
	mas.tooltip_text = "Nivel nuevo"
	mas.disabled = n >= Datos.MAX_NIVELES
	mas.pressed.connect(func(): _agregar_nivel(false))
	_niveles_fila.add_child(mas)
	var dup := _boton(" Copiar", "📄")
	dup.custom_minimum_size.y = 40
	dup.tooltip_text = "Duplicar este nivel"
	dup.disabled = n >= Datos.MAX_NIVELES
	dup.pressed.connect(func(): _agregar_nivel(true))
	_niveles_fila.add_child(dup)
	if n > 1:
		var del := _boton(" ¿Seguro?" if _borrar_pend else "", "🧽", Estilo.ROJO if _borrar_pend else null)
		del.custom_minimum_size = Vector2(44, 40)
		del.tooltip_text = "Borrar este nivel"
		del.pressed.connect(_borrar_nivel)
		_niveles_fila.add_child(del)
	var reg := _boton(" Reglas", "⚙", Estilo.TURQUESA)
	reg.custom_minimum_size.y = 40
	reg.tooltip_text = "Vidas, tiempo, puntos y más"
	reg.pressed.connect(_abrir_reglas)
	_niveles_fila.add_child(reg)


func _ir_nivel(i: int) -> void:
	_borrar_pend = false
	_esc.sel = null
	_esc.stamp = {}
	Datos.ir_a_nivel(i)
	_aviso("Nivel %d" % (Datos.idx + 1))


func _agregar_nivel(copiar: bool) -> void:
	_borrar_pend = false
	_esc.sel = null
	_esc.stamp = {}
	if Datos.agregar_nivel(copiar):
		_aviso("Nivel %d creado" % (Datos.idx + 1))
	else:
		_aviso("Máximo %d niveles" % Datos.MAX_NIVELES)


func _borrar_nivel() -> void:
	if not _borrar_pend:
		_borrar_pend = true
		_refrescar_niveles()
		get_tree().create_timer(3.0).timeout.connect(func():
			if _borrar_pend:
				_borrar_pend = false
				_refrescar_niveles())
		return
	_borrar_pend = false
	_esc.sel = null
	Datos.borrar_nivel()
	_aviso("Nivel borrado")


func _regla_fila(v: VBoxContainer, titulo: String, control: Control) -> void:
	var f := HBoxContainer.new()
	f.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = titulo
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_color_override("font_color", Estilo.TINTA)
	f.add_child(l)
	f.add_child(control)
	v.add_child(f)


func _regla_paso(clave: String, minv: int, maxv: int, paso: int, formato: Callable) -> HBoxContainer:
	var f := HBoxContainer.new()
	f.add_theme_constant_override("separation", 4)
	var lbl := Label.new()
	lbl.custom_minimum_size = Vector2(120, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Estilo.MORADO)
	lbl.text = formato.call(int(Datos.reglas[clave]))
	var cambiar := func(d: int):
		var nv := clampi(int(Datos.reglas[clave]) + d * paso, minv, maxv)
		Datos.reglas[clave] = nv
		lbl.text = formato.call(nv)
		Datos.guardar()
	var menos := _boton("", "➖", null, Color.WHITE, 46)
	menos.pressed.connect(func(): cambiar.call(-1))
	var mas := _boton("", "➕", null, Color.WHITE, 46)
	mas.pressed.connect(func(): cambiar.call(1))
	f.add_child(menos)
	f.add_child(lbl)
	f.add_child(mas)
	return f


## Botones tipo «elige uno»: opciones = [[valor, texto], ...]
func _regla_opciones(clave: String, opciones: Array, al_elegir: Callable = Callable()) -> HBoxContainer:
	var f := HBoxContainer.new()
	f.add_theme_constant_override("separation", 4)
	var botones: Array = []
	var pintar := func():
		for i in botones.size():
			_marcar(botones[i], Datos.reglas[clave] == opciones[i][0])
	for o in opciones:
		var b := _boton(o[1])
		botones.append(b)
		b.pressed.connect(func():
			Datos.reglas[clave] = o[0]
			if al_elegir.is_valid():
				al_elegir.call(o[0])
			Datos.guardar()
			pintar.call())
		f.add_child(b)
	pintar.call()
	return f


func _abrir_reglas() -> void:
	_cerrar_modal()
	Datos.reglas = Datos.reglas_completas(Datos.reglas)
	var fondo := ColorRect.new()
	fondo.color = Color(0.08, 0.06, 0.23, 0.62)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal = fondo
	_modal_es_reglas = true
	move_child(_tut, get_child_count() - 1)
	var centro := CenterContainer.new()
	fondo.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(640.0, size.x - 24.0), minf(660.0, size.y - 30.0))
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 26, 0, Color.TRANSPARENT, 22))
	centro.add_child(panel)
	var ext := VBoxContainer.new()
	ext.add_theme_constant_override("separation", 8)
	panel.add_child(ext)
	var tit := Label.new()
	tit.text = "Reglas de tu juego"
	tit.add_theme_font_size_override("font_size", 28)
	tit.add_theme_color_override("font_color", Estilo.TINTA)
	ext.add_child(tit)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ext.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	scroll.add_child(v)
	_regla_fila(v, "Vidas", _regla_paso("vidas", 1, 9, 1, func(x): return str(x)))
	_regla_fila(v, "Tiempo por nivel", _regla_paso("tiempo", 0, 900, 15, func(x): return "Sin límite" if x == 0 else "%d:%02d" % [x / 60, x % 60]))
	var ganar := Label.new()
	ganar.text = "Para ganar el nivel"
	ganar.add_theme_color_override("font_color", Estilo.TINTA)
	v.add_child(ganar)
	v.add_child(_regla_opciones("meta", [["meta", "Llegar a la meta"], ["mitad", "Recoger la mitad"], ["todo", "Recoger todo"]]))
	var pts := Label.new()
	pts.text = "Puntos que da cada cosa"
	pts.add_theme_color_override("font_color", Estilo.SUAVE)
	v.add_child(pts)
	var fmt := func(x): return str(x)
	_regla_fila(v, "Moneda", _regla_paso("pts_coin", 0, 99, 1, fmt))
	_regla_fila(v, "Gema", _regla_paso("pts_gem", 0, 99, 1, fmt))
	_regla_fila(v, "Estrella", _regla_paso("pts_star", 0, 99, 1, fmt))
	if not (modo == "3d" and Datos.tipo_3d() == "corredor") and str(Datos.nivel.get("tipo", "")) != "arriba":
		_regla_fila(v, "Enemigo derrotado", _regla_paso("pts_enemy", 0, 99, 1, fmt))
	_regla_fila(v, "Pantalla de título", _regla_opciones("titulo", [[true, "Sí"], [false, "No"]]))
	var musicas: Array = [{"id": "", "n": "Sin música"}]
	for a in Importar.listar():
		if Importar.es_audio(a["id"]):
			musicas.append(a)
	var pos_m := 0
	for i in musicas.size():
		if musicas[i]["id"] == str(Datos.reglas["musica"]):
			pos_m = i
	var ml := Label.new()
	ml.custom_minimum_size = Vector2(150, 0)
	ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ml.clip_text = true
	ml.add_theme_color_override("font_color", Estilo.MORADO)
	ml.text = musicas[pos_m]["n"]
	var mover_m := func(d: int):
		pos_m = posmod(pos_m + d, musicas.size())
		ml.text = musicas[pos_m]["n"]
		Datos.reglas["musica"] = musicas[pos_m]["id"]
		Datos.guardar()
	var mf := HBoxContainer.new()
	mf.add_theme_constant_override("separation", 4)
	var m_menos := _boton("", "⬅", null, Color.WHITE, 46)
	m_menos.pressed.connect(func(): mover_m.call(-1))
	var m_mas := _boton("", "➡", null, Color.WHITE, 46)
	m_mas.pressed.connect(func(): mover_m.call(1))
	mf.add_child(m_menos)
	mf.add_child(ml)
	mf.add_child(m_mas)
	_regla_fila(v, "Música de fondo", mf)
	var b_mus := _boton("  Importar música…", "📁")
	b_mus.pressed.connect(_importar)
	v.add_child(b_mus)
	# ---- mascota con poder
	var ml2 := Label.new()
	ml2.text = "Mascota que te acompaña y su poder"
	ml2.add_theme_color_override("font_color", Estilo.SUAVE)
	v.add_child(ml2)
	var mascotas: Array = [{"id": "", "n": "Sin mascota"}]
	for h in Datos.heroes:
		mascotas.append({"id": h[1], "n": h[0]})
	mascotas.append({"id": "a:animalito", "n": "Animalito"})
	mascotas.append({"id": "a:bichito", "n": "Bichito"})
	for a2 in Importar.listar():
		if not Importar.es_audio(a2["id"]):
			mascotas.append(a2)
	var pos_p := 0
	for i in mascotas.size():
		if mascotas[i]["id"] == str(Datos.reglas["mascota"]):
			pos_p = i
	var pl := Label.new()
	pl.custom_minimum_size = Vector2(150, 0)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.clip_text = true
	pl.add_theme_color_override("font_color", Estilo.MORADO)
	pl.text = mascotas[pos_p]["n"]
	var mover_p := func(d: int):
		pos_p = posmod(pos_p + d, mascotas.size())
		pl.text = mascotas[pos_p]["n"]
		Datos.reglas["mascota"] = mascotas[pos_p]["id"]
		Datos.guardar()
	var pf := HBoxContainer.new()
	pf.add_theme_constant_override("separation", 4)
	var p_menos := _boton("", "⬅", null, Color.WHITE, 46)
	p_menos.pressed.connect(func(): mover_p.call(-1))
	var p_mas := _boton("", "➡", null, Color.WHITE, 46)
	p_mas.pressed.connect(func(): mover_p.call(1))
	pf.add_child(p_menos)
	pf.add_child(pl)
	pf.add_child(p_mas)
	_regla_fila(v, "Mascota", pf)
	var pod: Array = []
	for q in [["escudo", "Escudo"], ["salto", "Salto alto"], ["escudo2", "Doble escudo"], ["vida", "Vida extra"], ["iman", "Imán"], ["bono", "Más puntos"]]:
		pod.append(q)
	v.add_child(_regla_opciones("poder", pod))
	if modo == "3d" and Datos.tipo_3d() == "corredor":
		_regla_fila(v, "Jugadores (mismo teclado)", _regla_opciones("jugadores", [[1, "1 jugador"], [2, "2 jugadores"]]))
	var tf := func(si: bool):
		Datos.reglas["tienda"] = si
		if si and (Datos.reglas["catalogo"] as Array).is_empty():
			var l: Array = []
			for h in Datos.heroes:
				l.append({"id": h[1], "n": h[0]})
			for a3 in Importar.listar():
				if not Importar.es_audio(a3["id"]):
					l.append(a3)
			Datos.reglas["catalogo"] = preload("res://scripts/tienda.gd").catalogo_desde(l)
		Datos.guardar()
	_regla_fila(v, "Tienda de mascotas", _regla_opciones("tienda", [[true, "Sí"], [false, "No"]], tf))
	var fl := Label.new()
	fl.text = "Mensaje al ganar el juego"
	fl.add_theme_color_override("font_color", Estilo.TINTA)
	v.add_child(fl)
	var le := LineEdit.new()
	le.text = str(Datos.reglas["final"])
	le.max_length = 50
	le.custom_minimum_size = Vector2(0, 46)
	le.text_changed.connect(func(t: String): Datos.reglas["final"] = t; Datos.guardar())
	v.add_child(le)
	var listo := _boton("  Listo", "✅", Estilo.VERDE, Color.WHITE)
	listo.add_theme_font_size_override("font_size", 22)
	listo.pressed.connect(_cerrar_modal)
	ext.add_child(listo)


## Ventana para pasar este nivel a 2D, 2.5D, vista desde arriba o 3D.
func _abrir_tipos() -> void:
	_cerrar_modal()
	var fondo := ColorRect.new()
	fondo.color = Color(0.08, 0.06, 0.23, 0.62)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal = fondo
	move_child(_tut, get_child_count() - 1)
	var centro := CenterContainer.new()
	fondo.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(560.0, size.x - 24.0), 0)
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 26, 0, Color.TRANSPARENT, 22))
	centro.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var tit := Label.new()
	tit.text = "¿En qué tipo de juego lo quieres?"
	tit.add_theme_font_size_override("font_size", 26)
	tit.add_theme_color_override("font_color", Estilo.TINTA)
	v.add_child(tit)
	var sub := Label.new()
	sub.text = "Tu juego se convierte en un nivel nuevo. El nivel de ahora queda como está."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_color_override("font_color", Estilo.SUAVE)
	v.add_child(sub)
	var actual := Datos.tipo_de(Datos.nivel)
	for k in ["plataformas", "25d", "arriba", "aventura", "corredor"]:
		var b := _boton("  " + str(Datos.NOMBRES_TIPO[k]) + ("  (el de ahora)" if k == actual else ""), "")
		b.disabled = k == actual
		b.custom_minimum_size = Vector2(0, 50)
		b.pressed.connect(func():
			_cerrar_modal()
			Datos.convertir_actual(k)
			reabrir.emit())
		v.add_child(b)
	var cerrar := _boton("  Cancelar", "✖")
	cerrar.pressed.connect(_cerrar_modal)
	v.add_child(cerrar)


func _nuevo() -> void:
	_esc.sel = null
	_esc.stamp = {}
	Datos.nivel = Datos.nivel_en_blanco()
	Datos.confirmar()
	_aviso("Nivel nuevo. Puedes volver atrás con ↩")


# ------------------------------------------------------------------ propiedades
func _al_agregar(tipo: String) -> void:
	_tut.avisar("add:" + tipo)
	if tipo == "player":
		_tut.avisar("hero")


func _refrescar() -> void:
	if not _nombre.has_focus():
		_nombre.text = str(Datos.nivel["name"])
	_btn_undo.disabled = Datos.historial.is_empty()
	_btn_redo.disabled = Datos.futuro.is_empty()
	_largo.select({30: 0, 45: 1, 60: 2}.get(int(Datos.nivel["cols"]), 0))
	_marcar_fichas()
	_refrescar_chip()
	_refrescar_props()
	_refrescar_niveles()


func _refrescar_chip() -> void:
	var activo: bool = not _esc.stamp.is_empty()
	_chip_caja.visible = activo
	if activo:
		_chip_txt.text = "Poniendo: %s   " % _esc.stamp["n"]


func _grupo(etq: String, valor: String, menos: Callable, mas: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	var l := Label.new()
	l.text = etq
	l.add_theme_color_override("font_color", Estilo.SUAVE)
	l.add_theme_font_size_override("font_size", 16)
	h.add_child(l)
	var bm := Button.new()
	bm.text = "−"
	bm.custom_minimum_size = Vector2(42, 42)
	bm.focus_mode = Control.FOCUS_NONE
	bm.pressed.connect(menos)
	h.add_child(bm)
	var v := Label.new()
	v.text = valor
	v.custom_minimum_size = Vector2(28, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(v)
	var bp := Button.new()
	bp.text = "+"
	bp.custom_minimum_size = Vector2(42, 42)
	bp.focus_mode = Control.FOCUS_NONE
	bp.pressed.connect(mas)
	h.add_child(bp)
	return h


func _refrescar_props() -> void:
	for c in _props_fila.get_children():
		_props_fila.remove_child(c)
		c.queue_free()
	var s: Variant = _esc.sel
	if s == null or not _esc.stamp.is_empty() or not Datos.nivel["items"].has(s):
		_props_caja.visible = false
		return
	_props_caja.visible = true
	var nombres := {"plat": "Plataforma", "coin": "Moneda", "star": "Estrella", "gem": "Gema", "spike": "Pinchos", "spring": "Resorte", "goal": "Meta", "enemy": "Enemigo", "deco": "Decoración", "player": "Inicio"}
	var l := Label.new()
	l.text = nombres.get(s["t"], "")
	l.add_theme_font_size_override("font_size", 20)
	_props_fila.add_child(l)
	if s["t"] == "plat":
		_props_fila.add_child(_grupo("Ancho", str(s["w"]), _ajustar.bind("w", -1), _ajustar.bind("w", 1)))
		_props_fila.add_child(_grupo("Alto", str(s["h"]), _ajustar.bind("h", -1), _ajustar.bind("h", 1)))
	if s["t"] == "plat" and modo == "3d":
		_props_fila.add_child(_grupo("Altura", str(int(s.get("alt", 1))), _ajustar.bind("alt", -1), _ajustar.bind("alt", 1)))
	if s["t"] == "deco":
		_props_fila.add_child(_grupo("Tamaño", str(int(s.get("s", 56)) / 12), _ajustar.bind("s", -1), _ajustar.bind("s", 1)))
	if s["t"] == "enemy":
		_props_fila.add_child(_grupo("Recorrido", str(s["r"]), _ajustar.bind("r", -1), _ajustar.bind("r", 1)))
		_props_fila.add_child(_grupo("Rapidez", str(int(s["sp"]) / 10), _ajustar.bind("sp", -1), _ajustar.bind("sp", 1)))
	if s["t"] != "player" and s["t"] != "goal":
		var dup := _boton(" Copiar", "📑")
		dup.pressed.connect(_duplicar)
		_props_fila.add_child(dup)
	if s["t"] != "player":
		var del := _boton(" Borrar", "🗑", Estilo.ROJO)
		del.pressed.connect(_borrar_sel)
		_props_fila.add_child(del)


func _ajustar(clave: String, d: int) -> void:
	var s: Variant = _esc.sel
	if s == null:
		return
	var cols: int = Datos.nivel["cols"]
	match clave:
		"w":
			s["w"] = clampi(s["w"] + d, 1, cols - s["x"])
		"h":
			s["h"] = clampi(s["h"] + d, 1, Datos.FILAS - s["y"])
		"r":
			s["r"] = clampi(s["r"] + d, 1, 10)
		"sp":
			s["sp"] = clampi(s["sp"] + d * 10, 10, 160)
		"alt":
			s["alt"] = clampi(int(s.get("alt", 1)) + d, 1, 8)
		"s":
			s["s"] = clampi(int(s.get("s", 56)) + d * 12, 24, 360)
	Datos.confirmar()
	_refrescar_props()


func _borrar_sel() -> void:
	var s: Variant = _esc.sel
	if s == null or s["t"] == "player":
		return
	Datos.quitar(s)
	_esc.sel = null
	Datos.confirmar()
	_refrescar_props()


func _duplicar() -> void:
	var s: Variant = _esc.sel
	if s == null:
		return
	var c: Dictionary = s.duplicate(true)
	c["id"] = Datos.nuevo_id()
	var ancho := int(c.get("w", 1))
	c["x"] = mini(int(Datos.nivel["cols"]) - 1, int(c["x"]) + ancho)
	Datos.nivel["items"].append(c)
	_esc.sel = c
	Datos.confirmar()
	_refrescar_props()


func _aviso(msg: String) -> void:
	_aviso_txt.text = msg
	_aviso_caja.modulate.a = 1.0
	if _aviso_tween:
		_aviso_tween.kill()
	_aviso_tween = create_tween()
	_aviso_tween.tween_interval(2.0)
	_aviso_tween.tween_property(_aviso_caja, "modulate:a", 0.0, 0.4)


# ------------------------------------------------------------------ jugar
func _jugar() -> void:
	if _jugando:
		return
	var hay_inicio := false
	var hay_meta := false
	for it in Datos.nivel["items"]:
		hay_inicio = hay_inicio or it["t"] == "player"
		hay_meta = hay_meta or it["t"] == "goal"
	if not hay_inicio and modo != "3d":
		_aviso("Falta el punto de inicio (en Objetos)")
		return
	_tut.avisar("play")
	_tut.visible = false
	_jugando = ColorRect.new()
	(_jugando as ColorRect).color = Color(0.06, 0.05, 0.16)
	add_child(_jugando)
	_jugando.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# marco con la forma de la pantalla elegida (horizontal 16:9 o vertical 9:16)
	var vertical: bool = str(Datos.nivel.get("orient", "horizontal")) == "vertical"
	var marco := AspectRatioContainer.new()
	marco.ratio = 9.0 / 16.0 if vertical else 16.0 / 9.0
	_jugando.add_child(marco)
	marco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var proy := Datos.proyecto()
	var j: Control = Partida.new()
	marco.add_child(j)
	var tactil: bool = str(Datos.nivel.get("disp", "pc")) == "movil" or DisplayServer.is_touchscreen_available()
	j.iniciar(proy, Datos.idx, Datos.idx == 0, tactil, true)
	j.salir.connect(_cerrar_juego)
	if not hay_meta:
		_aviso("Tip: añade una Meta para poder ganar")


func _cerrar_juego() -> void:
	if _jugando:
		_jugando.queue_free()
		_jugando = null
	_tut.visible = _tut.activo


# ------------------------------------------------------------------ exportar
func _abrir_exportar() -> void:
	_tut.avisar("export")
	_cerrar_modal()
	_botones_exp.clear()
	var fondo := ColorRect.new()
	fondo.color = Color(0.08, 0.06, 0.23, 0.62)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal = fondo
	move_child(_tut, get_child_count() - 1)
	var centro := CenterContainer.new()
	fondo.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 0)
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 26, 0, Color.TRANSPARENT, 22))
	centro.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var t := Label.new()
	t.text = "¡Tu juego está listo!"
	t.add_theme_font_size_override("font_size", 30)
	v.add_child(t)
	var desc := Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(530, 0)
	desc.add_theme_color_override("font_color", Estilo.SUAVE)
	v.add_child(desc)
	if _exp.disponible():
		desc.text = "Elige dónde quieres jugarlo. El botón mágico crea los archivos por ti y los deja en la carpeta «Mis juegos» de Documentos."
		for d in [["web", "🌐", "  Página web (HTML)", "Se abre en cualquier navegador"], ["windows", "🖥", "  Programa de Windows (.exe)", "Para jugar en la computadora"], ["android", "📱", "  App de Android (.apk)", "Para celulares y tablets"]]:
			var b := Button.new()
			b.text = "%s   —   %s" % [d[2], d[3]]
			b.icon = Datos.textura(d[1])
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.custom_minimum_size = Vector2(0, 58)
			b.focus_mode = Control.FOCUS_NONE
			b.disabled = not _exp.tiene_godot()
			b.pressed.connect(_lanzar_exportar.bind(d[0]))
			v.add_child(b)
			_botones_exp.append(b)
		if not _exp.tiene_godot():
			var aviso := Label.new()
			aviso.text = "Primero hay que indicar dónde está Godot (lo hace un adulto una sola vez)."
			aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(aviso)
			var bg := _boton(" Elegir Godot…", "📁", Estilo.MORADO)
			bg.pressed.connect(func(): _exp.elegir_godot(func(): _abrir_exportar.call_deferred()))
			v.add_child(bg)
	else:
		desc.text = "Desde este dispositivo no se puede crear el programa. Copia el código de tu juego y ábrelo en la computadora con el creador para exportarlo."
	_estado_exp = Label.new()
	_estado_exp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado_exp.custom_minimum_size = Vector2(530, 0)
	_estado_exp.add_theme_color_override("font_color", Estilo.MORADO)
	v.add_child(_estado_exp)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	var copiar := _boton(" Copiar código del nivel", "📋")
	copiar.pressed.connect(func():
		DisplayServer.clipboard_set(Datos.a_json())
		_estado_exp.text = "¡Código copiado!")
	h.add_child(copiar)
	var pegar := _boton(" Pegar nivel", "📁")
	pegar.pressed.connect(func():
		if Datos.desde_json(DisplayServer.clipboard_get()):
			_esc.sel = null
			_estado_exp.text = "¡Nivel pegado!"
		else:
			_estado_exp.text = "No encontré un nivel copiado.")
	h.add_child(pegar)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(sp)
	var cerrar := _boton("Cerrar")
	cerrar.pressed.connect(_cerrar_modal)
	h.add_child(cerrar)


func _cerrar_modal() -> void:
	_modal_es_reglas = false
	if _prev_audio and _prev_audio.playing:
		_prev_audio.stop()
	if _modal:
		_modal.queue_free()
		_modal = null


func _lanzar_exportar(plataforma: String) -> void:
	_estado_exp.text = "Preparando tu juego… puede tardar un ratito ⏳"
	for b in _botones_exp:
		b.disabled = true
	_exp.exportar(plataforma, str(Datos.nivel["name"]), Datos.a_json())


func _al_exportar(ok: bool, mensaje: String, carpeta: String) -> void:
	if _estado_exp == null or not is_instance_valid(_estado_exp):
		return
	_estado_exp.text = mensaje
	for b in _botones_exp:
		b.disabled = false
	if ok and carpeta != "":
		OS.shell_open(carpeta)


# ------------------------------------------------------------------ tutorial y teclado
func _iniciar_tutorial() -> void:
	_ajustes.set_value("tutorial", _clave_tutorial(), true)
	_ajustes.save("user://ajustes.cfg")
	_cambiar_tab("pers")
	_tut.iniciar()


func _unhandled_key_input(ev: InputEvent) -> void:
	if _jugando or not (ev is InputEventKey) or not ev.pressed:
		return
	var k := ev as InputEventKey
	if k.ctrl_pressed and k.keycode == KEY_Z:
		_esc.sel = null
		Datos.deshacer()
	elif k.ctrl_pressed and k.keycode == KEY_Y:
		_esc.sel = null
		Datos.rehacer()
	elif k.keycode == KEY_DELETE or k.keycode == KEY_BACKSPACE:
		_borrar_sel()
	elif k.keycode == KEY_ESCAPE:
		_esc.stamp = {}
		_esc.sel = null
		_usar_herramienta("mover")
		_refrescar_chip()
		_marcar_fichas()
