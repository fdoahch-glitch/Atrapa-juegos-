extends ColorRect
## Panel «Eventos»: reglas «si pasa esto, haz aquello» para el mundo que estás editando.

signal cerrar

const Estilo := preload("res://scripts/estilo.gd")

var _caja: VBoxContainer
var _lista: Array = []


func _ready() -> void:
	color = Color(0.08, 0.06, 0.23, 0.62)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var l0: Variant = Datos.nivel.get("eventos", [])
	_lista = (l0 as Array).duplicate(true) if l0 is Array else []
	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(700.0, maxf(320.0, size.x - 24.0)), 0)
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 26, 0, Color.TRANSPARENT, 22))
	centro.add_child(panel)
	var ext := VBoxContainer.new()
	ext.add_theme_constant_override("separation", 8)
	panel.add_child(ext)
	var tit := Label.new()
	tit.text = "Eventos"
	tit.add_theme_font_size_override("font_size", 28)
	tit.add_theme_color_override("font_color", Estilo.TINTA)
	ext.add_child(tit)
	var sub := Label.new()
	sub.text = "«Si pasa esto, haz aquello». Ejemplo: si recojo 10 monedas, abre las puertas. Las puertas y llaves están en Objetos."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_color_override("font_color", Estilo.SUAVE)
	ext.add_child(sub)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, minf(420.0, maxf(220.0, size.y - 260.0)))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ext.add_child(sc)
	_caja = VBoxContainer.new()
	_caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_caja.add_theme_constant_override("separation", 10)
	sc.add_child(_caja)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	ext.add_child(h)
	var nuevo := Button.new()
	nuevo.text = "  ➕ Evento nuevo"
	nuevo.custom_minimum_size = Vector2(0, 50)
	nuevo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Estilo.pintar(nuevo, Estilo.MORADO)
	nuevo.pressed.connect(func():
		_lista.append({"si": "monedas", "n": 5, "haz": "mensaje", "txt": "¡Muy bien!", "v": 1})
		_guardar()
		_pintar())
	h.add_child(nuevo)
	var ok := Button.new()
	ok.text = "Listo"
	ok.custom_minimum_size = Vector2(120, 50)
	Estilo.pintar(ok, Estilo.VERDE)
	ok.pressed.connect(func(): cerrar.emit())
	h.add_child(ok)
	_pintar()


func _guardar() -> void:
	if _lista.is_empty():
		Datos.nivel.erase("eventos")
	else:
		Datos.nivel["eventos"] = _lista.duplicate(true)
	Datos.guardar()


func _pintar() -> void:
	for c in _caja.get_children():
		c.queue_free()
	if _lista.is_empty():
		var l := Label.new()
		l.text = "Todavía no hay eventos. Toca «Evento nuevo»."
		l.add_theme_color_override("font_color", Estilo.SUAVE)
		_caja.add_child(l)
	for i in _lista.size():
		var ev: Dictionary = _lista[i]
		var tarjeta := PanelContainer.new()
		tarjeta.add_theme_stylebox_override("panel", Estilo.caja(Color("f1efff"), 16, 0, Color.TRANSPARENT, 10))
		_caja.add_child(tarjeta)
		var f := HFlowContainer.new()
		f.add_theme_constant_override("h_separation", 8)
		f.add_theme_constant_override("v_separation", 6)
		tarjeta.add_child(f)
		_etq(f, "SI")
		f.add_child(_opcion(Datos.EVENTOS_SI, str(ev["si"]), func(v):
			ev["si"] = v
			_guardar()))
		var sb := SpinBox.new()
		sb.min_value = 1
		sb.max_value = 9999
		sb.value = float(ev["n"])
		sb.value_changed.connect(func(x):
			ev["n"] = int(x)
			_guardar())
		f.add_child(sb)
		_etq(f, "ENTONCES")
		f.add_child(_opcion(Datos.EVENTOS_HAZ, str(ev["haz"]), func(v):
			ev["haz"] = v
			_guardar()
			_pintar()))
		var haz := str(ev["haz"])
		if haz == "mensaje":
			var le := LineEdit.new()
			le.text = str(ev.get("txt", ""))
			le.placeholder_text = "Mensaje"
			le.max_length = 60
			le.custom_minimum_size = Vector2(220, 40)
			le.text_changed.connect(func(tx):
				ev["txt"] = tx
				_guardar())
			f.add_child(le)
		elif haz == "vida" or haz == "puntos":
			var sv := SpinBox.new()
			sv.min_value = 1
			sv.max_value = 9999
			sv.value = float(ev.get("v", 1))
			sv.value_changed.connect(func(x):
				ev["v"] = int(x)
				_guardar())
			f.add_child(sv)
		var del := Button.new()
		del.text = "🗑"
		del.pressed.connect(func():
			_lista.remove_at(i)
			_guardar()
			_pintar())
		f.add_child(del)


func _etq(f: Control, s: String) -> void:
	var l := Label.new()
	l.text = s
	l.add_theme_color_override("font_color", Estilo.MORADO)
	l.add_theme_font_size_override("font_size", 15)
	f.add_child(l)


func _opcion(lista: Array, actual: String, al_elegir: Callable) -> OptionButton:
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(190, 40)
	ob.focus_mode = Control.FOCUS_NONE
	for i in lista.size():
		ob.add_item(str(lista[i][1]), i)
		if lista[i][0] == actual:
			ob.selected = i
	ob.item_selected.connect(func(i): al_elegir.call(lista[i][0]))
	return ob
