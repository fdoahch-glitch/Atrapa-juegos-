extends Node3D
func _ready() -> void:
	var dir := DirAccess.open("/tmp/ex/out")
	var files: Array = []
	for f in dir.get_files():
		if f.ends_with(".glb"): files.append(f)
	files.sort()
	var cols := 9
	var w := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.7, 0.85, 0.95); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color.WHITE; e.ambient_light_energy = 0.7; w.environment = e; add_child(w)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, -30, 0); add_child(sun)
	for i in files.size():
		var doc := GLTFDocument.new(); var st := GLTFState.new()
		if doc.append_from_file("/tmp/ex/out/" + files[i], st) != OK:
			print("ERR ", files[i]); continue
		var n: Node3D = doc.generate_scene(st)
		var ab := AABB(); var first := true
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var bb: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
			ab = bb if first else ab.merge(bb); first = false
		var k := 2.0 / maxf(ab.size.x, maxf(ab.size.y, ab.size.z))
		n.scale = Vector3.ONE * k
		n.position = Vector3((i % cols) * 2.6, 0, -(i / cols) * 2.6) - ab.get_center() * k + Vector3(0, ab.size.y * k / 2.0, 0)
		add_child(n)
		print(files[i], " ", ab.size)
	var cam := Camera3D.new(); cam.position = Vector3(11.5, 9, 7); add_child(cam); cam.look_at(Vector3(11.5, 0.5, -5.5)); cam.fov = 60
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/vista.png")
	get_tree().quit()
