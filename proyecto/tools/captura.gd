extends Node
# Captura pantallas reales (necesita un display, p. ej. xvfb-run) para revisar el aspecto.
func _guardar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/cap_%s.png" % nombre)
	print("captura ", nombre)

func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(1.6).timeout
	var ed = a.get_child(0)
	await _guardar("1_tutorial")
	ed._tut.detener()
	await get_tree().process_frame
	await _guardar("2_personajes")
	ed._cambiar_tab("fondos"); Datos.nivel["theme"] = "noche"; Datos.confirmar()
	await get_tree().create_timer(0.4).timeout
	await _guardar("3_fondos_noche")
	ed._cambiar_tab("objetos")
	ed._esc.stamp = {"id": "coin", "n": "Moneda", "t": "coin"}
	ed._refrescar_chip()
	ed._esc.sel = Datos.nivel["items"][2]
	await get_tree().create_timer(0.3).timeout
	await _guardar("4_objetos")
	ed._esc.stamp = {}; ed._refrescar_chip()
	ed._esc.sel = Datos.nivel["items"][2]; ed._refrescar_props()
	Datos.nivel["theme"] = "dia"; Datos.confirmar()
	await get_tree().create_timer(0.3).timeout
	await _guardar("5_seleccion")
	ed._jugar()
	var j = ed._jugando.get_child(0)
	j.dedos = {0: "der"}
	for i in 140:
		if i % 45 == 0: j.salto_pulsado = true
		await get_tree().process_frame
	await _guardar("6_jugando")
	ed._cerrar_juego()
	ed._abrir_exportar()
	await get_tree().create_timer(0.3).timeout
	await _guardar("7_exportar")
	get_tree().quit(0)
