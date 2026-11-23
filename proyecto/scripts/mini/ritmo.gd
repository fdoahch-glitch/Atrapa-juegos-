extends "res://scripts/juego_mini.gd"
## Ritmo: notas que caen por 4 carriles; tócalas cuando lleguen a la línea.

const TECLAS := [KEY_D, KEY_F, KEY_J, KEY_K]
const CAIDA := 1.6
const VENTANA := 0.2

var notas: Array = []
var combo := 0
var fallos := 0
var aciertos := 0
var _destello := [0.0, 0.0, 0.0, 0.0]


func _empezar() -> void:
	notas = []
	combo = 0
	fallos = 0
	aciertos = 0
	_destello = [0.0, 0.0, 0.0, 0.0]
	var paso := 60.0 / maxf(30.0, _num("bpm", 110.0))
	var i := 0
	for tok in str(cfg.get("patron", "1 2 3 4")).split(" ", false):
		if tok in ["1", "2", "3", "4"]:
			notas.append({"c": int(tok) - 1, "t": 2.0 + i * paso, "hecha": false, "perdida": false})
		i += 1
	total = notas.size()


func _paso(dt: float) -> void:
	for k in 4:
		_destello[k] = maxf(0.0, _destello[k] - dt * 4.0)
	var pendientes := 0
	for n in notas:
		if n["hecha"] or n["perdida"]:
			continue
		if t > n["t"] + VENTANA:
			n["perdida"] = true
			fallos += 1
			combo = 0
		else:
			pendientes += 1
	if pendientes == 0:
		if fallos <= int(cfg.get("fallos", 8)):
			_ganar("%d notas acertadas · %d falladas" % [aciertos, fallos])
		else:
			_perder("Fallaste %d notas (máximo %d)" % [fallos, int(cfg.get("fallos", 8))])
	elif fallos > int(cfg.get("fallos", 8)):
		_perder("Fallaste demasiadas notas")


func _linea_y() -> float:
	return size.y * 0.8


func _dibujar(ci: CanvasItem) -> void:
	var w := minf(size.x - 40.0, 520.0)
	var x0 := (size.x - w) / 2.0
	var cw := w / 4.0
	var colores := [Color("ef4444"), Color("f59e0b"), Color("22c55e"), Color("3b82f6")]
	var ly := _linea_y()
	for k in 4:
		var r := Rect2(x0 + k * cw, 0, cw, size.y)
		ci.draw_rect(Rect2(r.position.x + 2, 0, cw - 4, size.y), Color(0, 0, 0, 0.35))
		ci.draw_rect(Rect2(r.position.x + 2, ly - 26, cw - 4, 52), colores[k].lerp(Color.WHITE, _destello[k]) * Color(1, 1, 1, 0.55))
		_txt(ci, "DFJK"[k], Vector2(r.position.x + cw / 2.0, ly + 8), 22, Color.WHITE, 1)
		_zonas.append([r, k])
	for n in notas:
		if n["hecha"] or n["perdida"]:
			continue
		var y: float = ly - (n["t"] - t) / CAIDA * (ly - 40.0)
		if y < -40.0 or y > size.y + 40.0:
			continue
		var cx: float = x0 + n["c"] * cw + cw / 2.0
		ci.draw_circle(Vector2(cx, y), cw * 0.34, colores[n["c"]])
		ci.draw_circle(Vector2(cx, y), cw * 0.2, Color.WHITE)
	_txt(ci, "Combo %d" % combo, Vector2(20, 36), 26)
	_txt(ci, "Fallos %d / %d" % [fallos, int(cfg.get("fallos", 8))], Vector2(20, 68), 20)


func _golpear(c: int) -> void:
	_destello[c] = 1.0
	var mejor: Variant = null
	for n in notas:
		if n["c"] == c and not n["hecha"] and not n["perdida"] and absf(n["t"] - t) <= VENTANA:
			if mejor == null or absf(n["t"] - t) < absf(mejor["t"] - t):
				mejor = n
	if mejor != null:
		mejor["hecha"] = true
		aciertos += 1
		combo += 1
		puntos += 10 + combo
		recogidos += 1
		_sonido.tocar(440.0 + c * 110.0, 0.1)
	else:
		combo = 0


func _al_pulsar(id: Variant) -> void:
	_golpear(int(id))


func _tecla(k: int) -> void:
	var i := TECLAS.find(k)
	if i >= 0:
		_golpear(i)
