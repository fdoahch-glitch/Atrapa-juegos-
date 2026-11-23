extends ColorRect
## Panel «Colores del mundo»: cambia el cielo, las colinas y el suelo de este mundo sin salir del editor.

signal cerrar
signal cambiado

const Estilo := preload("res://scripts/estilo.gd")

var _selectores := {}


func _ready() -> void:
	color = Color(0.08, 0.06, 0.23, 0.6)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(520.0, maxf(320.0, size.x - 30.0)), 0)
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 26, 0, Color.TRANSPARENT, 22))
	centro.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, minf(660.0, maxf(300.0, size.y - 60.0)))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	scroll.add_child(v)
	_texto(v, "Colores de este mundo", 28, Estilo.TINTA)
	_texto(v, "Toca un color para cambiarlo. Se ve al instante en el mundo.", 15, Estilo.SUAVE)
	var t: Dictionary = Datos.tema_de(Datos.nivel)
	_fila(v, "cielo_a", "Cielo (arriba)", t["cielo"][0])
	_fila(v, "cielo_b", "Cielo (horizonte)", t["cielo"][1])
	_fila(v, "lejos", "Colinas lejanas", t["lejos"])
	_fila(v, "cerca", "Colinas cercanas", t["cerca"])
	_fila(v, "tierra", "Tierra (plataformas y pista)", t["plat"][0])
	_fila(v, "pasto", "Pasto o superficie", t["plat"][1])
	if str(Datos.nivel.get("tipo", "")) in ["carrera", "corredor", "3d"] or bool(Datos.nivel.get("vista3d", false)):
		_texto(v, "Ambiente (mundos 3D)", 20, Estilo.TINTA)
		_opcion(v, "Clima", "clima", [["", "Despejado"], ["lluvia", "Lluvia"], ["tormenta", "Tormenta con rayos"], ["nieve", "Nieve"], ["ventisca", "Ventisca"], ["erupcion", "Erupción volcánica"], ["variable", "Cambia solo"]])
		_opcion(v, "Hora del día", "hora", [["", "Según el tema"], ["dia", "Día"], ["atardecer", "Atardecer"], ["noche", "Noche"], ["ciclo", "Ciclo (va pasando)"]])
		_opcion(v, "Perseguidor (te alcanza si chocas)", "perseguidor", [[false, "No"], [true, "Sí"]])
		_opcion(v, "Cantidad de objetos", "densidad", [[0.5, "Pocos"], [1.0, "Normal"], [1.5, "Muchos"]])
		_objetos(v)
		_tramos(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	var rest := Button.new()
	rest.text = "  Volver a los colores del tema"
	rest.custom_minimum_size = Vector2(0, 44)
	rest.pressed.connect(func():
		Datos.nivel.erase("paleta")
		Datos.guardar()
		cambiado.emit()
		cerrar.emit())
	h.add_child(rest)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(sp)
	var c := Button.new()
	c.text = "Listo"
	c.custom_minimum_size = Vector2(110, 44)
	Estilo.pintar(c, Estilo.MORADO)
	c.pressed.connect(func(): cerrar.emit())
	h.add_child(c)


func _fila(padre: Control, clave: String, nombre: String, col: Color) -> void:
	var f := HBoxContainer.new()
	padre.add_child(f)
	var l := Label.new()
	l.text = nombre
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 18)
	f.add_child(l)
	var cp := ColorPickerButton.new()
	cp.color = col
	cp.edit_alpha = false
	cp.custom_minimum_size = Vector2(120, 40)
	cp.color_changed.connect(func(_c: Color): _aplicar())
	f.add_child(cp)
	_selectores[clave] = cp


## Qué se ve en la pista: el modelo de cada obstáculo y los objetos que adornan los lados.
func _objetos(padre: Control) -> void:
	var Imp := preload("res://scripts/importar.gd")
	var mods: Array = Imp.listar().filter(func(a): return str(a["id"]).begins_with("g:"))
	_texto(padre, "Objetos de la pista (tus modelos)", 20, Estilo.TINTA)
	var obs: Dictionary = Datos.nivel.get("obstaculos", {}) if Datos.nivel.get("obstaculos", {}) is Dictionary else {}
	for par in [["valla", "Obstáculo bajo (se salta)"], ["pared", "Obstáculo alto (se esquiva)"], ["viga", "Obstáculo por arriba (se agacha)"]]:
		var f := HBoxContainer.new()
		padre.add_child(f)
		var l := Label.new()
		l.text = par[1]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_theme_font_size_override("font_size", 18)
		f.add_child(l)
		var ob := OptionButton.new()
		ob.custom_minimum_size = Vector2(220, 40)
		ob.add_item("Por defecto (cajas)", 0)
		var actual := str(obs.get(par[0], "")) if not (obs.get(par[0], "") is Array) else str(obs[par[0]][0])
		var sel := 0
		for i in mods.size():
			ob.add_item(str(mods[i].get("n", mods[i]["id"])), i + 1)
			if str(mods[i]["id"]) == actual:
				sel = i + 1
		ob.selected = sel
		ob.item_selected.connect(func(i):
			var d: Dictionary = Datos.nivel.get("obstaculos", {}) if Datos.nivel.get("obstaculos", {}) is Dictionary else {}
			if i == 0:
				d.erase(par[0])
			else:
				d[par[0]] = mods[i - 1]["id"]
			Datos.nivel["obstaculos"] = d
			Datos.guardar()
			cambiado.emit())
		f.add_child(ob)
	var dl := Label.new()
	dl.text = "Adorno de los lados (elige varios; vacío = árboles del tema)"
	dl.add_theme_font_size_override("font_size", 18)
	padre.add_child(dl)
	var lista := ItemList.new()
	lista.select_mode = ItemList.SELECT_MULTI
	lista.custom_minimum_size = Vector2(0, 170)
	var marcados: Array = (Datos.nivel.get("decorado", []) as Array).map(func(d): return str(d["e"]))
	for i in mods.size():
		lista.add_item(str(mods[i].get("n", mods[i]["id"])))
		if marcados.has(str(mods[i]["id"])):
			lista.select(i, false)
	var cambio := func(_i, _a = false):
		var d: Array = []
		for i in lista.get_selected_items():
			var previo := (Datos.nivel.get("decorado", []) as Array).filter(func(x): return str(x["e"]) == str(mods[i]["id"]))
			d.append(previo[0] if previo.size() > 0 else {"e": mods[i]["id"], "alto": 3.0})
		Datos.nivel["decorado"] = d
		Datos.guardar()
		cambiado.emit()
	lista.multi_selected.connect(cambio)
	padre.add_child(lista)


