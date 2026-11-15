extends Node
func _guardar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/c3_%s.png" % nombre)
func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout
func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await _esperar(1.0)
	var ini = a.get_child(0)
	ini._mostrar_config(ini.MODOS[0])
	await _esperar(0.5)
	await _guardar("1_asistente2d")
	ini.crear.emit("2d", {"disp": "movil", "orient": "vertical", "tipo": "arriba"})
	await _esperar(1.0)
	var ed = a.get_child(0)
	ed._tut.detener()
	ed._cambiar_tab("objetos")
	await _esperar(0.5)
	await _guardar("2_editor_arriba")
	ed._jugar()
	await _esperar(0.6)
	var pa = ed._jugando.get_child(0).get_child(0)
	pa._empezar(0)
	await _esperar(0.8)
	await _guardar("3_jugando_vertical")
	get_tree().quit(0)
