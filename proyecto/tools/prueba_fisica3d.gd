extends Node
const JA := preload("res://scripts/juego_aventura.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	await get_tree().process_frame
	var j: Control = JA.new()
	add_child(j)
	j.size = Vector2(1280, 720)
	j.iniciar(Datos.nivel_aventura(), false, false)
	for i in 30: await get_tree().physics_frame
	ok(j._p3_ok, "mundo físico 3D activo")
	# caer sobre el bloque de altura 2 que ocupa x 12..16 (celdas*2), z 8..10
	j.p3 = Vector3(14.0 * 2.0 - 1.0, 3.0, 9.0 * 2.0)
	for i in 120:
		j._actualizar(1.0 / 120.0)
	var top: float = j.p3.y
	ok(absf(top - 2.0) < 0.1 and j.enelsuelo, "aterriza sobre el bloque con física real (y=%.2f)" % top)
	# en el suelo: no atraviesa un bloque alto caminando de frente
	j.p3 = Vector3(10.0 * 2.0 - 1.5, 0.0, 9.0 * 2.0)
	j.vy = 0.0
	var maxx := 0.0
	for i in 240:
		j._mover_godot(Vector2(1, 0), 1.0 / 120.0)
		maxx = maxf(maxx, j.p3.x)
	print("   x máximo contra el bloque: ", maxx)
	ok(maxx < 12.0 * 2.0 - 0.3 or j.p3.y > 1.5, "un bloque alto frena al héroe (no lo atraviesa)")
	# salto en el suelo libre
	j.p3 = Vector3(5.0, 0.0, 5.0)
	j.vy = 0.0
	j.enelsuelo = true
	for i in 30:
		j._mover_godot(Vector2.ZERO, 1.0 / 120.0)
	ok(j.enelsuelo and absf(j.p3.y) < 0.05, "de pie sobre el suelo")
	j._salto = true
	var ymax := 0.0
	for i in 120:
		j._mover_godot(Vector2.ZERO, 1.0 / 120.0)
		ymax = maxf(ymax, j.p3.y)
	ok(ymax > 1.5 and ymax < 2.1, "salta %.2f m" % ymax)
	print("FALLOS ", fallos)
	get_tree().quit()
