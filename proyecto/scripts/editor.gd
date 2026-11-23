extends Control
## El creador: barra superior, biblioteca (personajes, fondos, objetos,
## decoración), escenario, tutorial y exportación con el botón mágico.

const PanelRend := preload("res://scripts/panel_rendimiento.gd")
const Guia := preload("res://scripts/guia.gd")
const PanelExportar := preload("res://scripts/panel_exportar.gd")
const PanelColores := preload("res://scripts/panel_colores.gd")
const Categorias := preload("res://scripts/categorias.gd")
const PanelElementos := preload("res://scripts/panel_elementos.gd")
const PanelMini := preload("res://scripts/panel_mini.gd")
const PanelJuego := preload("res://scripts/panel_juego.gd")
const PanelPista := preload("res://scripts/panel_pista.gd")
const PanelCreador := preload("res://scripts/panel_creador.gd")
const PanelHoja := preload("res://scripts/panel_hoja.gd")
const PanelEfectos := preload("res://scripts/panel_efectos.gd")
const PanelEventos := preload("res://scripts/panel_eventos.gd")
const PanelBloques := preload("res://scripts/panel_bloques.gd")
const Recetas := preload("res://scripts/recetas.gd")
const PersonajesPanel := preload("res://scripts/panel_personajes.gd")
const PortadaEd := preload("res://scripts/portada_editor.gd")
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
var _t_pintar: Button
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
var _objetivos := {}
var _ajustes := ConfigFile.new()
var _construido := false
var _titulo: Label
var _modo_txt: Label
var _niveles_fila: HFlowContainer
var _port: Control
var _mini_ed: Control
var _mini_sig := ""
var _pers: Control
var _herr: Control
var _panel_bib: Control
var _etapa := "mundo"
var _etapas_fila: HBoxContainer
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
	var nombre_modo: String = Datos.nombre_estilo(Datos.nivel) if Datos.nombre_estilo(Datos.nivel) != "" else {"2d": "Vista desde arriba" if str(Datos.nivel.get("tipo", "")) == "arriba" else "Plataformas 2D", "25d": "Plataformas 2.5D", "3d": "Corredor 3D" if Datos.tipo_3d() == "corredor" else "Aventura 3D"}.get(modo, "")
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
	var b_guia := _boton(" Guía", "🧭", c_claro)
	b_guia.tooltip_text = "Los pasos para crear este tipo de juego"
	b_guia.pressed.connect(_abrir_guia)
	fila.add_child(b_guia)
	_textos_barra.append([b_guia, " Guía"])
	_b_ahora = _boton(" Ahora…", "💡", Color("ffd23f"))
	_b_ahora.tooltip_text = "Lo que podrías hacer ahora"
	_b_ahora.pressed.connect(_abrir_ahora)
	fila.add_child(_b_ahora)
	var b_elem := _boton(" Elementos", "🌍", c_claro)
	b_elem.tooltip_text = "Lista de todo lo que tiene este mundo: reemplazar, activar o desactivar"
	b_elem.pressed.connect(_abrir_elementos)
	fila.add_child(b_elem)
	_textos_barra.append([b_elem, " Elementos"])
	var b_tipo := _boton(" Tipo de juego", "🎮", c_claro)
	b_tipo.pressed.connect(_abrir_tipos)
	fila.add_child(b_tipo)
	_textos_barra.append([b_tipo, " Tipo de juego"])
	var b_col := _boton(" Colores", "🎨", c_claro)
	b_col.pressed.connect(_abrir_colores)
	fila.add_child(b_col)
	_textos_barra.append([b_col, " Colores"])
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
	var b_sorp := _boton(" Sorpréndeme", "✨", c_claro)
	b_sorp.tooltip_text = "Cambia el fondo y el héroe al azar"
	b_sorp.pressed.connect(_sorprender)
	fila.add_child(b_sorp)
	_textos_barra.append([b_sorp, " Sorpréndeme"])
	var b_jugar := _boton(" ¡Jugar!", "▶", Estilo.VERDE, Color.WHITE, 150)
	b_jugar.add_theme_font_size_override("font_size", 26)
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
	_panel_bib = panel
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var fila_tabs := HBoxContainer.new()
	fila_tabs.add_theme_constant_override("separation", 6)
	v.add_child(fila_tabs)
	for d in [["pers", "Personajes", "🐱"], ["fondos", "Fondos", "🖼"], ["objetos", "Objetos", "🧱"], ["deco", "Decorar", "🌳"], ["lib", "Biblioteca", "🎨"], ["mis", "Mis cosas", "📁"]]:
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
	_mini_ed = PanelMini.new()
	zona.add_child(_mini_ed)
	_mini_ed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mini_ed.visible = false
	_mini_ed.probar.connect(_jugar)
	_port = PortadaEd.new()
	zona.add_child(_port)
	_port.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_port.visible = false
	_pers = PersonajesPanel.new()
	zona.add_child(_pers)
	_pers.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pers.visible = false
	_pers.cambio.connect(func(): _aviso("Personajes guardados"))
	_port.cambio.connect(func(): Datos.guardar())
	_port.aviso.connect(func(t): _aviso(t))
	# herramientas
	var herr := HBoxContainer.new()
	_herr = herr
	herr.position = Vector2(12, 12)
	herr.add_theme_constant_override("separation", 6)
	zona.add_child(herr)
	_t_mover = _boton(" Mover", "✋")
	_t_mover.pressed.connect(func(): _usar_herramienta("mover"))
	herr.add_child(_t_mover)
	_t_pintar = _boton(" Pintar", "🖌")
	_t_pintar.tooltip_text = "Pinta bloques arrastrando, como un tilemap"
	_t_pintar.pressed.connect(func(): _usar_herramienta("pintar"))
	herr.add_child(_t_pintar)
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
	_niveles_fila.resized.connect(_acomodar_lienzo)
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
	_modo_txt.visible = size.x > 1600.0
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
			var imgs := Importar.listar_propios().filter(func(a): return str(a["id"]).begins_with("u:"))
			if not imgs.is_empty():
				r.append({"id": "fondo_ninguno", "n": "Del tema", "t": "fondo_img", "e": ""})
				for a in imgs:
					r.append({"id": "f" + a["id"], "n": a["n"], "t": "fondo_img", "e": a["id"]})
		"objetos":
			var lista := [["plat", "Plataforma"], ["coin", "Moneda"], ["star", "Estrella"], ["gem", "Gema"], ["spike", "Pinchos"], ["spring", "Resorte"], ["goal", "Meta"], ["player", "Inicio"]]
			if modo == "2d" and str(Datos.nivel.get("tipo", "")) != "arriba" and str(Datos.nivel.get("estilo", "")) == "":
				lista += [["llave", "Llave"], ["puerta", "Puerta"], ["boton", "Botón"], ["platmov", "Plataforma móvil"], ["puente", "Puente que se cae"], ["ruta", "Plataforma en ruta"], ["zona", "Zona (agua, hielo, viento…)"], ["pendulo", "Péndulo"], ["rueda", "Rueda que rueda"], ["pelota", "Pelota que rebota"], ["cuerda", "Cuerda que se mece"], ["caja", "Caja empujable"]]
			if modo == "2d" and str(Datos.nivel.get("tipo", "")) == "arriba":
				lista = [["plat", "Pared"], ["coin", "Moneda"], ["star", "Estrella"], ["gem", "Gema"], ["spike", "Pinchos"], ["goal", "Meta"], ["player", "Inicio"]]
			if str(Datos.nivel.get("estilo", "")) in ["carrera", "kart"]:
				lista = [["plat", "Muro de pista"], ["spring", "Turbo"], ["coin", "Moneda"], ["star", "Estrella"], ["spike", "Charco de aceite"], ["goal", "Línea de meta"], ["player", "Salida"]]
			elif modo == "3d" and Datos.tipo_3d() == "aventura":
				lista = [["plat", "Bloque"], ["coin", "Moneda"], ["star", "Estrella"], ["gem", "Gema"], ["spike", "Pinchos"], ["goal", "Meta"], ["player", "Inicio"]]
			elif modo == "3d":
				lista = [["valla", "Valla"], ["pared", "Pared"], ["viga", "Viga"], ["coin", "Moneda"], ["star", "Estrella"], ["gem", "Gema"], ["goal", "Meta"]]
			for d in lista:
				r.append({"id": d[0], "n": d[1], "t": d[0]})
			var pfs: Array = Datos.reglas.get("prefabs", [])
			if not pfs.is_empty():
				r.append({"enc": "Mis bloques reutilizables"})
				for k in pfs.size():
					r.append({"id": "pf%d" % k, "n": str(pfs[k]["n"]), "t": "prefab", "items": pfs[k]["items"]})
		"deco":
			for cat in Assets3D.OBJETOS:
				r.append({"enc": cat})
				for o in Assets3D.OBJETOS[cat]:
					r.append({"id": "da:" + o[0], "n": o[1], "t": "deco", "e": "a:" + o[0], "s": Assets3D.cuadro_px(o[0])})
			r.append({"enc": "Divertidas"})
			for d in Datos.decoraciones:
				r.append({"id": "d" + d[1], "n": d[0], "t": "deco", "e": d[1], "s": d[2]})
		"lib":
			var bib := Importar.biblioteca()
			var por_cat := func(cats: Array) -> Array:
				return bib.filter(func(a): return str(a.get("cat", "")) in cats and (modo != "2d" or not Importar.es_audio(a["id"])))
			r.append({"sel": true})
			if _lib_cat != "":
				r.append({"enc": _lib_cat})
				for a in por_cat.call([_lib_cat]):
					r.append({"id": "bd" + a["id"], "n": a["n"], "t": "deco", "e": a["id"], "s": 64})
				return r
			var heroes: Array = por_cat.call(["Personas", "Animales", "Dinosaurios", "Monstruos"])
			r.append({"enc": "Personajes (héroe)"})
			for a in heroes:
				r.append({"id": "bh" + a["id"], "n": a["n"], "t": "hero", "e": a["id"]})
			r.append({"enc": "Enemigos"})
			for a in por_cat.call(["Monstruos", "Animales", "Dinosaurios"]):
				r.append({"id": "be" + a["id"], "n": a["n"], "t": "enemy", "e": a["id"], "fly": false, "sp": 60})
			for cat in ["Plataformas", "Elementos", "Vehículos"]:
				r.append({"enc": cat})
				for a in por_cat.call([cat]):
					r.append({"id": "bd" + a["id"], "n": a["n"], "t": "deco", "e": a["id"], "s": 64})
			r.append({"enc": "Sonidos y música (toca para oírlos; se eligen en Reglas)"})
			for a in bib.filter(func(a): return Importar.es_audio(a["id"])):
				r.append({"id": "bs" + a["id"], "n": a["n"], "t": "audio", "e": a["id"]})
		"mis":
			r.append({"id": "importar", "n": "Importar…", "t": "importar"})
			var mias := Importar.listar_propios()
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


