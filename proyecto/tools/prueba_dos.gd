extends Node
const Partida := preload("res://scripts/partida.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("  ok  " if c else "  MAL ") + m)
	if not c: fallos += 1
func _tecla(k: int) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = true
	Input.parse_input_event(e)
func _ready() -> void:
	var n := Datos.normalizar(Datos.nivel_corredor())
	var p := Datos.proyecto_desde(n)
	p["reglas"]["jugadores"] = 2
	var pa: Control = Partida.new()
	add_child(pa)
	pa.size = Vector2(1280, 720)
	pa.iniciar(p, 0, false, false, false)
	for f in 3:
		await get_tree().process_frame
	var j = pa._juego
	ok(j.j2 and j._s_jug2 != null, "hay segundo jugador")
	j._input(_ev(KEY_A)); j._input(_ev(KEY_RIGHT)); j._input(_ev(KEY_UP))
	for f in 12:
		await get_tree().process_frame
	ok(j.carril == 0 and j.carril2 == 2, "cada uno en su carril: %d y %d" % [j.carril, j.carril2])
	ok(j.vy2 > 0.0 or j.py2 > 0.0, "salta solo el jugador 2")
	ok(j.py == 0.0, "el jugador 1 no saltó")
	for f in 40:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/dino/dos.png")
	# el jugador 2 choca solo con su carril
	var v0: int = j.vidas
	j.obst.append({"t": "pared", "lane": 2, "z": j.dist + 0.1, "nodo": Node3D.new(), "golpeado": false})
	for f in 10:
		await get_tree().process_frame
	ok(j.vidas == v0 - 1, "el choque del jugador 2 resta una vida (%d)" % j.vidas)
	print("FALLOS: ", fallos)
	get_tree().quit(fallos)
func _ev(k: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = true
	return e
