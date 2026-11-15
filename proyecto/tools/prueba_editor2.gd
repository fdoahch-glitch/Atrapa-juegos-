extends Node
func _ready() -> void:
	for k in ["plataformas", "corredor", "arriba"]:
		Datos.establecer(Datos.normalizar(Datos.convertir(Datos.nivel_inicial(), k)))
		var E = load("res://scripts/editor.gd").new()
		add_child(E)
		E.size = Vector2(1280, 720)
		await get_tree().process_frame
		E._abrir_tipos()
		await get_tree().process_frame
		E._abrir_reglas()
		await get_tree().process_frame
		print("editor ok ", k)
		if k == "corredor":
			get_viewport().get_texture().get_image().save_png("/tmp/dino/reglas.png")
		E.queue_free()
		await get_tree().process_frame
	get_tree().quit()