var _lib_cat := ""


func _construir_biblioteca() -> void:
	for c in _rejilla.get_children():
		_rejilla.remove_child(c)
		c.queue_free()
	var n := 0
	var tactil := DisplayServer.is_touchscreen_available()
	for d in _defs(tab):
		if d.has("sel"):
			var ob := OptionButton.new()
			var cats := ["", "Naturaleza", "Rocas", "Ciudad", "Calles", "Trenes", "Plataformas 3D", "Follaje 2D", "Animales", "Elementos", "Vehículos"]
			var nombres := ["Lo básico", "🌳 Naturaleza", "🪨 Rocas", "🏙 Ciudad", "🛣 Calles", "🚆 Trenes", "🧱 Plataformas 3D", "🍃 Follaje (dibujo 2D)", "🐾 Animales", "📦 Elementos", "🚗 Vehículos"]
			for i in cats.size():
				if cats[i] == "Follaje 2D" and modo != "2d":
					continue
				ob.add_item(nombres[i], i)
				if cats[i] == _lib_cat:
					ob.select(ob.item_count - 1)
			ob.item_selected.connect(func(k: int):
				_lib_cat = cats[ob.get_item_id(k)]
				_construir_biblioteca())
			ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_rejilla.add_child(ob)
			_rejilla.add_child(_relleno())
			_rejilla.add_child(_relleno())
			n += 3
			continue
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
	if h == "borrar" or h == "pintar":
		_esc.stamp = {}
		_esc.sel = null
		_refrescar_chip()
		_marcar_fichas()
	_marcar(_t_mover, h == "mover")
	_marcar(_t_borrar, h == "borrar")
	_marcar(_t_pintar, h == "pintar")
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
	var bp := Button.new()
	bp.text = " Portada"
	bp.icon = Datos.textura("🎮")
	bp.expand_icon = true
	bp.add_theme_constant_override("icon_max_width", 24)
	bp.custom_minimum_size = Vector2(0, 40)
	bp.focus_mode = Control.FOCUS_NONE
	if _etapa == "portada":
		Estilo.pintar(bp, Estilo.MORADO)
	bp.pressed.connect(func(): _set_etapa("portada"))
	_niveles_fila.add_child(bp)
	var bj := Button.new()
	bj.text = " Personajes"
	bj.icon = Datos.textura("🏃")
	bj.expand_icon = true
	bj.add_theme_constant_override("icon_max_width", 24)
	bj.custom_minimum_size = Vector2(0, 40)
	bj.focus_mode = Control.FOCUS_NONE
	bj.tooltip_text = "Elige qué personajes se pueden usar"
	bj.pressed.connect(func(): _set_etapa("personajes"))
	if _etapa == "personajes":
		Estilo.pintar(bj, Estilo.MORADO)
	_niveles_fila.add_child(bj)
	var br := Button.new()
	br.text = " Rendimiento"
	br.icon = Datos.textura("🔧")
	br.expand_icon = true
	br.add_theme_constant_override("icon_max_width", 24)
	br.custom_minimum_size = Vector2(0, 40)
	br.focus_mode = Control.FOCUS_NONE
	br.tooltip_text = "Calidad por plataforma y revisión de errores (Testear)"
	br.pressed.connect(_abrir_rendimiento)
	_niveles_fila.add_child(br)
	var et := Label.new()
	et.text = "Mundos:"
	et.add_theme_color_override("font_color", Estilo.TINTA)
	et.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	et.add_theme_constant_override("outline_size", 6)
	_niveles_fila.add_child(et)
	for i in n:
		var b := Button.new()
		b.text = "Mundo %d" % (i + 1)
		b.custom_minimum_size = Vector2(0, 40)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = "Nivel %d" % (i + 1)
		if i == Datos.idx and _etapa == "mundo":
			Estilo.pintar(b, Estilo.MORADO)
		b.pressed.connect(_ir_nivel.bind(i))
		_niveles_fila.add_child(b)
	var mas := _boton(" Mundo nuevo", "➕", Estilo.VERDE)
	mas.custom_minimum_size.y = 40
	mas.tooltip_text = "Crea el Mundo %d y se abre para trabajar ahí" % (n + 1)
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
	# botones según el tipo de juego
	var esmini := str(Datos.nivel.get("estilo", "")) == "mini"
	var extra: Array = []
	if Datos.es_corredor() or Datos.nivel.has("pista"):
		extra.append([" Pista", "🛣", "Creador de pista: curvas, subidas y bajadas", "trazado"])
	if not esmini:
		extra.append([" Elementos", "🌍", "Lista de todo lo del mundo", "elementos"])
	else:
		extra.append([" Contenido", "📝", "Edita el contenido del minijuego", "contenido"])
	for ex in extra:
		var be := _boton(ex[0], ex[1])
		be.custom_minimum_size.y = 40
		be.tooltip_text = ex[2]
		be.pressed.connect(_ir_paso.bind(ex[3]))
		_niveles_fila.add_child(be)
	for tb2 in [[" Eventos", "⚡", "Si pasa esto, haz aquello", "eventos"], [" Bloques", "🧩", "Programa apilando bloques de colores", "bloques"], [" Efectos", "🎬", "Sonidos, partículas, cámara, luces y filtros", "efectos"]]:
		var be2 := _boton(tb2[0], tb2[1])
		be2.custom_minimum_size.y = 40
		be2.tooltip_text = tb2[2]
		be2.pressed.connect(_ir_paso.bind(tb2[3]))
		_niveles_fila.add_child(be2)
	var crear := _boton(" Crear personaje", "🧑")
	crear.custom_minimum_size.y = 40
	crear.tooltip_text = "Arma un personaje: cuerpo, color y accesorio"
	crear.pressed.connect(_ir_paso.bind("creador"))
	_niveles_fila.add_child(crear)
	for tb in [[" Reglas", "📜", "Cómo se gana y se pierde, vidas, tiempo y puntos", "reglas"], [" Mecánicas", "🎮", "Lo que sabe hacer el personaje", "mecanicas"], [" Física", "⚙", "Gravedad, salto, velocidad y rebote", "fisica"]]:
		var reg := _boton(tb[0], tb[1], Estilo.TURQUESA)
		reg.custom_minimum_size.y = 40
		reg.tooltip_text = tb[2]
		reg.pressed.connect(_ir_paso.bind(tb[3]))
		_niveles_fila.add_child(reg)


