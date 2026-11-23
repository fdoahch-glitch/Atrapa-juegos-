extends Node
const JP := preload("res://scripts/juego_pelea.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	await get_tree().process_frame
	var j: Control = JP.new()
	add_child(j)
	j.size = Vector2(1280, 720)
	var n: Dictionary = Datos.normalizar(Datos.nivel_pelea())
	n["reglas"] = Datos.reglas_completas({})
	j.iniciar(n, false, false)
	for i in 30: await get_tree().physics_frame
	ok(j._pw_ok, "mundo físico de la pelea activo")
	j._estado = "pelea"
	for i in 120:
		j._mover_f(j.yo, 1.0 / 120.0, 0.0, false, false)
	ok(absf(float(j.yo["y"]) - j.suelo_y) < 0.2 and j.yo["suelo"], "el luchador está sobre el escenario (%.2f vs %.2f)" % [j.yo["y"], j.suelo_y])
	var ymin := 1e9
	j._mover_f(j.yo, 1.0 / 120.0, 0.0, true, false)
	for i in 300:
		j._mover_f(j.yo, 1.0 / 120.0, 0.0, false, false)
		ymin = minf(ymin, float(j.yo["y"]))
	ok(j.suelo_y - ymin > 60.0 and j.yo["suelo"], "salta %.0f px y vuelve a caer" % (j.suelo_y - ymin))
	var x0: float = j.yo["x"]
	for i in 120:
		j._mover_f(j.yo, 1.0 / 120.0, 1.0, false, false)
	ok(float(j.yo["x"]) > x0 + 100.0, "camina por el escenario")
	print("FALLOS ", fallos)
	get_tree().quit()
