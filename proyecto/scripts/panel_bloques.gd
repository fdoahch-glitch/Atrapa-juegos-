extends ColorRect
## Panel «Bloques»: programa el nivel apilando bloques de colores, como en Scratch.
## Un bloque «cuando…» arriba y, debajo, los bloques que se hacen en orden.

signal cerrar

const Estilo := preload("res://scripts/estilo.gd")

var _caja: VBoxContainer
var _lista: Array = []


func _ready() -> void:
	color = Color(0.08, 0.06, 0.23, 0.62)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var l0: Variant = Datos.nivel.get("programa", [])
	_lista = (l0 as Array).duplicate(true) if l0 is Array else []
	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(720.0, maxf(320.0, size.x - 24.0)), 0)
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 26, 0, Color.TRANSPARENT, 22))
	centro.add_child(panel)
	var ext := VBoxContainer.new()
	ext.add_theme_constant_override("separation", 8)
	panel.add_child(ext)
	var tit := Label.new()
	tit.text = "Bloques"
	tit.add_theme_font_size_override("font_size", 28)
	tit.add_theme_color_override("font_color", Estilo.TINTA)
	ext.add_child(tit)
	var sub := Label.new()
	sub.text = "Apila bloques para programar sin escribir código. El bloque de arriba dice CUÁNDO empieza; los de abajo se hacen en orden."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_color_override("font_color", Estilo.SUAVE)
	ext.add_child(sub)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, minf(440.0, maxf(220.0, size.y - 260.0)))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ext.add_child(sc)
	_caja = VBoxContainer.new()
	_caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_caja.add_theme_constant_override("separation", 14)
	sc.add_child(_caja)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	ext.add_child(h)
	var nuevo := Button.new()
	nuevo.text = "  ➕ Pila nueva"
	nuevo.name = "NuevaPila"
	nuevo.custom_minimum_size = Vector2(0, 50)
	nuevo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Estilo.pintar(nuevo, Estilo.MORADO)
	nuevo.pressed.connect(func():
		if _lista.size() < 12:
			_lista.append({"cuando": "monedas", "n": 5, "pasos": [{"b": "mensaje", "txt": "¡Muy bien!", "v": 1}]})
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
		Datos.nivel.erase("programa")
	else:
		Datos.nivel["programa"] = _lista.duplicate(true)
	Datos.guardar()


func _etq(f: Control, s: String, blanco: bool = true) -> void:
	var l := Label.new()
	l.text = s
	l.add_theme_color_override("font_color", Color.WHITE if blanco else Estilo.TINTA)
	l.add_theme_font_size_override("font_size", 17)
	f.add_child(l)


func _pintar() -> void:
	for c in _caja.get_children():
		c.queue_free()
	if _lista.is_empty():
		var l := Label.new()
		l.text = "Todavía no hay bloques. Toca «Pila nueva»."
		l.add_theme_color_override("font_color", Estilo.SUAVE)
		_caja.add_child(l)
	for i in _lista.size():
		var pr: Dictionary = _lista[i]
		var pila := VBoxContainer.new()
		pila.add_theme_constant_override("separation", 2)
		pila.name = "Pila%d" % i
		_caja.add_child(pila)
		# bloque «cuando»
		_hat(pila, pr, i)
		# pasos
		var pasos: Array = pr["pasos"]
		for j in pasos.size():
			_paso(pila, pasos, j)
		# añadir bloque
		var add := OptionButton.new()
		add.name = "AnadirBloque"
		add.focus_mode = Control.FOCUS_NONE
		add.custom_minimum_size = Vector2(240, 38)
		add.add_item("➕ Añadir bloque…", 0)
		for k in Datos.BLOQ_PASOS.size():
			add.add_item(str(Datos.BLOQ_PASOS[k][1]), k + 1)
		add.item_selected.connect(func(idx: int):
			if idx <= 0 or pasos.size() >= Datos.BLOQ_MAX:
				return
			var b: Array = Datos.BLOQ_PASOS[idx - 1]
			pasos.append({"b": b[0], "txt": "¡Hola!" if b[0] == "mensaje" else "", "v": 1 if b[3] == "num" else 0})
			_guardar()
			_pintar())
		pila.add_child(add)


func _hat(pila: VBoxContainer, pr: Dictionary, i: int) -> void:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Estilo.caja(Color("ffa31a"), 14, 0, Color.TRANSPARENT, 8))
	pila.add_child(pc)
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 8)
	pc.add_child(f)
	_etq(f, "🚩 CUANDO")
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	ob.custom_minimum_size = Vector2(190, 38)
	for k in Datos.BLOQ_CUANDO.size():
		ob.add_item(str(Datos.BLOQ_CUANDO[k][1]), k)
		if Datos.BLOQ_CUANDO[k][0] == str(pr["cuando"]):
			ob.selected = k
	ob.item_selected.connect(func(k: int):
		pr["cuando"] = Datos.BLOQ_CUANDO[k][0]
		_guardar())
	f.add_child(ob)
	var sb := SpinBox.new()
	sb.min_value = 1
	sb.max_value = 9999
	sb.value = float(pr["n"])
	sb.value_changed.connect(func(x):
		pr["n"] = int(x)
		_guardar())
	f.add_child(sb)
	var del := Button.new()
	del.text = "🗑 Borrar pila"
	del.pressed.connect(func():
		_lista.remove_at(i)
		_guardar()
		_pintar())
	f.add_child(del)


func _paso(pila: VBoxContainer, pasos: Array, j: int) -> void:
	var st: Dictionary = pasos[j]
	var def: Array = []
	for d in Datos.BLOQ_PASOS:
		if d[0] == str(st["b"]):
			def = d
	if def.is_empty():
		return
	var pc := PanelContainer.new()
	pc.name = "Bloque%d" % j
	pc.add_theme_stylebox_override("panel", Estilo.caja(Color(str(def[2])), 12, 0, Color.TRANSPARENT, 8))
	pila.add_child(pc)
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 8)
	pc.add_child(f)
	_etq(f, str(def[1]))
	if def[3] == "txt":
		var le := LineEdit.new()
		le.text = str(st.get("txt", ""))
		le.max_length = 60
		le.custom_minimum_size = Vector2(200, 36)
		le.text_changed.connect(func(tx):
			st["txt"] = tx
			_guardar())
		f.add_child(le)
	elif def[3] == "num":
		var sv := SpinBox.new()
		sv.min_value = 1
		sv.max_value = 9999
		sv.value = float(st.get("v", 1))
		sv.value_changed.connect(func(x):
			st["v"] = int(x)
			_guardar())
		f.add_child(sv)
	for acc in [["⬆", -1], ["⬇", 1]]:
		var b := Button.new()
		b.text = acc[0]
		b.pressed.connect(func():
			var k: int = j + int(acc[1])
			if k >= 0 and k < pasos.size():
				var tmp = pasos[j]
				pasos[j] = pasos[k]
				pasos[k] = tmp
				_guardar()
				_pintar())
		f.add_child(b)
	var del := Button.new()
	del.text = "🗑"
	del.pressed.connect(func():
		pasos.remove_at(j)
		_guardar()
		_pintar())
	f.add_child(del)
