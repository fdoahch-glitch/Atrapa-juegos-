extends Control
## Escenario: la zona donde se arma el nivel. Se pueden soltar objetos,
## moverlos, estirar plataformas, borrar y desplazar la vista.

signal agregado(tipo: String)
signal seleccionado(item: Variant)
signal cambio

const Dibujo := preload("res://scripts/dibujo.gd")
const Capa := preload("res://scripts/capa.gd")
const Estilo := preload("res://scripts/estilo.gd")
const T := 48

var sel: Variant = null              # objeto seleccionado (Dictionary) o null
var stamp: Dictionary = {}           # objeto de la biblioteca "en la mano"
var herramienta := "mover"           # mover | borrar
var zoom := 1.0
var Z := 40.0                        # píxeles de pantalla por celda
var origen := Vector2.ZERO           # esquina del mundo en pantalla
var t := 0.0

var _mundo: Node2D
var _fantasma: Node2D
var _drag: Dictionary = {}
var _hover := Vector2i(-1, -1)
var _cambiado := false
var _visto := -1
var vert := false                    # pista de carreras: se ve vertical (avanza hacia arriba)


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_mundo = Capa.new()
	_mundo.al_dibujar = _dibujar_mundo
	add_child(_mundo)
	_fantasma = Capa.new()
	_fantasma.al_dibujar = _dibujar_fantasma
	_fantasma.modulate = Color(1, 1, 1, 0.55)
	add_child(_fantasma)


func _tema() -> Dictionary:
	var th: Dictionary = Datos.tema_de(Datos.nivel)
	if str(Datos.nivel.get("tipo", "")) == "arriba":
		th = th.duplicate()
		th["arriba"] = true
	return th


## Celdas que ocupa el lienzo en pantalla (ancho, alto).
func _dims() -> Vector2:
	var cols: int = Datos.nivel["cols"]
	return Vector2(Datos.FILAS, cols) if vert else Vector2(cols, Datos.FILAS)


## Copia del objeto con su posición girada para dibujarlo en la pista vertical (el dibujo sigue derecho).
func _m(it: Dictionary) -> Dictionary:
	if not vert:
		return it
	var c := it.duplicate()
	var cols: int = Datos.nivel["cols"]
	c["x"] = it["y"]
	c["y"] = cols - 1 - int(it["x"])
	return c


func _rect_pant(b: Rect2) -> Rect2:
	if not vert:
		return b
	var cols: int = Datos.nivel["cols"]
	return Rect2(b.position.y, cols - b.position.x - b.size.x, b.size.y, b.size.x)


func _process(delta: float) -> void:
	vert = Datos.es_corredor()
	t += delta
	_ajustar()
	queue_redraw()
	_mundo.queue_redraw()
	_fantasma.queue_redraw()


func _ajustar() -> void:
	var d := _dims()
	if vert:
		Z = clampf(minf(size.x / d.x, 64.0), 30.0, 64.0) * zoom
	else:
		Z = maxf(30.0, size.y / Datos.FILAS) * zoom
	var ancho := d.x * Z
	var alto := d.y * Z
	if vert and _visto != Datos.idx:
		_visto = Datos.idx
		origen.y = size.y - alto   # empieza mostrando la salida (abajo)
	origen.x = (size.x - ancho) / 2.0 if ancho <= size.x else clampf(origen.x, size.x - ancho, 0.0)
	origen.y = (size.y - alto) / 2.0 if alto <= size.y else clampf(origen.y, size.y - alto, 0.0)
	for n in [_mundo, _fantasma]:
		n.position = origen
		n.scale = Vector2(Z / T, Z / T)


## Posición en celdas del MUNDO (no de la pantalla) bajo un punto de la pantalla.
func _celda(p: Vector2) -> Vector2:
	var c := (p - origen) / Z
	if vert:
		var cols: int = Datos.nivel["cols"]
		return Vector2(cols - c.y, c.x)
	return c


