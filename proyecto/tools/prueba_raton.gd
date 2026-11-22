extends Node
func _botones(n: Node, r: Array) -> Array:
	for c in n.get_children():
		if c is Button and c.is_visible_in_tree(): r.append(c)
		_botones(c, r)
	return r
func _clic_real(b: Button) -> void:
	var p: Vector2 = b.get_global_rect().get_center()
	var e := InputEventMouseMotion.new(); e.position = p; e.global_position = p
	get_viewport().push_input(e)
	await get_tree().process_frame
	for down in [true, false]:
		var m := InputEventMouseButton.new(); m.button_index = MOUSE_BUTTON_LEFT; m.pressed = down; m.position = p; m.global_position = p
		Input.parse_input_event(m)
		await get_tree().process_frame
		await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.8).timeout
	var ini = a.get_child(0)
	var pasos := ["portada", "plataforma", "orientacion", "categoria", "tipos"]
	ini = a.get_child(0)
	for i in pasos.size():
		ini = a.get_child(0)
		var bs := _botones(ini, [])
		print(pasos[i], " botones: ", bs.map(func(b): return b.text.strip_edges()))
		await _clic_real(bs[0] if i != 1 else bs[0])
		get_viewport().get_texture().get_image().save_png("/tmp/raton_%d.png" % i)
	await get_tree().create_timer(0.8).timeout
	print("nivel modo=", Datos.nivel.get("modo"), " tipo=", Datos.nivel.get("tipo"))
	get_tree().quit()
