extends Node
func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.5).timeout
	var n := Datos.normalizar(Datos.nivel_corredor())
	Datos.establecer_proyecto({"niveles": [n], "reglas": Datos.reglas_completas({"categoria": "carreras"})})
	a._abrir_editor()
	await get_tree().create_timer(1.0).timeout
	var e = a.get_child(a.get_child_count() - 1)
	e._agregar_nivel(false)
	await get_tree().create_timer(0.6).timeout
	print("NIVELES ", Datos.num_niveles(), " idx ", Datos.idx)
	get_viewport().get_texture().get_image().save_png("/tmp/lienzo.png")
	# arrastrar: simula soltar una moneda en el carril izquierdo cerca de la salida
	var esc = e._esc
	print("VERT ", esc.vert, " Z ", esc.Z)
	var antes: int = Datos.nivel["items"].size()
	esc.soltar({"t": "coin"}, esc.origen + Vector2(4.5, esc._dims().y - 3.5) * esc.Z)
	print("ITEMS ", antes, " -> ", Datos.nivel["items"].size(), " ultimo ", Datos.nivel["items"][-1])
	e._abrir_reglas()
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/reglas.png")
	get_tree().quit()
