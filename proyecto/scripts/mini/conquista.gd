extends "res://scripts/juego_mini.gd"
## Estrategia: conquista de islas. Envía la mitad de tus tropas de una isla a otra.

const POS := [Vector2(0.1, 0.5), Vector2(0.3, 0.22), Vector2(0.3, 0.78), Vector2(0.5, 0.5), Vector2(0.7, 0.22), Vector2(0.7, 0.78), Vector2(0.9, 0.5)]

var islas: Array = []    # {p (0-1), due (0 neutral, 1 tú, 2 rival), n}
var grupos: Array = []   # {a, b, n, due, prog, dur}
var sel := -1
var _ia := 0.0
var _crece := 0.0


func _empezar() -> void:
	islas = []
	grupos = []
	sel = -1
	_ia = _num("ia", 3.0)
	_crece = 0.0
	for i in POS.size():
		var due := 1 if i == 0 else (2 if i == POS.size() - 1 else 0)
		islas.append({"p": POS[i], "due": due, "n": 10 if due != 0 else int(_num("tropas", 12))})


func _centro(i: int) -> Vector2:
	var m := 70.0
	return Vector2(m + (islas[i]["p"].x) * (size.x - 2 * m), 130.0 + (islas[i]["p"].y) * (size.y - 200.0))


func _paso(dt: float) -> void:
	_crece += dt
	if _crece >= 1.2:
		_crece = 0.0
		for i in islas:
			if i["due"] != 0 and i["n"] < 40:
				i["n"] += 1
	for g in grupos.duplicate():
		g["prog"] += dt / g["dur"]
		if g["prog"] >= 1.0:
			grupos.erase(g)
			var d: Dictionary = islas[g["b"]]
			if d["due"] == g["due"]:
				d["n"] += g["n"]
			elif g["n"] > d["n"]:
				d["n"] = g["n"] - d["n"]
				d["due"] = g["due"]
				_sonido.tocar(700.0, 0.1)
			else:
				d["n"] -= g["n"]
	_ia -= dt
	if _ia <= 0.0:
		_ia = _num("ia", 3.0)
		_mover_rival()
	var mias := 0
	var suyas := 0
	for i in islas:
		if i["due"] == 1:
			mias += 1
		elif i["due"] == 2:
			suyas += 1
	for g in grupos:
		if g["due"] == 1:
			mias += 1
		else:
			suyas += 1
	if suyas == 0:
		puntos += 100
		_ganar("¡Conquistaste todas las islas!")
	elif mias == 0:
		_perder("Perdiste todas tus islas")


func _enviar(a: int, b: int, due: int) -> void:
	var n: int = int(islas[a]["n"] / 2)
	if n < 1:
		return
	islas[a]["n"] -= n
	grupos.append({"a": a, "b": b, "n": n, "due": due, "prog": 0.0, "dur": maxf(0.6, _centro(a).distance_to(_centro(b)) / 220.0)})


func _mover_rival() -> void:
	var mejor_a := -1
	for k in islas.size():
		if islas[k]["due"] == 2 and islas[k]["n"] > 8 and (mejor_a < 0 or islas[k]["n"] > islas[mejor_a]["n"]):
			mejor_a = k
	if mejor_a < 0:
		return
	var mejor_b := -1
	var puntaje := 1.0e9
	for k in islas.size():
		if islas[k]["due"] != 2:
			var s: float = float(islas[k]["n"]) * 8.0 + _centro(mejor_a).distance_to(_centro(k)) * 0.1
			if s < puntaje:
				puntaje = s
				mejor_b = k
	if mejor_b >= 0:
		_enviar(mejor_a, mejor_b, 2)


func _dibujar(ci: CanvasItem) -> void:
	_txt(ci, "Toca una isla tuya y luego otra para atacar o reforzar", Vector2(20, 36), 22)
	var cols := [Color("94a3b8"), Color("3b82f6"), Color("ef4444")]
	for k in islas.size():
		var c := _centro(k)
		ci.draw_circle(c, 46.0, Color(0, 0, 0, 0.25))
		ci.draw_circle(c, 42.0, cols[islas[k]["due"]])
		if k == sel:
			ci.draw_arc(c, 50.0, 0.0, TAU, 40, Color.WHITE, 5.0)
		_txt(ci, str(islas[k]["n"]), c + Vector2(0, 9), 28, Color.WHITE, 1)
		_zonas.append([Rect2(c - Vector2(50, 50), Vector2(100, 100)), k])
	for g in grupos:
		var p: Vector2 = _centro(g["a"]).lerp(_centro(g["b"]), g["prog"])
		ci.draw_circle(p, 16.0, cols[g["due"]])
		_txt(ci, str(g["n"]), p + Vector2(0, 7), 18, Color.WHITE, 1)


func _al_pulsar(id: Variant) -> void:
	var k := int(id)
	if sel < 0:
		if islas[k]["due"] == 1:
			sel = k
	else:
		if k != sel:
			_enviar(sel, k, 1)
		sel = -1
