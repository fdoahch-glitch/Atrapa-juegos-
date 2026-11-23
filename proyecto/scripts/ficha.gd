extends Button
## Una "ficha" de la biblioteca: muestra un dibujo y un nombre.
## Con el mouse se puede arrastrar al escenario; con el dedo se toca.

const Dibujo := preload("res://scripts/dibujo.gd")
const Capa := preload("res://scripts/capa.gd")
const Estilo := preload("res://scripts/estilo.gd")

var def: Dictionary = {}
var arrastrable := true
var marcada := false : set = _poner_marcada


## Control que dibuja la vista previa de la ficha.
class Icono extends Control:
	var def: Dictionary = {}
	var _capa: Node2D

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true
		if def["t"] != "tema" and def["t"] != "fondo_img":
			_capa = preload("res://scripts/capa.gd").new()
			_capa.al_dibujar = _pintar
			add_child(_capa)
			_aplicar()

	func _draw() -> void:
		if def["t"] == "tema":
			preload("res://scripts/dibujo.gd").fondo(self, Datos.temas[def["id"]], size, 0.0, 0.0)
		elif def["t"] == "fondo_img":
			var tex: Texture2D = Datos.textura(str(def["e"])) if str(def["e"]) != "" else null
			if tex:
				var k := maxf(size.x / tex.get_width(), size.y / tex.get_height())
				var w := tex.get_width() * k
				var h := tex.get_height() * k
				draw_texture_rect(tex, Rect2((size.x - w) / 2.0, (size.y - h) / 2.0, w, h), false)
			else:
				draw_rect(Rect2(Vector2.ZERO, size), Color("e3dfff"))
				draw_line(Vector2(8, size.y - 8), Vector2(size.x - 8, 8), Color("6b6699"), 3.0)

	func _aplicar() -> void:
		var k := maxf(0.2, minf(size.x, size.y) / 62.0)
		_capa.scale = Vector2(k, k)
		_capa.position = size / 2.0 - Vector2(24, 24) * k

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED and _capa:
			_aplicar()

	func _pintar(ci: CanvasItem) -> void:
		var Dib := preload("res://scripts/dibujo.gd")
		var th: Dictionary = Datos.temas["dia"]
		var d := def
		if d["t"] == "prefab":
			Dib.emoji(ci, "🧩", Vector2(24, 24), 44.0)
			return
		var it: Dictionary = {"t": d["t"], "x": 0, "y": 0}
		var extra := {}
		match d["t"]:
			"plat":
				it["w"] = 1
				it["h"] = 1
			"enemy":
				it["e"] = d["e"]
				it["fly"] = false
				extra = {"dir": -1}
			"deco":
				it["e"] = d["e"]
				it["s"] = minf(float(d.get("s", 56)), 46.0)
				if d["e"] == "☁️":
					it["y"] = 0
			"hero":
				it["t"] = "player"
				extra = {"e": d["e"], "cara": 1}
			"player":
				Dib.emoji(ci, "📍", Vector2(24, 24), 44.0)
				return
			"importar":
				Dib.emoji(ci, "📁", Vector2(24, 24), 44.0)
				return
			"audio":
				Dib.emoji(ci, "🔊", Vector2(24, 24), 44.0)
				return
		Dib.objeto(ci, it, th, 0.0, extra)


func _init() -> void:
	toggle_mode = false
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(98, 104)
	clip_contents = true


func configurar(d: Dictionary, es_arrastrable: bool) -> void:
	def = d
	arrastrable = es_arrastrable and not (d["t"] in ["tema", "importar", "fondo_img", "audio"])
	var ic := Icono.new()
	ic.def = d
	add_child(ic)
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ic.offset_left = 8.0
	ic.offset_right = -8.0
	ic.offset_top = 6.0
	ic.offset_bottom = -26.0
	var l := Label.new()
	l.text = str(d["n"])
	l.add_theme_font_size_override("font_size", 15)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	l.offset_top = -26.0
	l.offset_bottom = -4.0
	_poner_marcada(marcada)


func _poner_marcada(v: bool) -> void:
	marcada = v
	if v:
		add_theme_stylebox_override("normal", Estilo.caja(Color("efeaff"), 16, 3, Estilo.MORADO))
	else:
		remove_theme_stylebox_override("normal")


func _get_drag_data(_en: Vector2) -> Variant:
	if not arrastrable:
		return null
	var prev := Control.new()
	var cap := Capa.new()
	var ic := Icono.new()
	ic.def = def
	ic.size = Vector2(64, 64)
	ic.position = Vector2(-32, -32)
	ic.modulate = Color(1, 1, 1, 0.9)
	prev.add_child(ic)
	set_drag_preview(prev)
	cap.free()
	return {"def": def}
