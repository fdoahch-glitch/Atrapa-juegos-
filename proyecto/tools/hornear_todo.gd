extends Node
# Fabrica los dibujos 2D de todos los modelos genéricos (assets/modelos2d/*.png).
# Ejecutar con pantalla (xvfb-run) y: godot --rendering-driver opengl3 --path . res://tools/hornear_todo.tscn
const Assets3D := preload("res://scripts/assets3d.gd")
const Hornear := preload("res://scripts/hornear.gd")
func _ready() -> void:
	var n := 0
	for id in Assets3D.todos_los_ids():
		var es_pers := false
		var es_enemigo := false
		for p in Assets3D.PERSONAJES:
			es_pers = es_pers or p[0] == id
		for mm in Assets3D.MASCOTAS:
			es_pers = es_pers or mm[0] == id
		for e in Assets3D.ENEMIGOS:
			es_enemigo = es_enemigo or e[0] == id
		var yaw := 55.0 if es_pers else (-55.0 if es_enemigo else 22.0)
		var m := Assets3D.construir(id)
		var img: Image = await Hornear.foto(get_tree(), m, 384, yaw)
		var spr := Hornear.a_sprite(img, 128)
		spr.save_png("res://assets/modelos2d/%s.png" % id)
		n += 1
	print("modelos horneados: ", n)
	get_tree().quit(0)
