extends ColorRect
## Panel «Contenido» de los minijuegos: aquí se escribe y amplía el juego (cartas, notas, oleadas, preguntas, guion…).
## Lo que se cambia queda guardado en el mundo y se ve al pulsar ¡Jugar!.

signal probar
signal cambio

const Estilo := preload("res://scripts/estilo.gd")
const Minis := preload("res://scripts/minis.gd")


func _ready() -> void:
	color = Color(0.96, 0.95, 1.0)
	refrescar()


func refrescar() -> void:
	for c in get_children():
		c.queue_free()
	var id := str(Datos.nivel.get("mini", ""))
	if not Minis.existe(id):
		return
	var m: Dictionary = Minis.MINIS[id]
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 22)
	sc.add_child(margen)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margen.add_child(v)
	_t(v, "%s %s" % [m["emoji"], m["n"]], 34, Estilo.TINTA)
	_t(v, str(m["info"]), 18, Estilo.SUAVE)
	var cfg: Dictionary = Datos.nivel.get("mini_cfg", {})
	for campo in m["campos"]:
		var k: String = campo["k"]
		_t(v, str(campo["n"]), 18, Estilo.TINTA)
		match campo["t"]:
			"lista":
				var te := TextEdit.new()
				te.custom_minimum_size = Vector2(0, 190)
				te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
				te.text = str(cfg.get(k, ""))
				te.text_changed.connect(func():
					Datos.nivel["mini_cfg"][k] = te.text)
				te.focus_exited.connect(Datos.confirmar)
				v.add_child(te)
			"int":
				var sb := SpinBox.new()
				sb.min_value = 0
				sb.max_value = 99999
				sb.value = float(cfg.get(k, 0))
				sb.value_changed.connect(func(x):
					Datos.nivel["mini_cfg"][k] = int(x)
					Datos.confirmar())
				v.add_child(sb)
			_:
				var le := LineEdit.new()
				le.custom_minimum_size = Vector2(0, 44)
				le.text = str(cfg.get(k, ""))
				le.text_changed.connect(func(tx: String):
					Datos.nivel["mini_cfg"][k] = tx if not (cfg.get(k, "") is float) else float(tx))
				le.focus_exited.connect(Datos.confirmar)
				le.text_submitted.connect(func(_x): Datos.confirmar(); le.release_focus())
				v.add_child(le)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	v.add_child(fila)
	var bp := Button.new()
	bp.text = "  ▶ Probar mi juego"
	bp.custom_minimum_size = Vector2(240, 54)
	Estilo.pintar(bp, Estilo.VERDE, Color.WHITE)
	bp.pressed.connect(func(): probar.emit())
	fila.add_child(bp)
	var br := Button.new()
	br.text = "  Volver al ejemplo"
	br.custom_minimum_size = Vector2(220, 54)
	br.pressed.connect(func():
		Datos.nivel["mini_cfg"] = Minis.cfg_base(id)
		Datos.confirmar()
		refrescar())
	fila.add_child(br)


func _t(v: Control, s: String, tam: int, col: Color) -> void:
	var l := Label.new()
	l.text = s
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	v.add_child(l)
