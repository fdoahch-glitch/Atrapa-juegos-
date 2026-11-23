extends Node
func _snap(nombre: String) -> void:
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/p3_%s.png" % nombre)
func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.5).timeout
	var n := Datos.normalizar(Datos.nivel_trio())
	n["items"][-2]["anim"] = "flotar"
	Datos.establecer_proyecto({"niveles": [n], "reglas": Datos.reglas_completas({"categoria": "plataformas"})})
	a._abrir_editor()
	await get_tree().create_timer(1.0).timeout
	var e = a.get_child(a.get_child_count() - 1)
	for it in Datos.nivel["items"]:
		if it["t"] == "enemy":
			e._esc.sel = it
			break
	e._refrescar_props()
	await _snap("editor")
	e._abrir_juego("mecanicas")
	await _snap("mec")
	e._abrir_juego("fisica")
	await _snap("fis")
	e._abrir_creador()
	e._modal._acc = "👑"
	e._modal._tinte = Color("70d6ff")
	e._modal._pintar()
	await _snap("creador")
	var c := Datos.normalizar(Datos.nivel_corredor())
	c["pista"] = [{"d": [20, 40], "curva": 0.8, "subida": 0.5}, {"d": [55, 75], "curva": -0.9, "subida": -1.0}]
	Datos.establecer_proyecto({"niveles": [c], "reglas": Datos.reglas_completas({"categoria": "carreras"})})
	a._abrir_editor()
	await get_tree().create_timer(0.8).timeout
	e = a.get_child(a.get_child_count() - 1)
	e._abrir_pista()
	await _snap("pista")
	get_tree().quit()
