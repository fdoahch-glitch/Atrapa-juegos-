extends Node
func _botones(n: Node, r: Array) -> Array:
	for c in n.get_children():
		if c is Button and c.is_visible_in_tree(): r.append(c)
		_botones(c, r)
	return r
func _clic(b: Button) -> void:
	var p: Vector2 = b.get_global_rect().get_center()
	var e := InputEventMouseMotion.new(); e.position = p; e.global_position = p
	get_viewport().push_input(e)
	await get_tree().process_frame
	for down in [true, false]:
		var m := InputEventMouseButton.new(); m.button_index = MOUSE_BUTTON_LEFT; m.pressed = down; m.position = p; m.global_position = p
		Input.parse_input_event(m)
		await get_tree().process_frame
		await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.8).timeout
	var ini = a.get_child(0)
	var bs := _botones(ini, [])
	for b in bs:
		if "Abrir un juego guardado" in b.text:
			await _clic(b); break
	get_viewport().get_texture().get_image().save_png("/tmp/guardados.png")
	bs = _botones(ini, [])
	print(bs.map(func(b): return b.text.strip_edges()))
	for b in bs:
		if "ino" in b.text or "5 mundos" in b.text:
			await _clic(b); break
	await get_tree().create_timer(1.5).timeout
	print("niveles=", Datos.niveles.size(), " primero=", Datos.niveles[0]["name"] if Datos.niveles.size() > 0 else "")
	get_viewport().get_texture().get_image().save_png("/tmp/guardados2.png")
	get_tree().quit()
