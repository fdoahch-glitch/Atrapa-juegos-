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
func _ready() -> void:
	await get_tree().process_frame
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(Datos.nivel_inicial())], "reglas": Datos.reglas_completas({})})
	var base := [{"t": "player", "x": 2, "y": 5, "id": "p"}, {"t": "plat", "x": 0, "y": 9, "w": 6, "h": 3, "id": "s"}, {"t": "plat", "x": 10, "y": 9, "w": 1, "h": 1, "id": "s2"}, {"t": "goal", "x": 38, "y": 8, "id": "g"}]
	var J = _nuevo(base, {})
	ok(J._terreno == null, "sin la opción no hay capa de terreno")
	J.queue_free()
	J = _nuevo(base, {"autotile": true})
	ok(J._terreno != null and J._terreno is TileMapLayer, "con la opción hay un TileMapLayer")
	var L: TileMapLayer = J._terreno
	ok(L.get_used_cells().size() == 19, "celdas cubiertas (%d)" % L.get_used_cells().size())
	var esq: Vector2i = L.get_cell_atlas_coords(Vector2i(0, 9))
	var cen: Vector2i = L.get_cell_atlas_coords(Vector2i(2, 10))
	var sola: Vector2i = L.get_cell_atlas_coords(Vector2i(10, 9))
	ok(esq != cen, "la esquina y el centro usan piezas distintas (%s / %s)" % [esq, cen])
	ok(sola == Vector2i(0, 0), "el bloque suelto no tiene vecinos (%s)" % sola)
	# la pieza del centro tiene los 4 vecinos → máscara 15
	ok(cen == Vector2i(3, 3), "el centro es la pieza con 4 vecinos (%s)" % cen)
	for i in 30: await get_tree().physics_frame
	for i in 120: J._actualizar(J.PASO)
	ok(J.suelo, "el héroe sigue pisando el suelo con el terreno")
	print("FALLOS ", fallos)
	get_tree().quit()