## El lienzo empieza debajo de las barras de botones, para que nada quede tapado.
func _acomodar_lienzo() -> void:
	if _esc == null or _niveles_fila == null:
		return
	_esc.offset_top = _niveles_fila.position.y + _niveles_fila.size.y + 6.0


## Cuadro de arriba de Reglas: dice con palabras cuándo se gana, cuándo se pierde y si la pista termina.
func _reglas_resumen(v: VBoxContainer) -> void:
	var r: Dictionary = Datos.reglas
	var corre: bool = Datos.es_corredor() or Datos.nivel.has("pista")
	var mini: bool = str(Datos.nivel.get("estilo", "")) == "mini"
	var gana := ""
	var pierde := ""
	if mini:
		gana = "Cumples el objetivo del minijuego (puntos, metas o respuestas, según el contenido)."
		pierde = "Se acaban tus intentos, vidas o el tiempo."
	elif str(Datos.nivel.get("estilo", "")) == "supervivencia":
		gana = "Aguantas %d segundos con vida." % int(Datos.nivel.get("aguantar", 45))
		pierde = "Te quedas sin vidas."
	elif bool(r.get("sin_fin", false)) and corre:
		gana = "No se gana: la pista no termina. Cada vuelta suma puntos y se hace más difícil."
		pierde = "Chocas y te quedas sin vidas. Tu meta es batir tu récord."
	else:
		match str(r.get("meta", "meta")):
			"mitad": gana = "Recoges la mitad de los premios y llegas a la meta."
			"todo": gana = "Recoges todos los premios y llegas a la meta."
			_: gana = "Llegas a la meta."
		pierde = "Te quedas sin vidas" + (" o se acaba el tiempo (%d:%02d)." % [int(r["tiempo"]) / 60, int(r["tiempo"]) % 60] if int(r["tiempo"]) > 0 else ".")
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Estilo.caja(Color("eef0ff"), 16, 0, Color.TRANSPARENT, 12))
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", Estilo.TINTA)
	l.text = "Cómo se gana: %s\nCómo se pierde: %s\nPista: %s" % [gana, pierde, ("sin fin" if bool(r.get("sin_fin", false)) else "con meta al final") if corre else "no aplica"]
	caja.add_child(l)
	v.add_child(caja)


