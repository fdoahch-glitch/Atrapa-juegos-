extends Node
const Red := preload("res://scripts/red.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	await get_tree().process_frame
	var a := Red.new()
	var b := Red.new()
	add_child(a)
	add_child(b)
	ok(a.crear(24999) == OK, "la sala se crea")
	ok(b.unirse("127.0.0.1", 24999) == OK, "el otro jugador se une")
	for i in 120:
		await get_tree().create_timer(0.02).timeout
		if a.conectados() > 0 and b.conectados() > 0:
			break
	ok(a.conectados() == 1 and b.conectados() == 1, "conectados (%d / %d)" % [a.conectados(), b.conectados()])
	b.enviar({"x": 123.5, "y": 77.0, "c": -1.0, "n": 5})
	a.enviar({"x": 9.0, "y": 8.0, "c": 1.0, "n": 5})
	for i in 60:
		await get_tree().create_timer(0.02).timeout
		if not a.remotos.is_empty() and not b.remotos.is_empty():
			break
	ok(a.remotos.size() == 1 and absf(float(a.remotos.values()[0]["x"]) - 123.5) < 0.01, "el anfitrión ve al invitado en 123.5")
	ok(b.remotos.size() == 1 and absf(float(b.remotos.values()[0]["y"]) - 8.0) < 0.01, "el invitado ve al anfitrión")
	a._llego(99, var_to_bytes("basura"))
	a._llego(99, var_to_bytes({"x": "texto", "y": 1}))
	ok(not a.remotos.has(99), "los paquetes inválidos se ignoran")
	b.cerrar()
	for i in 100:
		await get_tree().create_timer(0.02).timeout
		if a.conectados() == 0:
			break
	ok(a.conectados() == 0 and a.remotos.is_empty(), "al irse un jugador desaparece")
	a.cerrar()
	# dentro del juego: dos partidas se ven entre sí
	const Juego := preload("res://scripts/juego.gd")
	var js: Array = []
	for modo in ["crear", "unirse"]:
		var n: Dictionary = Datos.normalizar(Datos.nivel_inicial())
		var J = Juego.new()
		J.size = Vector2(1280, 720)
		add_child(J)
		var nn := Datos.normalizar(n)
		nn["reglas"] = Datos.reglas_completas({"en_linea": true, "red_modo": modo, "red_puerto": 25001})
		Datos.reglas = nn["reglas"]
		J.iniciar(nn, false, false)
		js.append(J)
	for i in 150:
		await get_tree().create_timer(0.02).timeout
		if not js[0]._red.remotos.is_empty() and not js[1]._red.remotos.is_empty():
			break
	ok(js[0]._red != null and js[1]._red != null, "las dos partidas abren la red")
	ok(not js[0]._red.remotos.is_empty() and not js[1]._red.remotos.is_empty(), "cada partida ve al otro héroe")
	print("FALLOS ", fallos)
	get_tree().quit()
