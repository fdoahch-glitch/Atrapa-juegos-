extends ColorRect
## Panel «Rendimiento y Testear»: calidad por plataforma + informe de errores con «Aplicar corrección».

signal cerrar
signal corregido

const Estilo := preload("res://scripts/estilo.gd")
const Rend := preload("res://scripts/rendimiento.gd")

var _lista: VBoxContainer
var _resumen: Label
var _ops := {}


func _ready() -> void:
	color = Color(0.08, 0.06, 0.23, 0.7)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(980.0, maxf(360.0, size.x - 40.0)), minf(640.0, maxf(300.0, size.y - 40.0)))
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 26, 0, Color.TRANSPARENT, 18))
	centro.add_child(panel)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	sc.add_child(v)
	_titulo(v, "Rendimiento y calidad")
	var plataforma := str(Datos.reglas.get("plataforma", "windows"))
	var perf: Dictionary = Rend.PERFILES.get(plataforma, Rend.PERFILES["windows"])
	_texto(v, "Tu juego es para %s. %s" % [perf["nombre"], perf["nota"]], 17, Estilo.SUAVE)
	# ---- niveles de calidad (un toque cambia todo)
	_texto(v, "Nivel de calidad", 20, Estilo.TINTA)
	var nivs := HBoxContainer.new()
	nivs.add_theme_constant_override("separation", 8)
	v.add_child(nivs)
	for q in Rend.CALIDADES:
		var bq := Button.new()
		bq.text = str(q["nombre"])
		bq.tooltip_text = str(q["txt"])
		bq.custom_minimum_size = Vector2(0, 46)
		bq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Estilo.pintar(bq, Estilo.TURQUESA)
		var qid: String = q["id"]
		bq.pressed.connect(func():
			Datos.reglas["rend"] = Rend.calidad(qid, plataforma)
			Datos.guardar()
			corregido.emit()
			cerrar.emit())
		nivs.add_child(bq)
	_texto(v, "Baja: celulares viejos · Media: celulares y PC normales · Alta: PC con tarjeta gráfica (usa FSR 2.2).", 15, Estilo.SUAVE)
	# ---- opciones
	var r: Dictionary = Datos.reglas["rend"]
	_ops = {}
	_fila(v, "Motor gráfico", "render", Rend.RENDERS, r["render"])
	_fila(v, "Escalado de imagen", "escalado", Rend.ESCALADOS, r["escalado"])
	_fila(v, "Calidad de imagen", "escala", [[1.0, "100 % (nítida)"], [0.85, "85 %"], [0.75, "75 % (más rápida)"], [0.6, "60 %"], [0.5, "50 % (muy rápida)"]], r["escala"])
	_fila(v, "Bordes suaves (MSAA)", "msaa", [[0, "Apagado"], [2, "2×"], [4, "4×"], [8, "8×"]], r["msaa"])
	_fila(v, "Brillo suave (bloom, 3D)", "bloom", [[false, "Apagado"], [true, "Encendido"]], r["bloom"])
	_fila(v, "Sombras (3D)", "sombras", [[false, "Apagadas"], [true, "Encendidas"]], r["sombras"])
	_fila(v, "Límite de FPS", "fps", [[30, "30 (ahorra batería)"], [60, "60"], [120, "120"], [0, "Sin límite"]], r["fps"])
	var rec := Button.new()
	rec.text = "  Usar lo recomendado para %s" % perf["nombre"]
	rec.icon = Datos.textura("✨")
	rec.expand_icon = true
	rec.add_theme_constant_override("icon_max_width", 26)
	rec.custom_minimum_size = Vector2(0, 46)
	Estilo.pintar(rec, Estilo.TURQUESA)
	rec.pressed.connect(func():
		Datos.reglas["rend"] = Rend.recomendado(plataforma)
		Datos.guardar()
		corregido.emit()
		cerrar.emit())
	v.add_child(rec)
	_texto(v, "El motor gráfico se aplica al exportar para PC. Las demás opciones se notan al jugar.", 15, Estilo.SUAVE)
	v.add_child(HSeparator.new())
	# ---- testear
	_titulo(v, "Testear mi juego")
	_texto(v, "Reviso todos tus mundos y la portada: inicio, meta, objetos tapados o inalcanzables, imágenes pesadas y calidad.", 17, Estilo.SUAVE)
	var t := Button.new()
	t.text = "  Testear ahora"
	t.icon = Datos.textura("✅")
	t.expand_icon = true
	t.add_theme_constant_override("icon_max_width", 26)
	t.custom_minimum_size = Vector2(0, 52)
	Estilo.pintar(t, Estilo.AMARILLO, Color("4a3300"))
	t.pressed.connect(_testear)
	v.add_child(t)
	_resumen = _texto(v, "", 19, Estilo.TINTA)
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 8)
	v.add_child(_lista)
	var c := Button.new()
	c.text = "  Cerrar"
	c.icon = null
	c.custom_minimum_size = Vector2(0, 46)
	c.pressed.connect(func(): cerrar.emit())
	v.add_child(c)