# ------------------------------------------------------------------ dibujo
func _draw() -> void:
	Dibujo.fondo_de(self, Datos.nivel, _tema(), size, 0.0 if vert else -origen.x, t)
	# oscurece lo que queda fuera del nivel
	var mundo := Rect2(origen, _dims() * Z)
	var sombra := Color(0.09, 0.07, 0.25, 0.5)
	draw_rect(Rect2(0, 0, size.x, maxf(0.0, mundo.position.y)), sombra)
	draw_rect(Rect2(0, mundo.end.y, size.x, maxf(0.0, size.y - mundo.end.y)), sombra)
	draw_rect(Rect2(0, mundo.position.y, maxf(0.0, mundo.position.x), mundo.size.y), sombra)
	draw_rect(Rect2(mundo.end.x, mundo.position.y, maxf(0.0, size.x - mundo.end.x), mundo.size.y), sombra)
	_dibujar_marco_pantalla()


## Marco de la pantalla del celular: lo que se verá de una vez, según vertical u horizontal.
func _dibujar_marco_pantalla() -> void:
	if str(Datos.nivel.get("disp", "pc")) != "movil":
		return
	var vertical: bool = str(Datos.nivel.get("orient", "horizontal")) == "vertical"
	var ratio := 9.0 / 16.0 if vertical else 16.0 / 9.0
	var ancho_celdas := Datos.FILAS * ratio
	var x0 := 0.0
	for it in Datos.nivel["items"]:
		if it["t"] == "player":
			x0 = clampf(float(it["x"]) + 0.5 - ancho_celdas / 2.0, 0.0, maxf(0.0, float(Datos.nivel["cols"]) - ancho_celdas))
	var r := Rect2(origen + Vector2(x0 * Z, 0.0), Vector2(ancho_celdas * Z, Datos.FILAS * Z))
	draw_rect(r, Color(1, 0.85, 0.2, 0.9), false, 3.0)
	draw_string(ThemeDB.fallback_font, r.position + Vector2(8, 22), "Pantalla del celular (%s)" % ("vertical" if vertical else "horizontal"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 0.85, 0.2))


func _dibujar_mundo(ci: CanvasItem) -> void:
	var cols: int = Datos.nivel["cols"]
	var px := T / Z   # 1 píxel de pantalla en unidades del mundo
	var dm := _dims()
	for i in int(dm.x) + 1:
		ci.draw_line(Vector2(i * T, 0), Vector2(i * T, dm.y * T), Color(1, 1, 1, 0.25), px)
	for j in int(dm.y) + 1:
		ci.draw_line(Vector2(0, j * T), Vector2(dm.x * T, j * T), Color(1, 1, 1, 0.25), px)
	if Datos.es_corredor():
		_dibujar_pista(ci, cols)
	var lista: Array = []
	for it0 in Datos.nivel["items"]:
		lista.append(_m(it0))
	Dibujo.objetos(ci, lista, _tema(), t, str(Datos.nivel["hero"]))
	if sel != null and Datos.nivel["items"].has(sel):
		var b := _rect_pant(Datos.caja_de(sel))
		var r := Rect2(b.position * T, b.size * T).grow(px)
		var col := Estilo.MORADO
		ci.draw_dashed_line(r.position, Vector2(r.end.x, r.position.y), col, 3.0 * px, 8.0 * px)
		ci.draw_dashed_line(Vector2(r.end.x, r.position.y), r.end, col, 3.0 * px, 8.0 * px)
		ci.draw_dashed_line(r.end, Vector2(r.position.x, r.end.y), col, 3.0 * px, 8.0 * px)
		ci.draw_dashed_line(Vector2(r.position.x, r.end.y), r.position, col, 3.0 * px, 8.0 * px)
		if sel["t"] == "plat":
			ci.draw_circle(r.end, 11.0 * px, Color.WHITE)
			ci.draw_arc(r.end, 11.0 * px, 0.0, TAU, 20, col, 3.0 * px)
		if sel["t"] == "enemy" and not vert:
			var yy: float = (float(sel["y"]) + 1.0) * T + 6.0 * px
			ci.draw_line(Vector2((sel["x"] - sel["r"] + 0.5) * T, yy), Vector2((sel["x"] + sel["r"] + 0.5) * T, yy), Color.WHITE, 5.0 * px)


