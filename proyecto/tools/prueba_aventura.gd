extends Node
# Prueba lógica de la Aventura 3D: bloques, monedas, enemigos, pinchos y meta.
const JA := preload("res://scripts/juego_aventura.gd")
func _crear() -> Control:
	var j: Control = JA.new()
	add_child(j)
	j.size = Vector2(1280, 720)
	j.iniciar(Datos.nivel_aventura(), false, false)
	return j
func _correr(j, n: int) -> void:
	for i in n:
		j._actualizar(1.0 / 60.0)
func _ready() -> void:
	var fallos := 0
	var j := _crear()
	# 1) bloque: caer sobre el bloque de altura 2 en (12..16, 8..10) -> aterriza arriba
	j.p3 = Vector3(14.0 * 2.0 - 1.0, 3.0, 9.0 * 2.0)
	_correr(j, 60)
	print("aterriza sobre bloque: y=", snapped(j.p3.y, 0.01), " (esperado 2.0)")
	if absf(j.p3.y - 2.0) > 0.05: fallos += 1
	# 2) moneda
	j = _crear()
	var m: Dictionary = j.premios[0]
	j.p3 = Vector3(m["x"], 0, m["z"])
	_correr(j, 3)
	print("moneda recogida: ", j.recogidos, " puntos=", j.puntos)
	if j.recogidos < 1: fallos += 1
	# 3) pinchos hieren
	j = _crear()
	var pe: Dictionary = j.peligros[0]
	j.p3 = Vector3(pe["x"], 0, pe["z"])
	_correr(j, 3)
	print("pinchos: vidas=", j.vidas)
	if j.vidas != 2: fallos += 1
	# 4) pisar enemigo
	j = _crear()
	var b: Dictionary = j.bichos[0]
	j.p3 = Vector3(b["x"], 1.6, b["z"])
	j.vy = -6.0
	_correr(j, 4)
	print("enemigo pisado: muerto=", b["muerto"], " puntos=", j.puntos)
	if not b["muerto"]: fallos += 1
	# 5) tocar enemigo de lado hiere
	j = _crear()
	b = j.bichos[0]
	j.p3 = Vector3(b["x"], 0, b["z"])
	_correr(j, 3)
	print("enemigo de lado: vidas=", j.vidas)
	if j.vidas != 2: fallos += 1
	# 6) pared de bloque: no se puede atravesar a nivel del suelo
	j = _crear()
	j.p3 = Vector3(5.0, 0, 7.0)   # bloque (8..11,3..5) x 2m => x 16..22, z 6..10
	j.p3 = Vector3(14.0, 0, 8.0)
	for i in 120:
		j._joy = Vector2(1, 0)
		j._actualizar(1.0 / 60.0)
	print("bloque bloquea: x=", snapped(j.p3.x, 0.1), " (debe quedar < 15.5)")
	if j.p3.x > 15.6: fallos += 1
	# 7) meta
	j = _crear()
	j.p3 = Vector3(j.meta_pos.x, 0, j.meta_pos.y)
	_correr(j, 3)
	print("meta: estado=", j.estado)
	if j.estado != "gano": fallos += 1
	print("FALLOS: ", fallos)
	get_tree().quit(fallos)
