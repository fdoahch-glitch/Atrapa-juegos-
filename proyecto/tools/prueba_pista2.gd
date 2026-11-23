extends Node3D
const J3 := preload("res://scripts/juego3d.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("  ok  " if c else "  MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	var n := Datos.nivel_corredor()
	n["pista"] = [{"d": [20, 40], "curva": 1.0, "subida": 0.0}, {"d": [50, 70], "curva": -1.0, "subida": 1.0}]
	n = Datos.normalizar(n)
	ok(n.has("pista") and n["pista"].size() == 2, "pista se conserva")
	var ctl := Control.new()
	ctl.size = Vector2(1280, 720)
	add_child(ctl)
	var j: Control = J3.new()
	ctl.add_child(j)
	j.size = Vector2(1280, 720)
	j.iniciar(n, false, false)
	ok(absf(j._xo(0.0)) < 0.01, "x=0 al inicio")
	ok(j._xo(j.fin_z * 0.45) > 10.0, "curva a la derecha (%.1f)" % j._xo(j.fin_z * 0.45))
	ok(j._yo(j.fin_z * 0.8) > 5.0, "subida (%.1f)" % j._yo(j.fin_z * 0.8))
	for i in 240:
		j._actualizar(1.0 / 60.0)
		j._sincronizar()
	ok(j.estado in ["jugar", "perdio", "gano"], "se juega con curvas (%s, dist %.0f)" % [j.estado, j.dist])
	var rec := Datos.normalizar(Datos.nivel_corredor())
	ok(not rec.has("pista"), "sin pista no hay clave")
	print("FALLOS ", fallos)
	get_tree().quit()
