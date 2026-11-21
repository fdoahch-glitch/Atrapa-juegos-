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
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	_texto(v, "Colores de este mundo", 28, Estilo.TINTA)
	_texto(v, "Toca un color para cambiarlo. Se ve al instante en el mundo.", 15, Estilo.SUAVE)
	var t: Dictionary = Datos.tema_de(Datos.nivel)
	_fila(v, "cielo_a", "Cielo (arriba)", t["cielo"][0])
	_fila(v, "cielo_b", "Cielo (horizonte)", t["cielo"][1])
	_fila(v, "lejos", "Colinas lejanas", t["lejos"])
	_fila(v, "cerca", "Colinas cercanas", t["cerca"])
	_fila(v, "tierra", "Tierra (plataformas y pista)", t["plat"][0])
	_fila(v, "pasto", "Pasto o superficie", t["plat"][1])
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
