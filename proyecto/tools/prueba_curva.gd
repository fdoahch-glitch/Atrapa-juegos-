extends Node
const Paquete := preload("res://scripts/paquete.gd")
const Juego3D := preload("res://scripts/juego3d.gd")
func _ready() -> void:
	var r: Dictionary = Paquete.abrir_proyecto("/home/claude/dino-run-motor-/dino-run.atrapa.json")
	print("abrir ", r.get("ok"), " assets ", r.get("assets"))
	for k in [1]:
		var n: Dictionary = Datos.niveles[k].duplicate(true)
		n["reglas"] = Datos.reglas
		n["pista"] = [{"d": [8, 25], "curva": 1.0, "subida": 0.0}, {"d": [25, 40], "curva": -1.0, "subida": 1.0}]
		var j: Control = Juego3D.new()
		add_child(j)
		j.size = Vector2(1280, 720)
		j.iniciar(n, false, false)
		for i in 420:
			j._actualizar(1.0 / 60.0)
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("/tmp/curva_%d.png" % k)
		j.queue_free()
		await get_tree().process_frame
	get_tree().quit()