## Modo 3D: la pista vista desde arriba, con sus 3 carriles.
func _dibujar_pista(ci: CanvasItem, cols: int) -> void:
	var nombres := ["Izquierda", "Centro", "Derecha"]
	var fuente := ThemeDB.fallback_font
	if vert:
		for i in 3:
			var fila: int = Datos.fila_de_carril(i)
			var rv := Rect2((fila - 1) * T, 0, 3 * T, cols * T)
			ci.draw_rect(rv, Color(0.2, 0.22, 0.3, 0.62))
			ci.draw_rect(rv, Color(1, 1, 1, 0.55), false, 3.0 * T / Z)
			ci.draw_string(fuente, Vector2((fila - 1) * T + 6, 22), nombres[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.8))
		ci.draw_string(fuente, Vector2(6, cols * T - 8), "Salida", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.9))
		for k in range(2, cols, 6):
			ci.draw_colored_polygon(PackedVector2Array([Vector2(5.3 * T, (cols - k - 0.3) * T), Vector2(4.7 * T, (cols - k - 0.3) * T), Vector2(5.0 * T, (cols - k - 0.75) * T)]), Color(1, 1, 1, 0.28))
		return
	for i in 3:
		var fila: int = Datos.fila_de_carril(i)
		var r := Rect2(0, (fila - 1) * T, cols * T, 3 * T)
		ci.draw_rect(r, Color(0.2, 0.22, 0.3, 0.62))
		ci.draw_rect(r, Color(1, 1, 1, 0.55), false, 3.0 * T / Z)
		ci.draw_string(fuente, Vector2(6, (fila - 1) * T + 20), nombres[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.8))
	# flechas de avance
	var px := T / Z
	for k in range(2, cols, 6):
		ci.draw_colored_polygon(PackedVector2Array([Vector2((k + 0.3) * T, 5.3 * T), Vector2((k + 0.3) * T, 4.7 * T), Vector2((k + 0.75) * T, 5.0 * T)]), Color(1, 1, 1, 0.28))


func _dibujar_fantasma(ci: CanvasItem) -> void:
	if stamp.is_empty() or _hover.x < 0 or not _drag.is_empty():
		return
	var d := stamp
	var it: Dictionary = {"t": d["t"], "x": _hover.x, "y": _hover.y}
	if Datos.es_corredor() and Datos.TIPOS_PISTA.has(str(d["t"])):
		it["y"] = Datos.fila_de_carril(Datos.a_carril(_hover.y))
	it = _m(it)
	var extra := {}
	match d["t"]:
		"plat":
			it["w"] = 3
			it["h"] = 1
		"enemy":
			it["e"] = d["e"]
			it["fly"] = d.get("fly", false)
			extra = {"dir": 1}
		"deco":
			it["e"] = d["e"]
			it["s"] = d.get("s", 56)
		"hero", "player":
			it["t"] = "player"
			extra = {"e": d.get("e", Datos.nivel["hero"]) if d["t"] == "hero" else Datos.nivel["hero"], "cara": 1}
	Dibujo.objeto(ci, it, _tema(), t, extra)


# ------------------------------------------------------------------ entrada
func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_LEFT:
				if mb.pressed:
					_bajar(mb.position)
				else:
					_subir()
			MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT:
				if mb.pressed:
					_drag = {"modo": "panear", "inicio": mb.position, "origen": origen}
				else:
					_drag = {}
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				var s := 1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
				if mb.ctrl_pressed:
					zoom = clampf(zoom + s * 0.1, 0.6, 1.8)
				elif vert:
					origen.y += s * 90.0
				else:
					origen.x += s * 90.0
	elif ev is InputEventMouseMotion:
		_mover((ev as InputEventMouseMotion).position)


func _bajar(p: Vector2) -> void:
	var c := _celda(p)
	var cx := int(floor(c.x))
	var cy := int(floor(c.y))
	_drag = {}
	_cambiado = false
	if not stamp.is_empty():
		var it := Datos.colocar(stamp, cx, cy)
		sel = it
		_cambiado = true
		if it["t"] == "plat":
			_drag = {"modo": "dibujar", "it": it, "ox": cx, "oy": cy, "movido": false}
		elif it["t"] in ["coin", "star", "gem"]:
			_drag = {"modo": "pintar", "def": stamp, "ultimo": Vector2i(cx, cy)}
		else:
			_drag = {"modo": "nada"}
		agregado.emit(str(it["t"]))
		seleccionado.emit(sel)
		return
	if herramienta == "borrar":
		var h = Datos.objeto_en(c)
		if h != null and h["t"] != "player":
			Datos.quitar(h)
			_cambiado = true
		sel = null
		_drag = {"modo": "borrar"}
		seleccionado.emit(null)
		return
	if sel != null and sel["t"] == "plat" and c.distance_to(Datos.caja_de(sel).end) < 0.55:
		_drag = {"modo": "estirar", "it": sel}
		return
	var h2 = Datos.objeto_en(c)
	if h2 != null:
		sel = h2
		_drag = {"modo": "mover", "it": h2, "dx": c.x - float(h2["x"]), "dy": c.y - float(h2["y"])}
	else:
		sel = null
		_drag = {"modo": "panear", "inicio": p, "origen": origen}
	seleccionado.emit(sel)


