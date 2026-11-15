extends Node
const Partida := preload("res://scripts/partida.gd")
func _ready() -> void:
	var p := Datos.proyecto_dinorun()
	p["reglas"] = Datos.reglas_completas(p["reglas"])
	var pa: Control = Partida.new()
	add_child(pa)
	pa.size = Vector2(1280, 720)
	pa.iniciar(p, 0, true, false, false)
	for f in 4: await get_tree().process_frame
	pa._mostrar_personajes()
	for f in 6: await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/dino/elegir.png")
	pa._mostrar_tienda()
	for f in 6: await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/dino/tienda2.png")
	get_tree().quit()
