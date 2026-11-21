extends Node
func _ready() -> void:
	var E = load("res://scripts/editor_html.gd")
	var f := FileAccess.open("user://t.html", FileAccess.WRITE)
	f.store_string(E.PAGINA); f.close()
	print("PAGINA bytes: ", E.PAGINA.length(), " contiene función: ", E.PAGINA.contains("function limpio"), " barra-n ok: ", E.PAGINA.contains("'\\n'"))
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.8).timeout
	DirAccess.make_dir_recursive_absolute("/tmp/asis")
	get_viewport().get_texture().get_image().save_png("/tmp/asis/portada2.png")
	get_tree().quit()