func _titulo(v: Control, t: String) -> void:
	_texto(v, t, 28, Estilo.TINTA)


func _texto(v: Control, t: String, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	l.custom_minimum_size = Vector2(300, 0)
	v.add_child(l)
	return l


func _fila(v: Control, nombre: String, clave: String, opciones: Array, actual: Variant) -> void:
	var f := HBoxContainer.new()
	var l := Label.new()
	l.text = nombre
	l.custom_minimum_size = Vector2(210, 0)
	l.add_theme_color_override("font_color", Estilo.TINTA)
	f.add_child(l)
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(300, 42)
	var sel := 0
	for i in opciones.size():
		ob.add_item(str(opciones[i][1]), i)
		if str(opciones[i][0]) == str(actual):
			sel = i
	ob.selected = sel
	ob.item_selected.connect(func(i):
		var rr: Dictionary = Datos.reglas["rend"]
		rr[clave] = opciones[i][0]
		Datos.reglas["rend"] = Rend.normal(rr)
		Datos.guardar())
	f.add_child(ob)
	v.add_child(f)


func _testear() -> void:
	for c in _lista.get_children():
		c.queue_free()
	var res := Rend.analizar(Datos.proyecto())
	var e := 0
	var a := 0
	for p in res:
		if p["sev"] == "error":
			e += 1
		elif p["sev"] == "aviso":
			a += 1
	if res.is_empty():
		_resumen.text = "¡Todo en orden! No encontré problemas."
		return
	_resumen.text = "Encontré %d cosas: %d errores, %d avisos y %d consejos." % [res.size(), e, a, res.size() - e - a]
	var todo := Button.new()
	todo.text = "  Aplicar todas las correcciones"
	todo.custom_minimum_size = Vector2(0, 46)
	Estilo.pintar(todo, Estilo.TURQUESA)
	todo.pressed.connect(func():
		var n := 0
		# se corrige de a una, volviendo a revisar para no usar datos viejos
		for k in 40:
			var lista := Rend.analizar(Datos.proyecto())
			var hecho := false
			for p in lista:
				if Rend.corregir(p):
					n += 1
					hecho = true
					break
			if not hecho:
				break
		corregido.emit()
		_testear()
		_resumen.text = "Corregí %d cosas. " % n + _resumen.text)
	_lista.add_child(todo)
	for p in res:
		var caja := PanelContainer.new()
		var col: Color = {"error": Color("ffe3e3"), "aviso": Color("fff4d6"), "consejo": Color("e3f2ff")}[p["sev"]]
		caja.add_theme_stylebox_override("panel", Estilo.caja(col, 14, 0, Color.TRANSPARENT, 10))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		caja.add_child(h)
		var ic := TextureRect.new()
		ic.texture = Datos.textura({"error": "😵", "aviso": "⏰", "consejo": "✨"}[p["sev"]])
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(34, 34)
		h.add_child(ic)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(tv)
		_texto(tv, str(p["txt"]), 17, Estilo.TINTA)
		_texto(tv, "Solución: " + str(p["sol"]), 15, Estilo.SUAVE)
		var b := Button.new()
		b.text = "Aplicar corrección"
		b.custom_minimum_size = Vector2(190, 44)
		Estilo.pintar(b, Estilo.MORADO)
		b.pressed.connect(func():
			if Rend.corregir(p):
				corregido.emit()
				_testear()
			else:
				b.text = "No pude arreglarlo"
				b.disabled = true)
		h.add_child(b)
		_lista.add_child(caja)
