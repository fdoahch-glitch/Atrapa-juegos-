extends "res://scripts/juego_mini.gd"
## Parejas: da vuelta cartas y encuentra los pares iguales.

var cartas: Array = []
var _sel: Array = []
var _espera := 0.0
var intentos := 0


func _empezar() -> void:
	cartas = []
	_sel = []
	_espera = 0.0
	intentos = 0
	var lista: Array = []
	for e in str(cfg.get("emojis", "🐱 🐶")).split(" ", false):
		lista.append(e)
	if lista.size() < 2:
		lista = ["🐱", "🐶"]
	for e in lista + lista:
		cartas.append({"e": e, "abierta": false, "ok": false})
	cartas.shuffle()
	total = lista.size()


func _paso(dt: float) -> void:
	if _espera > 0.0:
		_espera -= dt
		if _espera <= 0.0:
			for i in _sel:
				cartas[i]["abierta"] = false
			_sel = []
			var lim := int(cfg.get("intentos", 0))
			if lim > 0 and intentos >= lim and recogidos < total:
				_perder("Se acabaron los intentos")


func _geom() -> Array:
	var n := cartas.size()
	var cols := int(ceil(sqrt(float(n) * size.x / maxf(size.y, 1.0))))
	cols = clampi(cols, 2, n)
	var filas := int(ceil(float(n) / float(cols)))
	var lado := minf((size.x - 60.0) / cols, (size.y - 170.0) / filas)
	var ox := (size.x - lado * cols) / 2.0
	var oy := 110.0 + ((size.y - 130.0) - lado * filas) / 2.0
	return [cols, lado, ox, oy]


func _dibujar(ci: CanvasItem) -> void:
	_txt(ci, "Parejas: %d de %d" % [recogidos, total], Vector2(20, 36), 26)
	var lim := int(cfg.get("intentos", 0))
	_txt(ci, "Intentos: %d%s" % [intentos, "" if lim == 0 else " / %d" % lim], Vector2(20, 70), 20)
	var g := _geom()
	for i in cartas.size():
		var c: Dictionary = cartas[i]
		var r := Rect2(g[2] + (i % g[0]) * g[1] + 5, g[3] + (i / g[0]) * g[1] + 5, g[1] - 10, g[1] - 10)
		var visible: bool = c["abierta"] or c["ok"]
		ci.draw_style_box(Estilo.caja(Color.WHITE if visible else Color("8b5cf6"), 18), r)
		if visible:
			Dibujo.emoji(ci, c["e"], r.get_center(), r.size.x * 0.7)
		else:
			_txt(ci, "?", r.get_center() + Vector2(0, r.size.y * 0.18), int(r.size.x * 0.5), Color.WHITE, 1)
		_zonas.append([r, i])


func _al_pulsar(i: Variant) -> void:
	if _espera > 0.0 or cartas[i]["abierta"] or cartas[i]["ok"]:
		return
	cartas[i]["abierta"] = true
	_sonido.tocar(600.0, 0.06)
	_sel.append(i)
	if _sel.size() == 2:
		intentos += 1
		if cartas[_sel[0]]["e"] == cartas[_sel[1]]["e"]:
			cartas[_sel[0]]["ok"] = true
			cartas[_sel[1]]["ok"] = true
			_sel = []
			recogidos += 1
			puntos += 10
			_sonido.tocar(900.0, 0.12)
			if recogidos >= total:
				_ganar("Lo hiciste en %d intentos" % intentos)
		else:
			_espera = 0.8
