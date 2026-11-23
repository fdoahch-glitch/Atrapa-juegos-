extends Node
const Juego := preload("res://scripts/juego.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	await get_tree().process_frame
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(Datos.nivel_inicial())], "reglas": Datos.reglas_completas({})})
	var n: Dictionary = Datos.normalizar(Datos.nivel_inicial())
	n["items"] = [
		{"t": "player", "x": 2, "y": 8, "id": 1},
		{"t": "plat", "x": 0, "y": 9, "w": 30, "h": 1, "id": 2},
		{"t": "plat", "x": 12, "y": 7, "w": 3, "h": 1, "id": 3},
		{"t": "rueda", "x": 8, "y": 7, "r": 2, "id": 4},
		{"t": "pelota", "x": 5, "y": 3, "r": 1, "id": 5},
		{"t": "cuerda", "x": 20, "y": 2, "r": 3, "id": 6},
		{"t": "goal", "x": 28, "y": 8, "id": 7}]
	var J = Juego.new()
	J.size = Vector2(1280, 720)
	add_child(J)
	J.iniciar(Datos.normalizar(n), false, false)
	for i in 30:
		await get_tree().physics_frame
	ok(J._pw_ok, "mundo físico de Godot activo")
	ok(J._pw_rig.size() == 2 and J._pw_cuerdas.size() == 1, "rueda, pelota y cuerda creadas")
	# el héroe cae y aterriza con la física real
	for i in 240:
		J._actualizar(J.PASO)
	ok(J.suelo, "héroe apoyado en el suelo (Godot)")
	ok(absf(J.pos.y + J.PH * 48.0 - 9 * 48.0) < 0.5, "héroe sobre la plataforma: y=%.2f" % J.pos.y)
	# la pelota cae y rebota
	var pel: RigidBody2D = null
	var rue: RigidBody2D = null
	for o in J._pw_rig:
		if o["t"] == "pelota": pel = o["body"]
		else: rue = o["body"]
	var min_y := 1e9
	var rebotes := 0
	var vy_ant := 0.0
	for i in 600:
		await get_tree().physics_frame
		if vy_ant > 100.0 and pel.linear_velocity.y < -50.0: rebotes += 1
		vy_ant = pel.linear_velocity.y
	ok(rebotes >= 1, "la pelota rebota (%d rebotes)" % rebotes)
	ok(absf(rue.position.y + 48.0 - 9 * 48.0) < 3.0, "la rueda reposa sobre el suelo y=%.1f" % rue.position.y)
	# empujar la rueda hacia la derecha
	J.pos = Vector2(5 * 48.0, 9 * 48.0 - J.PH * 48.0 - 0.05)
	var x0 := rue.position.x
	var d := InputEventKey.new()
	for i in 400:
		J.vel.x = 300.0
		J._actualizar(J.PASO)
		if i % 2 == 0: await get_tree().physics_frame
	ok(rue.position.x > x0 + 30.0, "empujar la rueda la hace rodar (%.0f px) giro=%.1f rad" % [rue.position.x - x0, rue.rotation])
	ok(absf(rue.rotation) > 0.3, "la rueda gira al rodar")
	# cuerda: se mece si se empuja
	var sg: RigidBody2D = J._pw_cuerdas[0]["segs"][J._pw_cuerdas[0]["segs"].size() - 1]
	sg.apply_central_impulse(Vector2(200.0, 0.0))
	var xmax := 0.0
	for i in 120:
		await get_tree().physics_frame
		xmax = maxf(xmax, absf(sg.position.x - 20.5 * 48.0))
	ok(xmax > 20.0, "la cuerda se balancea (%.0f px)" % xmax)
	# plataforma flotante: salta y se apoya encima
	J.pos = Vector2(12.5 * 48.0, 5.0 * 48.0)
	J.vel = Vector2.ZERO
	for i in 240:
		J._actualizar(J.PASO)
	ok(J.suelo and absf(J.pos.y + J.PH * 48.0 - 7 * 48.0) < 0.5, "aterriza encima de la plataforma flotante")
	# golpe de cabeza: la plataforma ocupa y=7 (bottom 384); el héroe sube desde abajo
	var peor := 1e9
	J.pos = Vector2(12.5 * 48.0, 8.0 * 48.0 + 6.0)
	J.vel = Vector2(0, -900.0)
	for i in 40:
		J._actualizar(J.PASO)
		peor = minf(peor, J.pos.y)
		if J.suelo: J.vel.y = -900.0
	ok(peor >= 8 * 48.0 - 0.5, "no atraviesa la plataforma desde abajo (min y=%.1f)" % peor)
	print("FALLOS ", fallos)
	get_tree().quit()
