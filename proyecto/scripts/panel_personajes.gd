extends ColorRect
## Etapa «Selección de personajes»: eliges cuáles se pueden usar y su poder.

signal cambio

const Estilo := preload("res://scripts/estilo.gd")
const Tienda := preload("res://scripts/tienda.gd")
const Importar := preload("res://scripts/importar.gd")
const Assets3D := preload("res://scripts/assets3d.gd")

var _rejilla: HFlowContainer
var _info: Label


func _ready() -> void:
	color = Color(0.12, 0.09, 0.32, 1.0)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.offset_top = 118
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	sc.add_child(v)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.add_theme_font_size_override("font_size", 20)
	_info.add_theme_color_override("font_color", Color.WHITE)
	_info.custom_minimum_size = Vector2(300, 60)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_info)
	_rejilla = HFlowContainer.new()
	_rejilla.alignment = FlowContainer.ALIGNMENT_CENTER
	_rejilla.add_theme_constant_override("h_separation", 12)
	_rejilla.add_theme_constant_override("v_separation", 12)
	_rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_rejilla)
	refrescar()


func _catalogo() -> Array:
	var r: Array = []
	for h in Assets3D.PERSONAJES:
		r.append({"id": "a:" + h[0], "n": h[1]})
	for h in Datos.heroes:
		r.append({"id": h[1], "n": h[0]})
	for a in Importar.listar():
		if str(a.get("cat", "")) != "" and not str(a.get("cat", "")) in ["Personas", "Animales", "Dinosaurios"]:
			continue
		if str(a["id"]).begins_with("u:") or str(a["id"]).begins_with("g:"):
			r.append({"id": a["id"], "n": a["n"]})
	return r


func _buscar(id: String) -> int:
	var lista: Array = Datos.reglas["jugables"]
	for i in lista.size():
		if str(lista[i]["id"]) == id:
			return i
	return -1


func refrescar() -> void:
	for c in _rejilla.get_children():
		c.queue_free()
	var n: int = (Datos.reglas["jugables"] as Array).size()
	_info.text = "Elige los personajes que el jugador podrá usar. " + ("Ahora hay %d elegidos: el juego mostrará la pantalla «Elige tu personaje»." % n if n > 1 else "Con 2 o más aparece la pantalla de selección en el juego.")
	for it in _catalogo():
		_rejilla.add_child(_tarjeta(it))


func _tarjeta(it: Dictionary) -> Control:
	var i := _buscar(str(it["id"]))
	var elegido := i >= 0
	var b := PanelContainer.new()
	b.custom_minimum_size = Vector2(150, 190)
	b.add_theme_stylebox_override("panel", Estilo.caja(Color(1, 1, 1, 0.96 if elegido else 0.78), 18, 5 if elegido else 0, Estilo.VERDE, 8))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	b.add_child(v)
	var tr := TextureRect.new()
	tr.texture = Datos.textura(str(it["id"]))
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(90, 90)
	v.add_child(tr)
	var l := Label.new()
	l.text = str(it["n"])
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Estilo.TINTA)
	v.add_child(l)
	var bt := Button.new()
	bt.text = "Quitar" if elegido else "Elegir"
	bt.focus_mode = Control.FOCUS_NONE
	Estilo.pintar(bt, Estilo.ROJO if elegido else Estilo.MORADO)
	bt.pressed.connect(func():
		var lista: Array = Datos.reglas["jugables"]
		var k := _buscar(str(it["id"]))
		if k >= 0:
			lista.remove_at(k)
		elif lista.size() < 12:
			lista.append({"id": str(it["id"]), "n": str(it["n"]), "poder": "", "desc": ""})
		Datos.reglas["jugables"] = lista
		Datos.guardar()
		cambio.emit()
		refrescar())
	v.add_child(bt)
	if elegido:
		var p := Button.new()
		var poder := str(Datos.reglas["jugables"][i].get("poder", ""))
		p.text = Tienda.NOMBRE_PODER.get(poder, "Sin poder")
		p.focus_mode = Control.FOCUS_NONE
		p.tooltip_text = "Toca para cambiar el poder"
		p.pressed.connect(func():
			var ops: Array = [""] + Tienda.PODERES
			var q := ops.find(str(Datos.reglas["jugables"][i].get("poder", "")))
			var nuevo: String = ops[(q + 1) % ops.size()]
			Datos.reglas["jugables"][i]["poder"] = nuevo
			Datos.reglas["jugables"][i]["desc"] = Tienda.NOMBRE_PODER.get(nuevo, "")
			Datos.guardar()
			refrescar())
		v.add_child(p)
	return b