func _opcion(padre: Control, nombre: String, clave: String, ops: Array) -> void:
	var f := HBoxContainer.new()
	padre.add_child(f)
	var l := Label.new()
	l.text = nombre
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 18)
	f.add_child(l)
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(190, 40)
	var sel := 0
	var actual = Datos.nivel.get(clave, ops[0][0] if clave != "densidad" else 1.0)
	for i in ops.size():
		ob.add_item(str(ops[i][1]), i)
		if str(ops[i][0]) == str(actual):
			sel = i
	ob.selected = sel
	ob.item_selected.connect(func(i):
		Datos.nivel[clave] = ops[i][0]
		Datos.guardar()
		cambiado.emit())
	f.add_child(ob)


## Curvas, subidas y bajadas: una lista de tramos, cada uno entre dos puntos de la pista (en %).
func _tramos(v: VBoxContainer) -> void:
	_texto(v, "Curvas, subidas y bajadas", 20, Estilo.TINTA)
	_texto(v, "Cada tramo dobla o sube la pista entre dos puntos (en % del recorrido). Se ve al jugar.", 14, Estilo.SUAVE)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	v.add_child(caja)
	var pintar := func() -> void: pass
	var lista: Array = Datos.nivel.get("pista", []).duplicate(true) if Datos.nivel.get("pista", []) is Array else []
	var guardar := func() -> void:
		if lista.is_empty():
			Datos.nivel.erase("pista")
		else:
			Datos.nivel["pista"] = lista.duplicate(true)
		Datos.guardar()
		cambiado.emit()
	var rehacer: Array = [Callable()]
	pintar = func() -> void:
		for c in caja.get_children():
			c.queue_free()
		for i in lista.size():
			var tr: Dictionary = lista[i]
			var f := HFlowContainer.new()
			f.add_theme_constant_override("h_separation", 6)
			caja.add_child(f)
			var oc := OptionButton.new()
			var curvas := [["Recta", 0.0], ["Curva izq. suave", -0.5], ["Curva izq. fuerte", -1.0], ["Curva der. suave", 0.5], ["Curva der. fuerte", 1.0]]
			var sel := 0
			for k in curvas.size():
				oc.add_item(curvas[k][0], k)
				if is_equal_approx(float(curvas[k][1]), float(tr["curva"])):
					sel = k
			oc.selected = sel
			oc.item_selected.connect(func(k):
				lista[i]["curva"] = curvas[k][1]
				guardar.call())
			f.add_child(oc)
			var os := OptionButton.new()
			var subs := [["Plana", 0.0], ["Subida", 1.0], ["Subida suave", 0.5], ["Bajada", -1.0], ["Bajada suave", -0.5]]
			var sel2 := 0
			for k in subs.size():
				os.add_item(subs[k][0], k)
				if is_equal_approx(float(subs[k][1]), float(tr["subida"])):
					sel2 = k
			os.selected = sel2
			os.item_selected.connect(func(k):
				lista[i]["subida"] = subs[k][1]
				guardar.call())
			f.add_child(os)
			for j in 2:
				var sb := SpinBox.new()
				sb.min_value = 0
				sb.max_value = 100
				sb.step = 5
				sb.suffix = "%"
				sb.value = float(tr["d"][j])
				sb.value_changed.connect(func(x):
					lista[i]["d"][j] = x
					if float(lista[i]["d"][1]) <= float(lista[i]["d"][0]):
						lista[i]["d"][1] = minf(100.0, float(lista[i]["d"][0]) + 5.0)
					guardar.call())
				f.add_child(sb)
			var bd := Button.new()
			bd.text = "🗑"
			bd.pressed.connect(func():
				lista.remove_at(i)
				guardar.call()
				rehacer[0].call())
			f.add_child(bd)
	rehacer[0] = pintar
	pintar.call()
	var ba := Button.new()
	ba.text = "  ➕ Agregar tramo"
	ba.custom_minimum_size = Vector2(0, 44)
	ba.pressed.connect(func():
		var ult := 10.0
		if lista.size() > 0:
			ult = minf(float(lista[-1]["d"][1]), 85.0)
		lista.append({"d": [ult, ult + 15.0], "curva": 0.5, "subida": 0.0})
		guardar.call()
		pintar.call())
	v.add_child(ba)


func _aplicar() -> void:
	var g := func(k: String) -> String: return "#" + (_selectores[k] as ColorPickerButton).color.to_html(false)
	Datos.nivel["paleta"] = {
		"cielo": [g.call("cielo_a"), g.call("cielo_b")],
		"lejos": g.call("lejos"), "cerca": g.call("cerca"),
		"plat": [g.call("tierra"), g.call("pasto")],
	}
	Datos.guardar()
	cambiado.emit()


func _texto(padre: Control, t: String, tam: int, col: Color) -> void:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	padre.add_child(l)
