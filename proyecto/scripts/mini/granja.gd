extends "res://scripts/juego_mini.gd"
## Granja: siembra, riega y cosecha para juntar monedas.

const COLS := 4
const FILAS_G := 3

var parcelas: Array = []
var monedas := 10
var elegido := 0
var _cult: Array = []


func _empezar() -> void:
	_cult = []
	for l in _lineas("cultivos"):
		var p: PackedStringArray = l.split(" ", false)
		if p.size() >= 3:
			_cult.append({"e": p[0], "seg": maxf(1.0, float(p[1])), "precio": int(p[2])})
	if _cult.is_empty():
		_cult = [{"e": "🥕", "seg": 8.0, "precio": 6}]
	parcelas = []
	for i in COLS * FILAS_G:
		parcelas.append({"c": -1, "p": 0.0, "regada": false})
	monedas = 10
	elegido = 0


func _paso(dt: float) -> void:
	for pa in parcelas:
		if pa["c"] >= 0 and pa["p"] < 1.0:
			pa["p"] = minf(1.0, pa["p"] + dt / _cult[pa["c"]]["seg"])


func _lado() -> float:
	return minf((size.x - 40.0) / COLS, (size.y - 250.0) / FILAS_G)


func _dibujar(ci: CanvasItem) -> void:
	var l := _lado()
	var ox := (size.x - l * COLS) / 2.0
	var oy := 110.0
	_txt(ci, "Monedas: %d / %d" % [monedas, int(cfg.get("meta", 80))], Vector2(20, 36), 26)
	_txt(ci, "Semilla = 2 monedas · toca una parcela: siembra, riega (crece más rápido) y cosecha", Vector2(20, 70), 17, Color(1, 1, 1, 0.9))
	for i in parcelas.size():
		var pa: Dictionary = parcelas[i]
		var r := Rect2(ox + (i % COLS) * l + 4, oy + (i / COLS) * l + 4, l - 8, l - 8)
		ci.draw_style_box(Estilo.caja(Color("7c5a3a") if not pa["regada"] else Color("5b4228"), 14), r)
		if pa["c"] >= 0:
			if pa["p"] >= 1.0:
				Dibujo.emoji(ci, _cult[pa["c"]]["e"], r.get_center(), r.size.x * 0.65)
			else:
				Dibujo.emoji(ci, "🌱", r.get_center(), r.size.x * (0.25 + pa["p"] * 0.35))
				ci.draw_rect(Rect2(r.position.x + 8, r.end.y - 14, (r.size.x - 16) * pa["p"], 6), Color("22c55e"))
		_zonas.append([r, i])
	var by := oy + l * FILAS_G + 16.0
	var bw := minf(150.0, (size.x - 40.0) / maxf(1.0, _cult.size()) - 8.0)
	for j in _cult.size():
		var r2 := Rect2(20 + j * (bw + 8), by, bw, 56)
		_boton(ci, r2, "    %d seg · %d" % [int(_cult[j]["seg"]), _cult[j]["precio"]], Color("2563eb") if j == elegido else Color(1, 1, 1, 0.25), 1000 + j, 16)
		Dibujo.emoji(ci, _cult[j]["e"], Vector2(r2.position.x + 24, r2.get_center().y), 34.0)


func _al_pulsar(id: Variant) -> void:
	var i := int(id)
	if i >= 1000:
		elegido = i - 1000
		return
	var pa: Dictionary = parcelas[i]
	if pa["c"] < 0:
		if monedas >= 2:
			monedas -= 2
			pa["c"] = elegido
			pa["p"] = 0.0
			pa["regada"] = false
			_sonido.tocar(500.0, 0.06)
		else:
			_decir("Te faltan monedas para una semilla")
	elif pa["p"] >= 1.0:
		var g: int = _cult[pa["c"]]["precio"]
		monedas += g
		puntos += g
		recogidos += 1
		pa["c"] = -1
		_sonido.tocar(900.0, 0.1)
		if monedas >= int(cfg.get("meta", 80)):
			_ganar("Juntaste %d monedas" % monedas)
	elif not pa["regada"]:
		pa["regada"] = true
		pa["p"] = minf(1.0, pa["p"] + 0.35)
		_sonido.tocar(420.0, 0.06)