func _abrir_rendimiento() -> void:
	_cerrar_modal()
	var pr := PanelRend.new()
	add_child(pr)
	move_child(_tut, get_child_count() - 1)
	_modal = pr
	pr.cerrar.connect(_cerrar_modal)
	pr.corregido.connect(func():
		_esc.sel = null
		_refrescar_niveles()
		if _port.visible:
			_port.refrescar()
		_esc.queue_redraw())


var _b_ahora: Button = null
var _ahora: Dictionary = {}


func _actualizar_ahora() -> void:
	if _b_ahora == null:
		return
	_ahora = Guia.ahora(Datos.proyecto())
	_b_ahora.text = " " + str(_ahora["titulo"])


func _abrir_ahora() -> void:
	_actualizar_ahora()
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
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	for par in [["💡 " + str(_ahora["titulo"]), 26, Estilo.TINTA], [str(_ahora["texto"]), 18, Estilo.TINTA], ["En esta sección:\n" + Guia.tutorial(_etapa, tab, str(Datos.reglas.get("plataforma", "windows"))), 16, Estilo.SUAVE]]:
		var l := Label.new()
		l.text = par[0]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(300, 0)
		l.add_theme_font_size_override("font_size", par[1])
		l.add_theme_color_override("font_color", par[2])
		v.add_child(l)
	if str(_ahora["abre"]) != "":
		var hz := Button.new()
		hz.text = str(_ahora["boton"])
		hz.custom_minimum_size = Vector2(0, 50)
		Estilo.pintar(hz, Estilo.TURQUESA)
		var ab: String = _ahora["abre"]
		hz.pressed.connect(func():
			_cerrar_modal()
			_ir_paso(ab))
		v.add_child(hz)
	var cz := Button.new()
	cz.text = "Cerrar"
	cz.custom_minimum_size = Vector2(0, 44)
	cz.pressed.connect(_cerrar_modal)
	v.add_child(cz)


