extends Node
const Part := preload("res://scripts/partida.gd")
func _ready() -> void:
	for id in ["frontal", "defensa", "ritmo", "penales", "granja", "novela", "estrategia", "puzzle"]:
		var n := Datos.normalizar(Datos.nivel_mini(id))
		var j: Control = Part.clase_para(n).new()
		add_child(j)
		j.size = Vector2(960, 540)
		j.iniciar(n, false, false)
		for i in 150:
			j._actualizar(1.0 / 60.0)
		if id == "defensa":
			j.monedas = 200
			for c in [2, 4, 6]:
				j._al_pulsar(c)
		if id == "puzzle":
			j._al_pulsar(0)
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("/tmp/m_%s.png" % id)
		j.queue_free()
		await get_tree().process_frame
	get_tree().quit()
