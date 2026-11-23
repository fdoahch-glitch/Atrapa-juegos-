extends ColorRect
## Panel «Elementos del mundo»: lista de todo lo que tiene este mundo 3D (personaje, obstáculos, premios y adornos).
## Cada elemento se puede reemplazar por uno de tus modelos, y los adornos se activan o desactivan con un toque.

signal cerrar
signal cambiado

const Estilo := preload("res://scripts/estilo.gd")
const Imp := preload("res://scripts/importar.gd")

var _mods: Array = []


func _ready() -> void:
	color = Color(0.08, 0.06, 0.23, 0.65)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mods = Imp.listar().filter(func(a): return str(a["id"]).begins_with("g:"))
	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(760.0, maxf(320.0, size.x - 30.0)), 0)
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 26, 0, Color.TRANSPARENT, 20))
	centro.add_child(panel)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, minf(640.0, maxf(300.0, size.y - 60.0)))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	sc.add_child(v)
	_titulo(v, "🌍 Elementos de «%s»" % str(Datos.nivel.get("name", "este mundo")), 28)
	_titulo(v, "Personaje", 20)
	_modelo(v, "Quién corre", "hero", true)
	_numero(v, "Tamaño real (alto en metros)", "hero_alto", 0.5, 6.0, 0.1, 1.7)
	_titulo(v, "Obstáculos", 20)
	for par in [["valla", "Bajo (se salta)"], ["pared", "Alto (se esquiva)"], ["viga", "Por arriba (se agacha)"]]:
		_modelo(v, par[1], "obstaculos:" + par[0])
	_titulo(v, "Premios", 20)
	for par in [["coin", "Moneda"], ["star", "Estrella"], ["gem", "Gema"]]:
		_modelo(v, par[1], "premios:" + par[0])
	_titulo(v, "Adornos de los lados (activa o desactiva)", 20)
	if _mods.is_empty():
		_texto(v, "Aún no hay modelos. Abre un juego con modelos (por ejemplo Dino Run) o importa los tuyos.", 15)
	var act: Array = Datos.nivel.get("decorado", []) as Array
	for m in _mods:
		var f := HBoxContainer.new()
		v.add_child(f)
		var cb := CheckBox.new()
		cb.text = str(m.get("n", m["id"]))
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var previo := act.filter(func(x): return str(x["e"]) == str(m["id"]))
		cb.button_pressed = previo.size() > 0
		var mid: String = str(m["id"])
		cb.toggled.connect(func(on):
			var d: Array = (Datos.nivel.get("decorado", []) as Array).filter(func(x): return str(x["e"]) != mid)
			if on:
				d.append({"e": mid, "alto": 3.0})
			Datos.nivel["decorado"] = d
			Datos.guardar()
			cambiado.emit())
		f.add_child(cb)
		var sb := SpinBox.new()
		sb.min_value = 0.3
		sb.max_value = 30.0
		sb.step = 0.1
		sb.suffix = " m"
		sb.value = float(previo[0].get("alto", 3.0)) if previo.size() > 0 else 3.0
		sb.value_changed.connect(func(x):
			var d: Array = Datos.nivel.get("decorado", []) as Array
			for e in d:
				if str(e["e"]) == mid:
					e["alto"] = x
			Datos.guardar()
			cambiado.emit())
		f.add_child(sb)
	var c := Button.new()
	c.text = "  Cerrar"
	c.custom_minimum_size = Vector2(0, 46)
	c.pressed.connect(func(): cerrar.emit())
	v.add_child(c)


func _titulo(v: Control, t: String, tam: int) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", Estilo.TINTA)
	v.add_child(l)


func _texto(v: Control, t: String, tam: int) -> void:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", Estilo.SUAVE)
	v.add_child(l)


## Una fila «nombre + lista de modelos». clave: "hero" o "grupo:nombre" (obstaculos:valla, premios:gem).
func _modelo(v: Control, nombre: String, clave: String, es_heroe: bool = false) -> void:
	var f := HBoxContainer.new()
	v.add_child(f)
	var l := Label.new()
	l.text = nombre
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 17)
	f.add_child(l)
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(240, 40)
	ob.add_item("Por defecto", 0)
	var grupo := ""
	var nom := clave
	if clave.contains(":"):
		grupo = clave.split(":")[0]
		nom = clave.split(":")[1]
	var actual := ""
	if grupo == "":
		actual = str(Datos.nivel.get(nom, ""))
	else:
		var d: Variant = Datos.nivel.get(grupo, {})
		if d is Dictionary and d.has(nom):
			actual = str(d[nom][0]) if d[nom] is Array else str(d[nom])
	var sel := 0
	for i in _mods.size():
		ob.add_item(str(_mods[i].get("n", _mods[i]["id"])), i + 1)
		if str(_mods[i]["id"]) == actual:
			sel = i + 1
	ob.selected = sel
	ob.item_selected.connect(func(i):
		if grupo == "":
			if i > 0:
				Datos.nivel[nom] = _mods[i - 1]["id"]
		else:
			var d2: Dictionary = Datos.nivel.get(grupo, {}) if Datos.nivel.get(grupo, {}) is Dictionary else {}
			if i == 0:
				d2.erase(nom)
			else:
				d2[nom] = _mods[i - 1]["id"]
			Datos.nivel[grupo] = d2
		Datos.guardar()
		cambiado.emit())
	f.add_child(ob)


func _numero(v: Control, nombre: String, clave: String, mn: float, mx: float, paso: float, def: float) -> void:
	var f := HBoxContainer.new()
	v.add_child(f)
	var l := Label.new()
	l.text = nombre
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 17)
	f.add_child(l)
	var sb := SpinBox.new()
	sb.min_value = mn
	sb.max_value = mx
	sb.step = paso
	sb.value = float(Datos.nivel.get(clave, def))
	sb.value_changed.connect(func(x):
		Datos.nivel[clave] = x
		Datos.guardar()
		cambiado.emit())
	f.add_child(sb)