func _set_etapa(e: String) -> void:
	_etapa = e
	_esc.visible = e == "mundo"
	_herr.visible = e == "mundo"
	_panel_bib.visible = e == "mundo"
	_port.visible = e == "portada"
	_pers.visible = e == "personajes"
	if e == "personajes":
		_pers.refrescar()
		_pers.move_to_front()
		_niveles_fila.get_parent().move_child(_niveles_fila, -1)
	if e == "portada":
		_port.refrescar()
	_refrescar_niveles()
	_vista_mini()
	_actualizar_ahora()


func _ir_nivel(i: int) -> void:
	if _etapa != "mundo":
		_set_etapa("mundo")
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
	_reglas_resumen(v)
	if Datos.es_corredor() or Datos.nivel.has("pista"):
		_regla_fila(v, "Pista", _regla_opciones("sin_fin", [[false, "Con meta"], [true, "Sin fin (como Dino Run)"]]))
	_regla_fila(v, "Vidas", _regla_paso("vidas", 1, 9, 1, func(x): return str(x)))
	_regla_fila(v, "Tiempo por nivel", _regla_paso("tiempo", 0, 900, 15, func(x): return "Sin límite" if x == 0 else "%d:%02d" % [x / 60, x % 60]))
	var dl := Label.new()
	dl.text = "Dificultad"
	dl.add_theme_color_override("font_color", Estilo.TINTA)
	v.add_child(dl)
	v.add_child(_regla_opciones("dificultad", [["facil", "Fácil"], ["normal", "Normal"], ["dificil", "Difícil"], ["extrema", "Extrema"]]))
	_regla_fila(v, "El jugador elige la dificultad", _regla_opciones("elegir_dificultad", [[false, "No"], [true, "Sí"]]))
	_regla_fila(v, "Misiones del día", _regla_opciones("misiones", [[false, "No"], [true, "Sí"]]))
	_regla_fila(v, "Revivir al perder (monedas)", _regla_paso("revivir", 0, 500, 10, func(x): return "No" if x == 0 else str(x)))
	_regla_fila(v, "Salón de espera (cuenta 3-2-1 antes de empezar)", _regla_opciones("espera", [[false, "No"], [true, "Sí"]]))
	_regla_fila(v, "Logros (medallas al jugar)", _regla_opciones("logros", [[true, "Sí"], [false, "No"]]))
	_regla_fila(v, "Arma (juegos de disparos)", _regla_opciones("arma", [["pistola", "Pistola"], ["rafaga", "Ráfaga"], ["escopeta", "Escopeta"], ["rifle", "Rifle"]]))
	_regla_fila(v, "Modo prueba (todo desbloqueado)", _regla_opciones("modo_prueba", [[false, "No"], [true, "Sí"]]))
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
	for a in Importar.listar_propios():
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
	for a2 in Importar.mascotas():
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
			for a3 in Importar.mascotas():
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
	_actualizar_ahora()
	_refrescar_niveles()
	_vista_mini()


