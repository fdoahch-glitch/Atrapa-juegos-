extends Node
# Capturas: asistente, editor de la Aventura 3D, biblioteca y «Mis cosas».
func _guardar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/c2_%s.png" % nombre)
func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout
func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await _esperar(1.0)
	var ini = a.get_child(0)
	ini._mostrar_config(ini.MODOS[2])
	await _esperar(0.6)
	await _guardar("1_asistente")
	ini.crear.emit("3d", {"disp": "movil", "orient": "vertical", "tipo": "aventura"})
	await _esperar(1.0)
	var ed = a.get_child(0)
	ed._tut.detener()
	await _esperar(0.4)
	await _guardar("2_editor_aventura")
	ed._cambiar_tab("pers")
	await _esperar(0.4)
	await _guardar("3_personajes")
	ed._cambiar_tab("deco")
	await _esperar(0.4)
	await _guardar("4_deco")
	ed._cambiar_tab("mis")
	await _esperar(0.4)
	await _guardar("5_miscosas_vacio")
	await ed._incorporar("/tmp/glb/cubo rosa.glb")
	ed._cambiar_tab("mis")
	await _esperar(0.5)
	await _guardar("6_miscosas_con_glb")
	ed._jugar()
	for i in 90:
		await get_tree().process_frame
	await _guardar("7_jugando_vertical")
	get_tree().quit(0)
