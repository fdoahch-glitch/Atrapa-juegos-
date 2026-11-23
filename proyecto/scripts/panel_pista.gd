extends "res://scripts/panel_colores.gd"
## Creador de pista: dibuja la pista vista desde arriba y deja agregar tramos de curva, subida y bajada.
## Los colores y el ambiente siguen en el panel de colores.

var _vista: Control


func _ready() -> void:
	color = Color(0.08, 0.06, 0.23, 0.6)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(560.0, maxf(320.0, size.x - 30.0)), 0)
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
	_texto(v, "Creador de pista", 28, Estilo.TINTA)
	_texto(v, "Así se ve tu pista desde arriba. Agrega tramos con curvas, subidas y bajadas.", 15, Estilo.SUAVE)
	_vista = Control.new()
	_vista.custom_minimum_size = Vector2(0, 260)
	_vista.draw.connect(_pintar)
	v.add_child(_vista)
	cambiado.connect(func(): _vista.queue_redraw())
	_tramos(v)
	_texto(v, "Largo de la pista: usa «Nivel corto / medio / largo» en el mundo. Si quieres que no termine, activa «Sin fin» en Reglas.", 14, Estilo.SUAVE)
	var c := Button.new()
	c.text = "Listo"
	c.custom_minimum_size = Vector2(0, 48)
	Estilo.pintar(c, Estilo.VERDE)
	c.pressed.connect(func(): cerrar.emit())
	v.add_child(c)


func _pintar() -> void:
	var r := Rect2(Vector2.ZERO, _vista.size)
	_vista.draw_style_box(Estilo.caja(Color("2b2f45"), 18), r)
	var tramos: Array = Datos.nivel.get("pista", []) if Datos.nivel.get("pista", []) is Array else []
	var pts: Array = []
	var cols: Array = []
	var p := Vector2.ZERO
	var rumbo := -PI / 2.0
	var N := 120
	for i in N + 1:
		var s := float(i) / N * 100.0
		var curva := 0.0
		var sub := 0.0
		for tr in tramos:
			if s >= float(tr["d"][0]) and s < float(tr["d"][1]):
				curva = float(tr["curva"])
				sub = float(tr["subida"])
		rumbo += curva * 0.045
		p += Vector2(cos(rumbo), sin(rumbo)) * 1.0
		pts.append(p)
		cols.append(Color("43d17a") if sub > 0.0 else (Color("ff6b6b") if sub < 0.0 else Color("f5f5ff")))
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	for q in pts:
		mn = mn.min(q)
		mx = mx.max(q)
	var tam := (mx - mn).max(Vector2(1, 1))
	var esc := minf((r.size.x - 50.0) / tam.x, (r.size.y - 50.0) / tam.y)
	var off := (r.size - tam * esc) / 2.0 - mn * esc
	for i in N:
		_vista.draw_line(pts[i] * esc + off, pts[i + 1] * esc + off, cols[i], 12.0)
	_vista.draw_circle(pts[0] * esc + off, 9.0, Color("ffd23f"))
	_vista.draw_circle(pts[N] * esc + off, 9.0, Color("ffffff"))
	var f := ThemeDB.fallback_font
	_vista.draw_string(f, pts[0] * esc + off + Vector2(12, 4), "Salida", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	_vista.draw_string(f, pts[N] * esc + off + Vector2(12, 4), "Meta", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	_vista.draw_string(f, Vector2(10, r.size.y - 10), "Verde = sube · Rojo = baja · Blanco = plana", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.8))
