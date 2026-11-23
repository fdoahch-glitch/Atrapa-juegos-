extends ColorRect
## Panel «Efectos y sonido»: sonido por evento, partículas, cámara, luces, filtro de pantalla,
## transición entre niveles, idioma y créditos.

signal cerrar

const Estilo := preload("res://scripts/estilo.gd")
const Imp := preload("res://scripts/importar.gd")
const Sonido := preload("res://scripts/sonido.gd")

var _sn: Node


func _ready() -> void:
	color = Color(0.08, 0.06, 0.23, 0.62)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Datos.reglas = Datos.reglas_completas(Datos.reglas)
	_sn = Sonido.new()
	add_child(_sn)
	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(660.0, maxf(320.0, size.x - 24.0)), 0)
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 26, 0, Color.TRANSPARENT, 22))
	centro.add_child(panel)
	var ext := VBoxContainer.new()
	ext.add_theme_constant_override("separation", 8)
	panel.add_child(ext)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, minf(610.0, maxf(280.0, size.y - 130.0)))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ext.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	sc.add_child(v)
	_t(v, "Efectos y sonido", 28, Estilo.TINTA, true)
	_t(v, "Sonidos", 20, Estilo.MORADO, true)
	var audios: Array = Imp.listar().filter(func(a): return Imp.es_audio(a["id"]))
	for e in Datos.SFX_EVENTOS:
		var ids: Array = Datos.SFX_NOMBRES.keys()
		var nombres: Array = []
		for k in ids:
			nombres.append(Datos.SFX_NOMBRES[k])
		for a in audios:
			ids.append(a["id"])
			nombres.append("♪ " + str(a["n"]))
		var cur := str(Datos.reglas["sonidos"][e[0]])
		var fila := _opciones(v, str(e[1]), ids, nombres, cur, func(val):
			var d: Dictionary = Datos.reglas["sonidos"]
			d[e[0]] = val
			Datos.reglas["sonidos"] = d
			Datos.guardar()
			_probar(str(val)))
		fila.tooltip_text = "Elige el sonido"
	_t(v, "Partículas", 20, Estilo.MORADO, true)
	_t(v, "Las decoraciones también pueden echar partículas: tócalas en el mundo y elige «Part».", 14, Estilo.SUAVE)
	for e in Datos.FX_EVENTOS:
		var ids2: Array = []
		var nom2: Array = []
		for p in Datos.PART_TIPOS:
			ids2.append(p[0])
			nom2.append(p[1])
		_opciones(v, str(e[1]), ids2, nom2, str(Datos.reglas["fx"][e[0]]), func(val):
			var d: Dictionary = Datos.reglas["fx"]
			d[e[0]] = val
			Datos.reglas["fx"] = d
			Datos.guardar())
	_t(v, "Cámara", 20, Estilo.MORADO, true)
	_barra(v, "Suavidad al seguirte", "Brusca", "Muy suave", 30.0, 300.0, float(Datos.reglas["cam_suave"]), func(x):
		Datos.reglas["cam_suave"] = int(x)
		Datos.guardar())
	_opciones(v, "Tiembla al golpear", [true, false], ["Sí", "No"], bool(Datos.reglas["cam_temblor"]), func(val):
		Datos.reglas["cam_temblor"] = bool(val)
		Datos.guardar())
	_t(v, "Luces y pantalla (este mundo)", 20, Estilo.MORADO, true)
	_barra(v, "Oscuridad (cueva con linterna)", "Día", "Muy oscuro", 0.0, 0.95, float(Datos.nivel.get("oscuridad", 0.0)), func(x):
		if x < 0.05:
			Datos.nivel.erase("oscuridad")
		else:
			Datos.nivel["oscuridad"] = x
		Datos.guardar())
	var fi: Array = []
	var fn: Array = []
	for f in Datos.FILTROS:
		fi.append(f[0])
		fn.append(f[1])
	_opciones(v, "Filtro de pantalla", fi, fn, str(Datos.nivel.get("filtro", "")), func(val):
		if str(val) == "":
			Datos.nivel.erase("filtro")
		else:
			Datos.nivel["filtro"] = val
		Datos.guardar())
	_t(v, "Juego completo", 20, Estilo.MORADO, true)
	var ti: Array = []
	var tn: Array = []
	for x in Datos.TRANSICIONES:
		ti.append(x[0])
		tn.append(x[1])
	_opciones(v, "Transición entre niveles", ti, tn, str(Datos.reglas["trans"]), func(val):
		Datos.reglas["trans"] = val
		Datos.guardar())
	_opciones(v, "Idioma de los textos del juego", ["es", "en"], ["Español", "English"], str(Datos.reglas["idioma"]), func(val):
		Datos.reglas["idioma"] = val
		Datos.guardar())
	_t(v, "Créditos (se ven en el menú de pausa)", 16, Estilo.TINTA, false)
	var le := LineEdit.new()
	le.placeholder_text = "Hecho por…"
	le.max_length = 120
	le.text = str(Datos.reglas["creditos"])
	le.custom_minimum_size = Vector2(0, 44)
	le.text_changed.connect(func(tx: String):
		Datos.reglas["creditos"] = tx
		Datos.guardar())
	v.add_child(le)
	var b := Button.new()
	b.text = "Listo"
	b.custom_minimum_size = Vector2(0, 52)
	Estilo.pintar(b, Estilo.VERDE)
	b.pressed.connect(func(): cerrar.emit())
	ext.add_child(b)


func _probar(id: String) -> void:
	if Datos.SFX_PRE.has(id):
		var d: Array = Datos.SFX_PRE[id]
		_sn.tocar(float(d[0]), float(d[1]), str(d[2]))
	elif id.begins_with("m:"):
		var st := Imp.cargar_audio(id)
		if st != null:
			var p := AudioStreamPlayer.new()
			p.stream = st
			add_child(p)
			p.finished.connect(p.queue_free)
			p.play()


func _t(v: Control, s: String, tam: int, col: Color, _titulo: bool = false) -> void:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)


func _opciones(v: Control, titulo: String, ids: Array, nombres: Array, actual: Variant, al_elegir: Callable) -> HBoxContainer:
	var f := HBoxContainer.new()
	f.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = titulo
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_color_override("font_color", Estilo.TINTA)
	f.add_child(l)
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(190, 42)
	ob.focus_mode = Control.FOCUS_NONE
	for i in ids.size():
		ob.add_item(str(nombres[i]), i)
		if ids[i] == actual:
			ob.selected = i
	ob.item_selected.connect(func(i): al_elegir.call(ids[i]))
	f.add_child(ob)
	v.add_child(f)
	return f


func _barra(v: Control, titulo: String, izq: String, der: String, mn: float, mx: float, valor: float, al_cambiar: Callable) -> void:
	_t(v, titulo, 16, Estilo.TINTA, false)
	var sl := HSlider.new()
	sl.min_value = mn
	sl.max_value = mx
	sl.step = (mx - mn) / 40.0
	sl.value = valor
	sl.custom_minimum_size = Vector2(0, 28)
	sl.focus_mode = Control.FOCUS_NONE
	sl.value_changed.connect(func(x): al_cambiar.call(x))
	v.add_child(sl)
	var ex := HBoxContainer.new()
	for par in [izq, der]:
		var a := Label.new()
		a.text = par
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		a.add_theme_color_override("font_color", Estilo.SUAVE)
		a.add_theme_font_size_override("font_size", 13)
		if par == der:
			a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ex.add_child(a)
	v.add_child(ex)
