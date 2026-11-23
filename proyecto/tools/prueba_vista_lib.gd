extends Node
func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.5).timeout
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(Datos.nivel_inicial())], "reglas": Datos.reglas_completas({"paleta": "desierto", "paleta_fuerza": 85})})
	a._abrir_editor()
	await get_tree().create_timer(0.8).timeout
	var ed = a.get_child(a.get_child_count() - 1)
	ed._tut.detener()
	ed._cambiar_tab("lib")
	ed._lib_cat = "Naturaleza"
	ed._construir_biblioteca()
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/asis/lib_nat.png")
	ed._lib_cat = "Ciudad"
	ed._construir_biblioteca()
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/asis/lib_ciu.png")
	print("listo")
	get_tree().quit(0)