## En los minijuegos no hay mapa que dibujar: se muestra el panel «Contenido» en su lugar.
func _vista_mini() -> void:
	var es_mini := str(Datos.nivel.get("estilo", "")) == "mini" and _etapa == "mundo"
	_mini_ed.visible = es_mini
	if es_mini:
		_esc.visible = false
		_herr.visible = false
		_panel_bib.visible = false
		var sig := "%d:%s" % [Datos.idx, str(Datos.nivel.get("mini", ""))]
		if sig != _mini_sig:
			_mini_sig = sig
			_mini_ed.refrescar()
	else:
		_mini_sig = ""


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
	var nombres := {"plat": "Plataforma", "coin": "Moneda", "star": "Estrella", "gem": "Gema", "spike": "Pinchos", "spring": "Resorte", "goal": "Meta", "llave": "Llave", "puerta": "Puerta", "boton": "Botón", "platmov": "Plataforma móvil", "puente": "Puente que se cae", "ruta": "Ruta", "zona": "Zona", "pendulo": "Péndulo", "rueda": "Rueda", "pelota": "Pelota", "cuerda": "Cuerda", "caja": "Caja", "enemy": "Enemigo", "deco": "Decoración", "player": "Inicio"}
	var l := Label.new()
	l.text = nombres.get(s["t"], "")
	l.add_theme_font_size_override("font_size", 20)
	_props_fila.add_child(l)
	if s["t"] in ["plat", "platmov", "puente", "zona", "ruta"]:
		_props_fila.add_child(_grupo("Ancho", str(s["w"]), _ajustar.bind("w", -1), _ajustar.bind("w", 1)))
		_props_fila.add_child(_grupo("Alto", str(s["h"]), _ajustar.bind("h", -1), _ajustar.bind("h", 1)))
	if s["t"] == "plat" and modo == "3d":
		_props_fila.add_child(_grupo("Altura", str(int(s.get("alt", 1))), _ajustar.bind("alt", -1), _ajustar.bind("alt", 1)))
	if s["t"] == "deco":
		_props_fila.add_child(_grupo("Tamaño", str(int(s.get("s", 56)) / 12), _ajustar.bind("s", -1), _ajustar.bind("s", 1)))
		if modo == "2d" and str(Datos.nivel.get("tipo", "")) == "arriba":
			var dl := LineEdit.new()
			dl.placeholder_text = "Diálogo al acercarte (personaje del RPG)"
			dl.custom_minimum_size = Vector2(280, 40)
			dl.max_length = 120
			dl.text = str(s.get("dlg", ""))
			dl.text_changed.connect(func(tx: String):
				if tx == "":
					s.erase("dlg")
				else:
					s["dlg"] = tx)
			dl.focus_exited.connect(Datos.confirmar)
			dl.text_submitted.connect(func(_t): Datos.confirmar(); dl.release_focus())
			_props_fila.add_child(dl)
	if s["t"] in ["enemy", "platmov", "pendulo"]:
		_props_fila.add_child(_grupo("Recorrido", str(s["r"]), _ajustar.bind("r", -1), _ajustar.bind("r", 1)))
		_props_fila.add_child(_grupo("Rapidez", str(int(s["sp"]) / 10), _ajustar.bind("sp", -1), _ajustar.bind("sp", 1)))
	if s["t"] in ["zona", "ruta"]:
		var lst: Array = Datos.ZONAS if s["t"] == "zona" else Datos.RUTAS
		var clv := "z" if s["t"] == "zona" else "forma"
		var oz := OptionButton.new()
		oz.custom_minimum_size = Vector2(190, 40)
		oz.focus_mode = Control.FOCUS_NONE
		oz.tooltip_text = "Cómo se comporta"
		for k in lst.size():
			oz.add_item(str(lst[k][1]), k)
			if lst[k][0] == str(s.get(clv, "")):
				oz.selected = k
		oz.item_selected.connect(func(k):
			s[clv] = lst[k][0]
			Datos.confirmar())
		_props_fila.add_child(oz)
		if s["t"] == "ruta":
			_props_fila.add_child(_grupo("Recorrido", str(s["r"]), _ajustar.bind("r", -1), _ajustar.bind("r", 1)))
			_props_fila.add_child(_grupo("Rapidez", str(int(s["sp"]) / 10), _ajustar.bind("sp", -1), _ajustar.bind("sp", 1)))
		elif s["z"] == "viento":
			_props_fila.add_child(_grupo("Dirección", "→" if int(s.get("d", 1)) >= 0 else "←", func(): s["d"] = -1; Datos.confirmar(), func(): s["d"] = 1; Datos.confirmar()))
	if not (s["t"] in ["player", "goal"]):
		var gp := Button.new()
		gp.text = "🧩 Guardar bloque"
		gp.tooltip_text = "Guarda este objeto y los que tiene alrededor (3 casillas) para ponerlos de nuevo con un toque"
		gp.custom_minimum_size = Vector2(150, 40)
		gp.focus_mode = Control.FOCUS_NONE
		gp.pressed.connect(func(): _guardar_bloque(s))
		_props_fila.add_child(gp)
	if s["t"] in ["rueda", "pelota", "cuerda"]:
		_props_fila.add_child(_grupo("Tamaño" if s["t"] != "cuerda" else "Largo", str(s["r"]), _ajustar.bind("r", -1), _ajustar.bind("r", 1)))
	if s["t"] == "enemy" and modo == "2d":
		var oc := OptionButton.new()
		oc.custom_minimum_size = Vector2(150, 40)
		oc.focus_mode = Control.FOCUS_NONE
		oc.tooltip_text = "Cómo se comporta el enemigo"
		var ia := str(s.get("ia", "patrulla"))
		for k in Datos.COMPORTAMIENTOS.size():
			oc.add_item(str(Datos.COMPORTAMIENTOS[k][1]), k)
			if Datos.COMPORTAMIENTOS[k][0] == ia:
				oc.selected = k
		oc.item_selected.connect(func(k):
			s["ia"] = Datos.COMPORTAMIENTOS[k][0]
			Datos.confirmar())
		_props_fila.add_child(oc)
	if s["t"] == "deco":
		var of := OptionButton.new()
		of.custom_minimum_size = Vector2(150, 40)
		of.focus_mode = Control.FOCUS_NONE
		of.tooltip_text = "Partículas que salen de la decoración"
		var fxs := str(s.get("fx", ""))
		for k in Datos.PART_TIPOS.size():
			of.add_item("Part: " + str(Datos.PART_TIPOS[k][1]), k)
			if Datos.PART_TIPOS[k][0] == fxs:
				of.selected = k
		of.item_selected.connect(func(k):
			var v: String = Datos.PART_TIPOS[k][0]
			if v == "":
				s.erase("fx")
			else:
				s["fx"] = v
			Datos.confirmar())
		_props_fila.add_child(of)
	if ["deco", "enemy", "coin", "star", "gem"].has(str(s["t"])) or (s["t"] == "player" and str(s.get("e", "")) != ""):
		var op := OptionButton.new()
		op.custom_minimum_size = Vector2(150, 40)
		op.focus_mode = Control.FOCUS_NONE
		op.tooltip_text = "Colores de este objeto: los del juego, los suyos o una paleta"
		op.add_item("🎨 Colores: del juego", 0)
		op.add_item("🎨 Colores: originales", 1)
		var ps := str(s.get("pal", ""))
		if ps == "no":
			op.selected = 1
		for k in Datos.PALETAS.size():
			op.add_item("🎨 " + str(Datos.PALETAS[k][1]), 2 + k)
			if Datos.PALETAS[k][0] == ps:
				op.selected = op.item_count - 1
		op.item_selected.connect(func(k):
			var id := op.get_item_id(k)
			if id == 0:
				s.erase("pal")
			elif id == 1:
				s["pal"] = "no"
			else:
				s["pal"] = Datos.PALETAS[id - 2][0]
			Datos.olvidar_texturas_pal()
			Datos.confirmar())
		_props_fila.add_child(op)
	if not ["plat", "platmov", "puente", "zona", "ruta", "pendulo", "rueda", "pelota", "cuerda", "player", "goal", "pared", "viga", "valla", "puerta", "boton", "caja"].has(str(s["t"])):
		var oa := OptionButton.new()
		oa.custom_minimum_size = Vector2(140, 40)
		oa.focus_mode = Control.FOCUS_NONE
		oa.tooltip_text = "Animación del objeto"
		var an := str(s.get("anim", "ninguna"))
		for k in Datos.ANIM_OBJ.size():
			oa.add_item("Anim: " + str(Datos.ANIM_OBJ[k][1]), k)
			if Datos.ANIM_OBJ[k][0] == an:
				oa.selected = k
		oa.item_selected.connect(func(k):
			var v: String = Datos.ANIM_OBJ[k][0]
			if v == "ninguna":
				s.erase("anim")
			else:
				s["anim"] = v
			Datos.confirmar())
		_props_fila.add_child(oa)
	if s["t"] != "player" and s["t"] != "goal":
		var dup := _boton(" Copiar", "📑")
		dup.pressed.connect(_duplicar)
		_props_fila.add_child(dup)
	if s["t"] != "player":
		var del := _boton(" Borrar", "🗑", Estilo.ROJO)
		del.pressed.connect(_borrar_sel)
		_props_fila.add_child(del)


