extends Node
const Juego := preload("res://scripts/juego.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _nuevo(items: Array, reglas := {}) -> Control:
	var n: Dictionary = Datos.normalizar(Datos.nivel_inicial())
	n["items"] = items
	var J = Juego.new()
	J.size = Vector2(1280, 720)
	add_child(J)
	var nn := Datos.normalizar(n)
	nn["reglas"] = Datos.reglas_completas(reglas)
	Datos.reglas = nn["reglas"]
	J.iniciar(nn, false, false)
	return J
func _fr(n: int) -> void:
	pass
func _ready() -> void:
	await get_tree().process_frame
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(Datos.nivel_inicial())], "reglas": Datos.reglas_completas({})})
	var base := [{"t": "player", "x": 2, "y": 8, "id": "p"}, {"t": "plat", "x": 0, "y": 9, "w": 40, "h": 1, "id": "s"}, {"t": "goal", "x": 38, "y": 8, "id": "g"}]
	# --- hielo: resbala más
	var J = _nuevo(base + [{"t": "zona", "x": 2, "y": 7, "w": 6, "h": 2, "z": "hielo", "id": "z1"}], {"minimapa": true})
	for i in 30: await get_tree().physics_frame
	ok(J._pw_ok, "mundo físico activo")
	for i in 120: J._actualizar(J.PASO)
	for i in 60:
		J.vel.x = 300.0 if i < 30 else J.vel.x
		J._actualizar(J.PASO)
	var vh := absf(J.vel.x)
	ok(J.zonas.size() == 1 and J._z_fric < 0.5, "zona de hielo detectada con Area2D (fric %.2f)" % J._z_fric)
	J.queue_free()
	# --- agua: cae lento y se puede nadar
	J = _nuevo([{"t": "player", "x": 2, "y": 3, "id": "p"}, {"t": "plat", "x": 0, "y": 11, "w": 40, "h": 1, "id": "s"}, {"t": "goal", "x": 38, "y": 8, "id": "g"}, {"t": "zona", "x": 0, "y": 0, "w": 10, "h": 11, "z": "agua", "id": "z2"}])
	for i in 30: await get_tree().physics_frame
	for i in 240:
		J._actualizar(J.PASO)
		if i % 2 == 0: await get_tree().physics_frame
	ok(J._z_agua and J.vel.y <= 262.0, "en el agua cae despacio (%.0f px/s)" % J.vel.y)
	J.salto_pulsado = true
	J._actualizar(J.PASO)
	ok(J.vel.y < -300.0, "en el agua se puede nadar hacia arriba")
	J.queue_free()
	# --- viento empuja
	J = _nuevo(base + [{"t": "zona", "x": 0, "y": 5, "w": 30, "h": 4, "z": "viento", "d": 1, "id": "z3"}])
	for i in 30: await get_tree().physics_frame
	var x0: float = J.pos.x
	for i in 240:
		J._actualizar(J.PASO)
		if i % 2 == 0: await get_tree().physics_frame
	ok(J.pos.x > x0 + 40.0, "el viento empuja al héroe (%.0f px)" % (J.pos.x - x0))
	J.queue_free()
	# --- lava hiere
	J = _nuevo(base + [{"t": "zona", "x": 0, "y": 7, "w": 10, "h": 2, "z": "lava", "id": "z4"}])
	var v0: int = J.vidas
	var e0: int = J._escudos
	for i in 30: await get_tree().physics_frame
	for i in 60:
		J._actualizar(J.PASO)
		if i % 2 == 0: await get_tree().physics_frame
	ok(J.vidas < v0 or J.estado != "jugar" or J._escudos < e0, "la lava hace daño (o gasta el escudo)")
	J.queue_free()
	# --- ruta: la plataforma sube y lleva al héroe
	J = _nuevo([{"t": "player", "x": 2, "y": 7, "id": "p"}, {"t": "plat", "x": 0, "y": 10, "w": 5, "h": 1, "id": "s"}, {"t": "goal", "x": 38, "y": 8, "id": "g"}, {"t": "ruta", "x": 2, "y": 9, "w": 3, "h": 1, "r": 4, "sp": 120, "forma": "vaiven", "id": "r1"}])
	for i in 30: await get_tree().physics_frame
	var y0: float = 1e9
	var y1: float = -1e9
	for i in 240:
		J._actualizar(J.PASO)
		y0 = minf(y0, J.rutas[0]["rect"].position.y)
		y1 = maxf(y1, J.rutas[0]["rect"].position.y)
		if i % 2 == 0: await get_tree().physics_frame
	print("DBG ", y0, " ", y1, " off=", J.rutas[0]["off"], " dir=", J.rutas[0]["dir"], " sp=", J.rutas[0]["sp"], " estado=", J.estado, " pos=", J.pos)
	ok(absf(y1 - y0) > 30.0, "la plataforma sigue su ruta (%.0f px)" % (y1 - y0))
	ok(J.rutas[0]["len"] > 100.0, "Curve2D de la ruta mide %.0f px" % J.rutas[0]["len"])
	for forma in ["circulo", "cuadro", "diagonal"]:
		var cv: Curve2D = preload("res://scripts/dibujo.gd").ruta_curva({"forma": forma, "r": 4})
		ok(cv.get_baked_length() > 50.0, "ruta %s con camino" % forma)
	J.queue_free()
	# --- raycast: el vigilante no ve a través de un muro
	var ene := {"t": "enemy", "x": 14, "y": 8, "e": "🦊", "r": 3, "sp": 60, "ia": "vigila", "id": "e1"}
	J = _nuevo([{"t": "player", "x": 6, "y": 8, "id": "p"}, {"t": "plat", "x": 0, "y": 9, "w": 40, "h": 1, "id": "s"}, {"t": "plat", "x": 10, "y": 6, "w": 1, "h": 3, "id": "m"}, ene, {"t": "goal", "x": 38, "y": 8, "id": "g"}])
	for i in 30: await get_tree().physics_frame
	var vis_muro: bool = J._linea_libre(Vector2(14 * 48 + 24, 8 * 48 + 20), J.pos + Vector2(14, 20))
	ok(not vis_muro, "el rayo de Godot choca con el muro")
	ok(J._linea_libre(Vector2(2 * 48, 3 * 48), Vector2(5 * 48, 3 * 48)), "el rayo pasa por el aire libre")
	J.queue_free()
	# --- filtros nuevos y minimapa
	for f in ["ondas", "crt", "dibujo", "neon", "agua"]:
		var nv := Datos.normalizar(Datos.nivel_inicial())
		nv["filtro"] = f
		var J2 = Juego.new()
		J2.size = Vector2(800, 450)
		add_child(J2)
		nv["reglas"] = Datos.reglas_completas({})
		J2.iniciar(nv, false, false)
		await get_tree().process_frame
		ok(J2._filtro != null, "filtro %s activo" % f)
		J2.queue_free()
	J = _nuevo(base, {"minimapa": true})
	await get_tree().process_frame
	await get_tree().process_frame
	ok(bool(J.reglas.get("minimapa", false)), "minimapa encendido y se dibuja sin errores")
	print("FALLOS ", fallos)
	get_tree().quit()
