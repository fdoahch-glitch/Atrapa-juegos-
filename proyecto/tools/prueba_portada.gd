extends Node
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(Datos.nivel_inicial())], "reglas": Datos.reglas_completas({"portada": Datos.portada_nueva("Prueba")})})
	var Ed = load("res://scripts/editor.gd").new()
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.5).timeout
	a._abrir_editor()
	await get_tree().create_timer(0.8).timeout
	var ed = a.get_child(a.get_child_count() - 1)
	ed._set_etapa("portada")
	await get_tree().create_timer(0.4).timeout
	var pe = ed._port
	pe._botones().append({"txt": "Tienda", "img": "", "x": 0.5, "y": 0.8, "w": 0.3, "h": 0.1, "anim": "flotar", "accion": "tienda"})
	pe._p()["titulo"] = "Mi gran juego"
	pe.sel = 1
	pe._sub_anim.id_pressed.emit(5)
	pe._sub_acc.id_pressed.emit(2)
	ok(pe._botones()[1]["anim"] == "brillar" and pe._botones()[1]["accion"] == "personajes", "menú Animación/Acción cambia el botón")
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/asis/portada_ed.png")
	# convertir imagen
	var im := Image.create(64, 64, false, Image.FORMAT_RGBA8); im.fill(Color.RED); im.save_png("/tmp/t.png")
	var id: String = pe.convertir_e_importar("/tmp/t.png", "webp")
	ok(id.begins_with("u:"), "convierte e importa imagen (" + id + ")")
	var norm := Datos.portada_normal(pe._p())
	ok(norm["botones"].size() == 2 and norm["titulo"] == "Mi gran juego", "portada se normaliza")
	ed._set_etapa("mundo")
	ok(ed._esc.visible and not pe.visible, "volver a mundo")
	print("FALLOS: ", fallos)
	get_tree().quit()