func _mover(p: Vector2) -> void:
	var c := _celda(p)
	var cx := int(floor(c.x))
	var cy := int(floor(c.y))
	_hover = Vector2i(clampi(cx, 0, Datos.nivel["cols"] - 1), clampi(cy, 0, Datos.FILAS - 1))
	if _drag.is_empty():
		return
	var cols: int = Datos.nivel["cols"]
	match _drag["modo"]:
		"dibujar":
			var it: Dictionary = _drag["it"]
			if cx != _drag["ox"] or cy != _drag["oy"]:
				_drag["movido"] = true
			if _drag["movido"]:
				it["w"] = clampi(cx - _drag["ox"] + 1, 1, cols - it["x"])
				it["h"] = clampi(cy - _drag["oy"] + 1, 1, Datos.FILAS - it["y"])
		"pintar":
			var cel := Vector2i(cx, cy)
			var ant: Vector2i = _drag["ultimo"]
			if cel != ant:
				var def: Dictionary = _drag["def"]
				var pasos := maxi(absi(cel.x - ant.x), absi(cel.y - ant.y))
				for i in range(1, pasos + 1):
					var q := Vector2i(roundi(lerpf(ant.x, cel.x, float(i) / pasos)), roundi(lerpf(ant.y, cel.y, float(i) / pasos)))
					if q.x < 0 or q.x >= cols or q.y < 0 or q.y >= Datos.FILAS:
						continue
					var hay := false
					for o in Datos.nivel["items"]:
						if o["t"] == def["t"] and o["x"] == q.x and o["y"] == q.y:
							hay = true
					if not hay:
						Datos.colocar(def, q.x, q.y)
						_cambiado = true
				_drag["ultimo"] = cel
		"mover":
			var it2: Dictionary = _drag["it"]
			var b := Datos.caja_de(it2)
			var ancho := int(it2["w"]) if it2["t"] == "plat" else 1
			var alto := int(it2["h"]) if it2["t"] == "plat" else 1
			var nx := clampi(roundi(c.x - _drag["dx"]), 0, cols - ancho)
			var ny := clampi(roundi(c.y - _drag["dy"]), 0, Datos.FILAS - alto)
			if Datos.es_corredor() and Datos.TIPOS_PISTA.has(str(it2["t"])):
				ny = Datos.fila_de_carril(Datos.a_carril(ny))
			if nx != it2["x"] or ny != it2["y"]:
				it2["x"] = nx
				it2["y"] = ny
				_cambiado = true
		"estirar":
			var it3: Dictionary = _drag["it"]
			it3["w"] = clampi(roundi(c.x - it3["x"]), 1, cols - it3["x"])
			it3["h"] = clampi(roundi(c.y - it3["y"]), 1, Datos.FILAS - it3["y"])
			_cambiado = true
		"borrar":
			var h = Datos.objeto_en(c)
			if h != null and h["t"] != "player":
				Datos.quitar(h)
				_cambiado = true
		"panear":
			origen = _drag["origen"] + (p - _drag["inicio"])


func _subir() -> void:
	if not _drag.is_empty() and (_cambiado or _drag["modo"] == "dibujar"):
		Datos.confirmar()
		cambio.emit()
	_drag = {}
	_cambiado = false


# ------------------------------------------------------------------ arrastrar y soltar desde la biblioteca
func _can_drop_data(_p: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("def")


func _drop_data(p: Vector2, data: Variant) -> void:
	soltar(data["def"], p)


func soltar(def: Dictionary, p: Vector2) -> void:
	var c := _celda(p)
	var it := Datos.colocar(def, int(floor(c.x)), int(floor(c.y)))
	sel = it
	Datos.confirmar()
	cambio.emit()
	agregado.emit(str(it["t"]))
	seleccionado.emit(sel)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hover = Vector2i(-1, -1)
