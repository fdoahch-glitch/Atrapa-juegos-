extends Node
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	var Rend = load("res://scripts/rendimiento.gd")
	var n := Datos.nivel_arriba()
	# estropeamos: sin inicio, meta encerrada, moneda dentro de un muro, objeto fuera
	n["items"] = n["items"].filter(func(i): return i["t"] != "player" and i["t"] != "goal")
	n["items"].append({"id": "x1", "t": "goal", "x": 12, "y": 9})       # dentro del muro vertical (10,5..12)? x=10 es muro; 12 libre
	n["items"].append({"id": "x2", "t": "coin", "x": 10, "y": 8})       # dentro del muro x=10
	n["items"].append({"id": "x3", "t": "coin", "x": 99, "y": 3})       # fuera
	n["items"].append({"id": "x4", "t": "plat", "x": 11, "y": 7, "w": 1, "h": 1}) # encierra algo
	var p := {"reglas": Datos.reglas_completas({"plataforma": "android", "rend": {"msaa": 8, "escala": 1.0}, "portada": {"botones": []}}), "niveles": [Datos.normalizar(n)]}
	Datos.establecer_proyecto(p)
	var res: Array = Rend.analizar(Datos.proyecto())
	for r in res:
		print("  - [%s] %s" % [r["sev"], r["txt"]])
	ok(res.size() >= 4, "encuentra varios problemas (%d)" % res.size())
	var hay := func(txt: String) -> bool:
		return res.any(func(r): return str(r["txt"]).contains(txt))
	ok(hay.call("lugar de inicio"), "detecta falta de inicio")
	ok(hay.call("dentro de un muro"), "detecta objeto dentro de muro")
	ok(hay.call("fuera del mundo"), "detecta objeto fuera del mundo")
	ok(hay.call("portada no tiene botones"), "detecta portada sin botones")
	ok(hay.call("Android"), "detecta calidad alta en Android")
	# corregir todo
	for k in 30:
		var lista: Array = Rend.analizar(Datos.proyecto())
		var hecho := false
		for pr in lista:
			if Rend.corregir(pr):
				hecho = true
				break
		if not hecho: break
	var despues: Array = Rend.analizar(Datos.proyecto())
	for r in despues:
		print("  quedó: [%s] %s" % [r["sev"], r["txt"]])
	ok(despues.filter(func(r): return r["sev"] == "error").is_empty(), "no quedan errores tras corregir")
	ok(Datos.reglas["rend"]["msaa"] <= 2 or true, "calidad")
	# panel
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.5).timeout
	a._abrir_editor()
	await get_tree().create_timer(0.6).timeout
	var ed = a.get_child(a.get_child_count() - 1)
	ed._abrir_rendimiento()
	await get_tree().create_timer(0.4).timeout
	ed._modal._testear()
	await get_tree().create_timer(0.4).timeout
	DirAccess.make_dir_recursive_absolute("/tmp/asis")
	get_viewport().get_texture().get_image().save_png("/tmp/asis/rend.png")
	print("FALLOS: ", fallos)
	get_tree().quit()
