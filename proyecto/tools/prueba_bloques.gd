extends Node
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	await get_tree().process_frame
	var n: Dictionary = Datos.normalizar(Datos.nivel_inicial())
	n["items"] = [{"t": "player", "x": 2, "y": 8, "id": "a"}, {"t": "plat", "x": 5, "y": 8, "w": 3, "h": 1, "id": "b"}, {"t": "coin", "x": 6, "y": 7, "id": "c"}, {"t": "enemy", "x": 7, "y": 7, "e": "🦊", "r": 2, "sp": 60, "id": "d"}, {"t": "goal", "x": 28, "y": 8, "id": "g"}]
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(n)], "reglas": Datos.reglas_completas({})})
	var Ed = load("res://scripts/editor.gd")
	var e = Ed.new()
	add_child(e)
	e.size = Vector2(1280, 720)
	await get_tree().process_frame
	var sel: Dictionary = {}
	for it in Datos.nivel["items"]:
		if it["t"] == "plat": sel = it
	e._guardar_bloque(sel)
	var pf: Array = Datos.reglas["prefabs"]
	ok(pf.size() == 1 and pf[0]["items"].size() == 3, "se guardó un bloque con 3 objetos (%d)" % pf[0]["items"].size())
	ok(pf[0]["items"][0]["x"] >= 0 and not pf[0]["items"][0].has("id"), "posiciones relativas, sin ids")
	var antes: int = Datos.nivel["items"].size()
	var def := {"id": "pf0", "n": "Bloque 1", "t": "prefab", "items": pf[0]["items"]}
	Datos.colocar(def, 15, 5)
	ok(Datos.nivel["items"].size() == antes + 3, "al colocarlo aparecen 3 objetos nuevos")
	var ids := {}
	for it in Datos.nivel["items"]: ids[it["id"]] = true
	ok(ids.size() == Datos.nivel["items"].size(), "todos con id distinto")
	var lista: Array = e._lista_biblioteca() if e.has_method("_lista_biblioteca") else []
	e._construir_biblioteca()
	await get_tree().process_frame
	var r2 := Datos.reglas_completas({"prefabs": pf})
	ok(r2["prefabs"].size() == 1, "los bloques se conservan en las reglas del juego")
	print("FALLOS ", fallos)
	get_tree().quit()