## Guarda el objeto elegido y los que lo rodean como un «bloque reutilizable» (un prefab, como una escena de Godot).
func _guardar_bloque(s: Dictionary) -> void:
	var caja: Rect2 = Datos.caja_de(s).grow(3.0)
	var grupo: Array = []
	for it in Datos.nivel["items"]:
		if str(it["t"]) in ["player", "goal"]:
			continue
		if caja.intersects(Datos.caja_de(it)) or it == s:
			grupo.append(it)
	if grupo.is_empty():
		return
	var mx := 9999
	var my := 9999
	for it in grupo:
		mx = mini(mx, int(it["x"]))
		my = mini(my, int(it["y"]))
	var rel: Array = []
	for it in grupo:
		var c: Dictionary = (it as Dictionary).duplicate(true)
		c["x"] = int(it["x"]) - mx
		c["y"] = int(it["y"]) - my
		c.erase("id")
		rel.append(c)
	var lista: Array = Datos.reglas.get("prefabs", [])
	lista.append({"n": "Bloque %d" % (lista.size() + 1), "items": rel})
	Datos.reglas["prefabs"] = lista
	Datos.guardar()
	_aviso("Bloque guardado: búscalo en Objetos, «Mis bloques reutilizables»")
	_construir_biblioteca()


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
## Cambia el fondo y el héroe al azar (sin tocar lo que ya colocaste).
func _sorprender() -> void:
	var fondos: Array = Datos.temas.keys()
	var cambio: String = str(fondos[randi() % fondos.size()])
	Datos.nivel.erase("fondo")
	Datos.nivel["theme"] = cambio
	var heroes: Array = []
	for h in Datos.heroes:
		heroes.append(str(h[1]))
	for h in Assets3D.PERSONAJES:
		heroes.append("a:" + str(h[0]))
	Datos.nivel["hero"] = heroes[randi() % heroes.size()]
	_esc.sel = null
	Datos.confirmar()
	_aviso("¡Sorpresa! Prueba a darle a Jugar")


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
	var pe := PanelExportar.new()
	pe.exp = _exp
	add_child(pe)
	move_child(_tut, get_child_count() - 1)
	_modal = pe
	pe.cerrar.connect(func():
		_cerrar_modal()
		_esc.sel = null
		_refrescar_niveles()
		_esc.queue_redraw())


