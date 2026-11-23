extends Node
const JA := preload("res://scripts/juego_arriba.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	await get_tree().process_frame
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(Datos.nivel_arriba())], "reglas": Datos.reglas_completas({})})
	var n: Dictionary = Datos.normalizar(Datos.nivel_arriba())
	var items := [{"t": "player", "x": 2, "y": 6, "id": "p"}, {"t": "goal", "x": 25, "y": 2, "id": "g"},
		{"t": "enemy", "x": 9, "y": 6, "e": "🦊", "r": 1, "sp": 120, "ia": "persigue", "id": "e"}]
	# muro vertical con un hueco abajo (y=11)
	for y in range(1, 11):
		items.append({"t": "plat", "x": 7, "y": y, "w": 1, "h": 1, "id": "m%d" % y})
	n["items"] = items
	var J = JA.new()
	J.size = Vector2(1280, 720)
	add_child(J)
	n["reglas"] = Datos.reglas_completas({"vidas": 99})
	J.iniciar(Datos.normalizar(n), false, false)
	await get_tree().process_frame
	ok(J._astar != null, "mapa de navegación creado")
	var e: Dictionary = J.enemigos[0]
	var ruta: Array = J._astar.get_id_path(Vector2i(9, 6), Vector2i(2, 6))
	ok(ruta.size() > 12, "A* rodea el muro (%d pasos, directo serían 10)" % ruta.size())
	var cruzo_muro := false
	var llego := false
	for i in 2400:
		J._actualizar(J.PASO)
		J.inv = 99.0
		if absf(float(e["x"]) - 7.0) < 0.4 and float(e["y"]) < 10.5:
			cruzo_muro = true
		if Vector2(float(e["x"]), float(e["y"])).distance_to(Vector2(2, 6)) < 1.6:
			llego = true
			break
	ok(not cruzo_muro, "el enemigo no atraviesa el muro")
	ok(llego, "el enemigo llega hasta el héroe por el hueco")
	print("FALLOS ", fallos)
	get_tree().quit()
