extends Node
const Juego := preload("res://scripts/juego.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _tecla(k: int, p: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = p
	Input.parse_input_event(ev)
func _nuevo(items: Array) -> Control:
	var n: Dictionary = Datos.normalizar(Datos.nivel_inicial())
	n["items"] = items
	var J = Juego.new()
	J.size = Vector2(1280, 720)
	add_child(J)
	var nn := Datos.normalizar(n)
	nn["reglas"] = Datos.reglas_completas({})
	Datos.reglas = nn["reglas"]
	J.iniciar(nn, false, false)
	return J
func _ready() -> void:
	await get_tree().process_frame
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(Datos.nivel_inicial())], "reglas": Datos.reglas_completas({})})
	var J = _nuevo([{"t": "player", "x": 2, "y": 8, "id": "p"}, {"t": "plat", "x": 0, "y": 11, "w": 40, "h": 1, "id": "s"}, {"t": "goal", "x": 38, "y": 8, "id": "g"}, {"t": "cuerda", "x": 10, "y": 1, "r": 4, "id": "c"}])
	J.set_process(false)
	J._pw_vigilar()
	for i in 40: await get_tree().physics_frame
	ok(J._pw_ok, "mundo físico activo")
	var seg: RigidBody2D = J._pw_cuerdas[0]["segs"][3]
	J.pos = seg.position - Vector2(J.PW * 24.0, 40.0)
	J.vel = Vector2.ZERO
	J.suelo = false
	_tecla(KEY_UP, true)
	for i in 6:
		J._actualizar(J.PASO)
		await get_tree().physics_frame
	ok(not J._agarre.is_empty(), "el héroe agarra la cuerda en el aire")
	_tecla(KEY_UP, false)
	var x0: float = J.pos.x
	_tecla(KEY_RIGHT, true)
	var xmax := x0
	for i in 150:
		J._actualizar(J.PASO)
		if i % 2 == 0: await get_tree().physics_frame
		xmax = maxf(xmax, J.pos.x)
	#print("DBG right=", Input.is_key_pressed(KEY_RIGHT), " k=", J._agarre.get("k"), " rbpos=", (J._agarre["cu"]["segs"][int(J._agarre["k"])] as RigidBody2D).position, " lv=", (J._agarre["cu"]["segs"][int(J._agarre["k"])] as RigidBody2D).linear_velocity, " sleeping=", (J._agarre["cu"]["segs"][int(J._agarre["k"])] as RigidBody2D).sleeping, " mode=", J._pw.process_mode)
	_tecla(KEY_RIGHT, false)
	ok(xmax > x0 + 15.0 and not J._agarre.is_empty(), "al mecerse arrastra al héroe (%.0f px)" % (xmax - x0))
	var k0: int = J._agarre["k"]
	_tecla(KEY_UP, true)
	for i in 60:
		J._actualizar(J.PASO)
		if i % 2 == 0: await get_tree().physics_frame
	ok(not J._agarre.is_empty() and int(J._agarre["k"]) < k0, "trepa hacia arriba con ↑ (segmento %d → %d)" % [k0, J._agarre["k"]])
	_tecla(KEY_UP, false)
	J._actualizar(J.PASO)
	J.salto_pulsado = true
	J._actualizar(J.PASO)
	J._actualizar(J.PASO)
	ok(J._agarre.is_empty() and J.vel.y < -300.0, "al saltar se suelta con impulso (vy %.0f)" % J.vel.y)
	J.queue_free()
	# pelota sobre una plataforma en ruta: el cuerpo animado la sostiene
	J = _nuevo([{"t": "player", "x": 2, "y": 8, "id": "p"}, {"t": "plat", "x": 0, "y": 11, "w": 40, "h": 1, "id": "s"}, {"t": "goal", "x": 38, "y": 8, "id": "g"}, {"t": "ruta", "x": 20, "y": 8, "w": 4, "h": 1, "r": 3, "sp": 60, "forma": "vaiven", "id": "r"}, {"t": "pelota", "x": 21, "y": 2, "r": 1, "id": "b"}])
	for i in 40: await get_tree().physics_frame
	var bola: RigidBody2D = J._pw_rig[0]["body"]
	var peor_y := -1e9
	for i in 400:
		await get_tree().physics_frame
		var rect: Rect2 = J.rutas[0]["rect"]
		if i > 200:
			peor_y = maxf(peor_y, bola.position.y - rect.position.y)
	ok(J._pw_anim.size() >= 1, "la ruta tiene su cuerpo animado")
	ok(peor_y < 10.0, "la pelota queda sobre la plataforma en ruta (diferencia %.0f px)" % peor_y)
	print("FALLOS ", fallos)
	get_tree().quit()
