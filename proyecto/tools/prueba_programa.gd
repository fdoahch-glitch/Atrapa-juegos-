extends Node
const Juego := preload("res://scripts/juego.gd")
const PanelB := preload("res://scripts/panel_bloques.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	await get_tree().process_frame
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(Datos.nivel_inicial())], "reglas": Datos.reglas_completas({})})
	var n: Dictionary = Datos.normalizar(Datos.nivel_inicial())
	n["items"] = [{"t": "player", "x": 2, "y": 8, "id": "p"}, {"t": "plat", "x": 0, "y": 9, "w": 40, "h": 1, "id": "s"}, {"t": "goal", "x": 38, "y": 8, "id": "g"}, {"t": "door", "x": 10, "y": 7, "id": "d"}]
	n["programa"] = [
		{"cuando": "tiempo", "n": 1, "pasos": [{"b": "puntos", "v": 5}, {"b": "esperar", "v": 1}, {"b": "repetir", "v": 3}, {"b": "puntos", "v": 10}, {"b": "inventado", "v": 1}]},
		{"cuando": "falso", "pasos": []},
		{"cuando": "inicio", "n": 1, "pasos": [{"b": "vida", "v": 2}]}]
	var nn := Datos.normalizar(n)
	ok(nn["programa"].size() == 2, "las pilas inválidas se descartan (%d)" % nn["programa"].size())
	ok(nn["programa"][0]["pasos"].size() == 4, "los bloques inventados se descartan (%d)" % nn["programa"][0]["pasos"].size())
	var J = Juego.new()
	J.size = Vector2(1280, 720)
	add_child(J)
	nn["reglas"] = Datos.reglas_completas({})
	Datos.reglas = nn["reglas"]
	J.iniciar(nn, false, false)
	var v0: int = J.vidas
	J.set_process(false)
	for i in 10: J._actualizar(J.PASO)
	ok(J.vidas == v0 + 2, "«Al empezar» da 2 vidas (%d→%d)" % [v0, J.vidas])
	for i in 130: J._actualizar(J.PASO)   # ~1,1 s
	ok(J.puntos == 5, "tras 1 s se hace el primer bloque (%d)" % J.puntos)
	for i in 120: J._actualizar(J.PASO)   # espera 1 s más
	ok(J.puntos == 5 + 30, "«Repetir 3 veces» da 3×10 después de esperar (%d)" % J.puntos)
	ok(int(J._prog[0]["estado"]) == 2, "la pila termina y no se repite")
	for i in 240: J._actualizar(J.PASO)
	ok(J.puntos == 35, "no vuelve a ejecutarse (%d)" % J.puntos)
	# el panel arma la interfaz con los bloques
	Datos.nivel = nn
	var P = PanelB.new()
	add_child(P)
	P.size = Vector2(1280, 720)
	await get_tree().process_frame
	ok(P.find_child("Pila0", true, false) != null and P.find_child("Bloque0", true, false) != null, "el panel muestra la pila con sus bloques")
	ok(P.find_child("AnadirBloque", true, false) != null and P.find_child("NuevaPila", true, false) != null, "el panel ofrece añadir bloques y pilas")
	print("FALLOS ", fallos)
	get_tree().quit()
