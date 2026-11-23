extends "res://scripts/juego_mini.gd"
## Defensa de torres: coloca torres en el mapa y detén las oleadas.

const COLS := 9
const FILAS_M := 5
const CAMINO := 2

var torres: Array = []
var malos: Array = []
var monedas := 0
var oleada := -1
var por_salir := 0
var _sig := 0.0
var _tregua := 2.0
var _oleadas: Array = []
var _disparos: Array = []


func mini_usa_vidas() -> bool:
	return true


func _empezar() -> void:
	torres = []
	malos = []
	_disparos = []
	monedas = int(cfg.get("monedas", 60))
	oleada = -1
	por_salir = 0
	_tregua = 2.0
	_oleadas = []
	for tok in str(cfg.get("oleadas", "5 8 12")).split(" ", false):
		if int(tok) > 0:
			_oleadas.append(int(tok))
	if _oleadas.is_empty():
		_oleadas = [5]


func _lado() -> float:
	return minf((size.x - 30.0) / COLS, (size.y - 190.0) / FILAS_M)


func _origen() -> Vector2:
	var l := _lado()
	return Vector2((size.x - l * COLS) / 2.0, 130.0 + ((size.y - 150.0) - l * FILAS_M) / 2.0)


func _paso(dt: float) -> void:
	# oleadas
	if por_salir == 0 and malos.is_empty():
		_tregua -= dt
		if _tregua <= 0.0:
			oleada += 1
			if oleada >= _oleadas.size():
				_ganar("Detuviste todas las oleadas")
				return
			por_salir = _oleadas[oleada]
			_sig = 0.0
	elif por_salir > 0:
		_sig -= dt
		if _sig <= 0.0:
			malos.append({"x": -0.5, "hp": maxi(1, int(cfg.get("vida", 3)))})
			por_salir -= 1
			_sig = 1.1
			if por_salir == 0:
				_tregua = 3.0
	for m in malos.duplicate():
		m["x"] += 0.8 * dt
		if m["x"] >= COLS - 0.3:
			malos.erase(m)
			vidas -= 1
			_sonido.tocar(150.0, 0.2, "sierra")
			if vidas <= 0:
				_perder("Los enemigos llegaron a tu casa")
				return
	_disparos = _disparos.filter(func(d): return t - d["t"] < 0.12)
	for tw in torres:
		tw["cd"] -= dt
		if tw["cd"] > 0.0:
			continue
		var objetivo: Variant = null
		var mejor := 2.6
		for m in malos:
			var d := Vector2(m["x"], CAMINO).distance_to(Vector2(tw["c"], tw["r"]))
			if d < mejor:
				mejor = d
				objetivo = m
		if objetivo != null:
			tw["cd"] = 0.8
			objetivo["hp"] -= 1
			_disparos.append({"a": Vector2(tw["c"], tw["r"]), "b": Vector2(objetivo["x"], CAMINO), "t": t})
			_sonido.tocar(700.0, 0.05)
			if objetivo["hp"] <= 0:
				malos.erase(objetivo)
				monedas += 5
				puntos += 5


func _dibujar(ci: CanvasItem) -> void:
	var l := _lado()
	var o := _origen()
	_txt(ci, "Monedas: %d" % monedas, Vector2(20, 36), 26)
	_txt(ci, "Oleada %d de %d" % [mini_oleada(), _oleadas.size()], Vector2(20, 68), 20)
	_txt(ci, "Torre = %d monedas" % int(cfg.get("costo", 25)), Vector2(20, 96), 18, Color(1, 1, 1, 0.85))
	for r in FILAS_M:
		for c in COLS:
			var rc := Rect2(o.x + c * l + 2, o.y + r * l + 2, l - 4, l - 4)
			ci.draw_style_box(Estilo.caja(Color("b08968") if r == CAMINO else Color(0.2, 0.55, 0.25, 0.85), 10), rc)
			if r != CAMINO:
				_zonas.append([rc, c + r * COLS])
	Dibujo.emoji(ci, "🏠", o + Vector2(COLS * l - l * 0.4, CAMINO * l + l / 2.0), l * 0.8)
	for tw in torres:
		Dibujo.emoji(ci, str(cfg.get("torre", "🏹")), o + Vector2(tw["c"] * l + l / 2.0, tw["r"] * l + l / 2.0), l * 0.75)
	for m in malos:
		Dibujo.emoji(ci, str(cfg.get("enemigo", "👾")), o + Vector2(m["x"] * l + l / 2.0, CAMINO * l + l / 2.0), l * 0.7)
	for d in _disparos:
		ci.draw_line(o + (d["a"] as Vector2) * l + Vector2(l, l) / 2.0, o + (d["b"] as Vector2) * l + Vector2(l, l) / 2.0, Color("fde047"), 4.0)


func mini_oleada() -> int:
	return clampi(oleada + 1, 0, _oleadas.size())


func _al_pulsar(id: Variant) -> void:
	var c := int(id) % COLS
	var r := int(id) / COLS
	for tw in torres:
		if tw["c"] == c and tw["r"] == r:
			return
	var costo := int(cfg.get("costo", 25))
	if monedas < costo:
		_decir("Te faltan monedas")
		return
	monedas -= costo
	torres.append({"c": c, "r": r, "cd": 0.0})
	_sonido.tocar(520.0, 0.08)
