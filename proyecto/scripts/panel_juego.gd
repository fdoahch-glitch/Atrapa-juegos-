extends ColorRect
## Paneles «Mecánicas» (lo que sabe hacer el personaje) y «Física» (cómo se siente el mundo).
## Se elige con `modo` antes de agregarlo: "mec" o "fis". Todo se guarda en las reglas del juego.

signal cerrar

const Estilo := preload("res://scripts/estilo.gd")

var modo := "mec"
var _sliders := {}
var _etq := {}


func _ready() -> void:
	color = Color(0.08, 0.06, 0.23, 0.62)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Datos.reglas = Datos.reglas_completas(Datos.reglas)
	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(640.0, maxf(320.0, size.x - 24.0)), 0)
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 26, 0, Color.TRANSPARENT, 22))
	centro.add_child(panel)
	var ext := VBoxContainer.new()
	ext.add_theme_constant_override("separation", 8)
	panel.add_child(ext)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, minf(600.0, maxf(280.0, size.y - 130.0)))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ext.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	sc.add_child(v)
	if modo == "mec":
		_mecanicas(v)
	else:
		_fisica(v)
	var b := Button.new()
	b.text = "Listo"
	b.icon = Datos.textura("✅")
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 28)
	b.custom_minimum_size = Vector2(0, 52)
	Estilo.pintar(b, Estilo.VERDE)
	b.pressed.connect(func(): cerrar.emit())
	ext.add_child(b)


func _t(v: Control, s: String, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	return l


func _aplica_a() -> String:
	if Datos.es_3d() or str(Datos.nivel.get("tipo", "")) == "arriba" or str(Datos.nivel.get("estilo", "")) in ["mini", "pelea"]:
		return "Esto se usa en los juegos de plataformas (2D, 2.5D y el trío). En este tipo de juego todavía no cambia nada."
	return ""


# ------------------------------------------------------------------ mecánicas
func _mecanicas(v: VBoxContainer) -> void:
	_t(v, "Mecánicas", 28, Estilo.TINTA)
	_t(v, "Lo que sabe hacer tu personaje. Enciende lo que quieras y pruébalo con ¡Jugar!", 15, Estilo.SUAVE)
	var aviso := _aplica_a()
	if aviso != "":
		_t(v, aviso, 15, Estilo.ROJO)
	var mec: Dictionary = Datos.reglas["mec"]
	for x in Datos.MEC_LISTA:
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 10)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_t(col, str(x[1]), 20, Estilo.TINTA)
		_t(col, str(x[2]), 14, Estilo.SUAVE)
		f.add_child(col)
		var bt := Button.new()
		bt.toggle_mode = true
		bt.custom_minimum_size = Vector2(92, 48)
		bt.focus_mode = Control.FOCUS_NONE
		var clave: String = x[0]
		var pintar := func():
			bt.text = "Sí" if bool(mec[clave]) else "No"
			Estilo.pintar(bt, Estilo.VERDE if bool(mec[clave]) else Color("c7c2f0"), Color.WHITE if bool(mec[clave]) else Estilo.TINTA)
		pintar.call()
		bt.pressed.connect(func():
			mec[clave] = not bool(mec[clave])
			Datos.reglas["mec"] = mec
			Datos.guardar()
			pintar.call())
		f.add_child(bt)
		v.add_child(f)
	_t(v, "En el trío de héroes cada personaje además trae sus propias habilidades (1 caballero, 2 mago, 3 ladrón).", 14, Estilo.SUAVE)


# ------------------------------------------------------------------ física
const NOMBRES := {
	"grav": ["Gravedad", "Ligera", "Pesada"], "salto": ["Fuerza de salto", "Bajito", "Altísimo"],
	"vel": ["Velocidad al caminar", "Lento", "Veloz"], "friccion": ["Agarre del suelo", "Resbala", "Frena al instante"],
	"caida": ["Velocidad máxima de caída", "Cae despacio", "Cae rápido"], "rebote": ["Rebote al caer", "Sin rebote", "Rebota mucho"]}


func _fisica(v: VBoxContainer) -> void:
	_t(v, "Física", 28, Estilo.TINTA)
	_t(v, "Cómo se siente el mundo. Elige un estilo o mueve las barras.", 15, Estilo.SUAVE)
	var aviso := _aplica_a()
	if aviso != "":
		_t(v, aviso, 15, Estilo.ROJO)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 6)
	fl.add_theme_constant_override("v_separation", 6)
	v.add_child(fl)
	for p in Datos.FIS_PRESETS:
		var b := Button.new()
		b.text = str(p[0])
		b.custom_minimum_size = Vector2(0, 44)
		b.focus_mode = Control.FOCUS_NONE
		var cambios: Dictionary = p[1]
		b.pressed.connect(func():
			var f := Datos.FIS_BASE.duplicate()
			for k in cambios.keys():
				f[k] = cambios[k]
			Datos.reglas["fis"] = f
			Datos.guardar()
			for k in _sliders.keys():
				(_sliders[k] as HSlider).set_value_no_signal(float(f[k]))
				_poner_etq(k, float(f[k])))
		fl.add_child(b)
	var fis: Dictionary = Datos.reglas["fis"]
	for k in ["grav", "salto", "vel", "friccion", "caida", "rebote"]:
		var nom: Array = NOMBRES[k]
		var r: Array = Datos.FIS_RANGOS[k]
		var cab := HBoxContainer.new()
		var l := Label.new()
		l.text = str(nom[0])
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_theme_color_override("font_color", Estilo.TINTA)
		cab.add_child(l)
		var e := Label.new()
		e.add_theme_color_override("font_color", Estilo.MORADO)
		cab.add_child(e)
		_etq[k] = e
		v.add_child(cab)
		var sl := HSlider.new()
		sl.min_value = float(r[0])
		sl.max_value = float(r[1])
		sl.step = 0.05
		sl.value = float(fis[k])
		sl.custom_minimum_size = Vector2(0, 30)
		sl.focus_mode = Control.FOCUS_NONE
		sl.value_changed.connect(func(x):
			var f2: Dictionary = Datos.reglas["fis"]
			f2[k] = x
			Datos.reglas["fis"] = f2
			Datos.guardar()
			_poner_etq(k, x))
		v.add_child(sl)
		_sliders[k] = sl
		var ex := HBoxContainer.new()
		var a := Label.new()
		a.text = str(nom[1])
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		a.add_theme_color_override("font_color", Estilo.SUAVE)
		a.add_theme_font_size_override("font_size", 13)
		ex.add_child(a)
		var z := Label.new()
		z.text = str(nom[2])
		z.add_theme_color_override("font_color", Estilo.SUAVE)
		z.add_theme_font_size_override("font_size", 13)
		ex.add_child(z)
		v.add_child(ex)
		_poner_etq(k, float(fis[k]))


func _poner_etq(k: String, x: float) -> void:
	(_etq[k] as Label).text = "%d%%" % roundi(x * 100.0) if k != "rebote" else ("No" if x < 0.05 else "%d%%" % roundi(x * 100.0))
