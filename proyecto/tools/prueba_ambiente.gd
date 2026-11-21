extends Node
const Juego3D := preload("res://scripts/juego3d.gd")
const Progreso := preload("res://scripts/progreso.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("OK   " if c else "FALLA ") + m)
	if not c: fallos += 1
func _crear(extra: Dictionary, reglas: Dictionary = {}) -> Control:
	var n := Datos.nivel_corredor()
	n.merge(extra, true)
	n["reglas"] = Datos.reglas_completas(reglas)
	var j: Control = Juego3D.new()
	add_child(j)
	j.size = Vector2(1280, 720)
	j.iniciar(n, false, false)
	return j
func _ready() -> void:
	DirAccess.remove_absolute("user://progreso.json")
	for cl in ["lluvia", "tormenta", "nieve", "ventisca", "erupcion", "variable"]:
		var j := _crear({"clima": cl, "hora": "ciclo", "perseguidor": true})
		for i in 600:
			j._actualizar(1.0 / 60.0)
		ok(j._amb._part != null or cl == "variable", "clima " + cl)
		j.queue_free()
	var a := _crear({"perseguidor": true, "hora": "noche"})
	ok(a._amb._factor_noche() == 1.0, "noche")
	a.inv = 0.0
	a._herir(); a.inv = 0.0
	ok(a._amb.acercamiento > 0.3, "perseguidor se acerca")
	a.inv = 0.0; a._herir(); a.inv = 0.0; a._herir()
	ok(a.estado == "perdio", "perseguidor atrapa")
	a.revivir()
	ok(a.estado == "jugar" and a.vidas == 1, "revivir")
	a.queue_free()
	var f := _crear({}, {"dificultad": "facil"})
	var d := _crear({}, {"dificultad": "extrema"})
	ok(f.vidas > d.vidas and f._vel_k < d._vel_k, "dificultad cambia vidas y velocidad")
	var s := _crear({"clima": "nieve", "hora": "atardecer", "perseguidor": true}, {"skins": [{"id": "r", "n": "R", "color": "#ff0000", "precio": 0}], "rend": {"bloom": true, "sombras": true}})
	for i in 20:
		s._actualizar(1.0 / 60.0)
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/amb_nieve.png")
	print("FALLOS ", fallos)
	get_tree().quit(fallos)