func _abrir_colores() -> void:
	_cerrar_modal()
	var pc := PanelColores.new()
	add_child(pc)
	move_child(_tut, get_child_count() - 1)
	_modal = pc
	pc.cerrar.connect(_cerrar_modal)
	pc.cambiado.connect(func():
		_esc.queue_redraw()
		_refrescar_niveles())


## Guía por pasos: según la categoría del juego, lista las secciones en orden y abre cada panel.
func _abrir_guia() -> void:
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
	panel.custom_minimum_size = Vector2(minf(600.0, size.x - 24.0), 0)
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 26, 0, Color.TRANSPARENT, 22))
	centro.add_child(panel)
	var v0 := VBoxContainer.new()
	v0.add_theme_constant_override("separation", 8)
	panel.add_child(v0)
	var cat := str(Datos.reglas.get("categoria", ""))
	var info: Dictionary = Categorias.categoria(cat)
	var tit := Label.new()
	tit.text = "Pasos de tu juego" + (" · " + Datos.limpiar_emoji(str(info.get("titulo", ""))) if info.size() > 0 else "")
	tit.add_theme_font_size_override("font_size", 26)
	tit.add_theme_color_override("font_color", Estilo.TINTA)
	v0.add_child(tit)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, minf(520.0, maxf(240.0, size.y - 200.0)))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v0.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	sc.add_child(v)
	var n := 0
	var lista_pasos: Array = Recetas.pasos_mini() if str(Datos.nivel.get("estilo", "")) == "mini" else Recetas.pasos(cat)
	for p in lista_pasos:
		n += 1
		var b := Button.new()
		var pronto: bool = p["abre"] == "pronto"
		b.text = "   %d. %s%s\n   %s" % [n, p["titulo"], "  (pronto)" if pronto else "", p["pregunta"]]
		b.icon = Datos.textura(str(p["emoji"]))
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 36)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 62)
		b.add_theme_font_size_override("font_size", 16)
		b.disabled = pronto
		var abre: String = p["abre"]
		b.pressed.connect(func():
			_cerrar_modal()
			_ir_paso(abre))
		v.add_child(b)
	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.custom_minimum_size = Vector2(0, 44)
	cerrar.pressed.connect(_cerrar_modal)
	v0.add_child(cerrar)


func _ir_paso(abre: String) -> void:
	match abre:
		"portada":
			_set_etapa("portada")
		"personajes":
			_set_etapa("personajes")
		"fondos", "objetos", "deco", "lib", "mis":
			_set_etapa("mundo")
			_cambiar_tab(abre)
		"pista":
			_set_etapa("mundo")
			_abrir_colores()
		"contenido":
			_set_etapa("mundo")
			_vista_mini()
		"elementos":
			_set_etapa("mundo")
			_abrir_elementos()
		"reglas":
			_abrir_reglas()
		"mecanicas", "fisica":
			_abrir_juego(abre)
		"hoja":
			_abrir_modal_simple(PanelHoja.new())
		"eventos", "efectos", "bloques":
			_abrir_modal_simple(PanelEventos.new() if abre == "eventos" else (PanelBloques.new() if abre == "bloques" else PanelEfectos.new()))
		"trazado":
			_set_etapa("mundo")
			_abrir_pista()
		"creador":
			_abrir_creador()
		"rendimiento":
			_abrir_rendimiento()
		"exportar":
			_abrir_exportar()
		"tipos":
			_abrir_tipos()


func _abrir_juego(que: String) -> void:
	_cerrar_modal()
	var pj := PanelJuego.new()
	pj.modo = "mec" if que == "mecanicas" else "fis"
	add_child(pj)
	move_child(_tut, get_child_count() - 1)
	_modal = pj
	pj.cerrar.connect(_cerrar_modal)


func _abrir_modal_simple(p: Control) -> void:
	_cerrar_modal()
	add_child(p)
	move_child(_tut, get_child_count() - 1)
	_modal = p
	p.cerrar.connect(_cerrar_modal)


func _abrir_pista() -> void:
	_cerrar_modal()
	var pp := PanelPista.new()
	add_child(pp)
	move_child(_tut, get_child_count() - 1)
	_modal = pp
	pp.cerrar.connect(_cerrar_modal)
	pp.cambiado.connect(func():
		_esc.queue_redraw()
		_refrescar_niveles())


func _abrir_creador() -> void:
	_cerrar_modal()
	var pc := PanelCreador.new()
	add_child(pc)
	move_child(_tut, get_child_count() - 1)
	_modal = pc
	pc.cerrar.connect(_cerrar_modal)
	pc.guardado.connect(func(_id):
		if _etapa == "mundo":
			_cambiar_tab("mis"))
	pc.animar.connect(func(): _abrir_modal_simple(PanelHoja.new()))


func _abrir_elementos() -> void:
	_cerrar_modal()
	var pe := PanelElementos.new()
	add_child(pe)
	move_child(_tut, get_child_count() - 1)
	_modal = pe
	pe.cerrar.connect(_cerrar_modal)
	pe.cambiado.connect(func():
		_esc.queue_redraw()
		_refrescar_niveles())


func _cerrar_modal() -> void:
	_modal_es_reglas = false
	if _prev_audio and _prev_audio.playing:
		_prev_audio.stop()
	if _modal:
		_modal.queue_free()
		_modal = null


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
