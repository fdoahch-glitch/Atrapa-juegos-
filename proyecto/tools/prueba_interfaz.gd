extends Node
func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.5).timeout
	var n := Datos.normalizar(Datos.nivel_corredor())
	n["pista"] = [{"d": [20, 40], "curva": 0.8, "subida": 0.0}]
	Datos.establecer_proyecto({"niveles": [n], "reglas": Datos.reglas_completas({"categoria": "carreras"})})
	a._abrir_editor()
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/ui_editor.png")
	var e = a.get_child(a.get_child_count() - 1)
	e._abrir_guia()
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/ui_guia.png")
	e._cerrar_modal()
	var m := Datos.normalizar(Datos.nivel_mini("ritmo"))
	Datos.establecer_proyecto({"niveles": [m], "reglas": Datos.reglas_completas({"categoria": "otros"})})
	a._abrir_editor()
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/ui_mini.png")
	get_tree().quit()
