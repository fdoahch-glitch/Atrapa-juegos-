extends "res://scripts/juego_mini.gd"
## Preguntas y respuestas: acierta para sumar puntos; cada error cuesta una vida.

var preguntas: Array = []
var i_preg := 0
var _espera := 0.0
var _resp := -1


func mini_usa_vidas() -> bool:
	return true


func _empezar() -> void:
	preguntas = []
	for l in _lineas("preguntas"):
		var p: PackedStringArray = l.split("|")
		if p.size() >= 3:
			var ops: Array = []
			for o in p[1].split(";"):
				ops.append(o.strip_edges())
			preguntas.append({"q": p[0].strip_edges(), "o": ops, "ok": clampi(int(p[2]) - 1, 0, maxi(0, ops.size() - 1))})
	i_preg = 0
	_espera = 0.0
	_resp = -1
	total = preguntas.size()


func _paso(dt: float) -> void:
	if preguntas.is_empty():
		_perder("Escribe preguntas en el panel Contenido")
		return
	if _espera > 0.0:
		_espera -= dt
		if _espera <= 0.0:
			_resp = -1
			i_preg += 1
			if vidas <= 0:
				_perder("Te quedaste sin vidas")
			elif i_preg >= preguntas.size():
				_ganar("Respondiste bien %d de %d" % [recogidos, total])


func _dibujar(ci: CanvasItem) -> void:
	if preguntas.is_empty() or i_preg >= preguntas.size():
		return
	var q: Dictionary = preguntas[i_preg]
	_txt(ci, "Pregunta %d de %d" % [i_preg + 1, total], Vector2(20, 36), 24)
	var y := _parrafo(ci, q["q"], Vector2(40, size.y * 0.22), size.x - 80, 32)
	for k in q["o"].size():
		var col := Color("2563eb")
		if _resp >= 0:
			if k == q["ok"]:
				col = Color("22c55e")
			elif k == _resp:
				col = Color("ef4444")
		_boton(ci, Rect2(40, maxf(y, size.y * 0.4) + k * 70, size.x - 80, 60), "%s" % q["o"][k], col, k, 24)


func _al_pulsar(id: Variant) -> void:
	if _espera > 0.0:
		return
	_resp = int(id)
	var q: Dictionary = preguntas[i_preg]
	if _resp == q["ok"]:
		recogidos += 1
		puntos += 10
		_sonido.tocar(900.0, 0.12)
	else:
		vidas -= 1
		_sonido.tocar(150.0, 0.2, "sierra")
	_espera = 1.0
