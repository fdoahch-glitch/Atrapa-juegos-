extends Node
func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.8).timeout
	a.get_child(0).crear_juego.emit({"modo":"2d","tipo":"plataformas"})
	await get_tree().create_timer(0.6).timeout
	var e = a.get_child(0)
	e._tut.terminar() if e.get("_tut") and e._tut.has_method("terminar") else null
	await get_tree().create_timer(0.3).timeout
	e._sorprender()
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/dino/barra2.png")
	e._abrir_exportar()
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/dino/barra3.png")
	get_tree().quit()
