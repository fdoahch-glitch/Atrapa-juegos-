extends Node
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _clic(b: Button) -> void:
	b.pressed.emit()
	await get_tree().create_timer(0.35).timeout
func _botones(n: Node, r: Array) -> Array:
	for c in n.get_children():
		if c is Button: r.append(c)
		_botones(c, r)
	return r
func _snap(nombre: String) -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/asis")
	get_viewport().get_texture().get_image().save_png("/tmp/asis/%s.png" % nombre)
func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.8).timeout
	_snap("1_portada")
	var ini = a.get_child(0)
	var bs := _botones(ini, [])
	await _clic(bs[0]); _snap("2_plataforma")
	bs = _botones(ini, [])
	# Android = tercera tarjeta
	await _clic(bs[2]); _snap("3_orientacion")
	bs = _botones(ini, [])
	await _clic(bs[0]); _snap("4_categoria")      # vertical
	bs = _botones(ini, [])
	await _clic(bs[0]); _snap("5_tipos")          # carreras
	bs = _botones(ini, [])
	await _clic(bs[0])                              # corredor infinito
	await get_tree().create_timer(0.8).timeout
	ok(Datos.nivel["modo"] == "3d" and Datos.nivel["tipo"] == "corredor", "carreras de corredor crea un juego 3D corredor")
	ok(Datos.nivel["disp"] == "movil" and Datos.nivel["orient"] == "vertical", "Android vertical queda configurado")
	ok(Datos.reglas["plataforma"] == "android" and Datos.reglas["categoria"] == "carreras", "recuerda plataforma y categoría")
	ok(Datos.reglas["portada"]["botones"].size() == 1, "nace con portada y botón Jugar")
	_snap("6_editor")
	print("FALLOS: ", fallos)
	get_tree().quit()
