extends Node
const J3 := preload("res://scripts/juego3d.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	await get_tree().process_frame
	var j: Control = J3.new()
	add_child(j)
	j.size = Vector2(1280, 720)
	j.iniciar(Datos.nivel_corredor(), false, false)
	for i in 30: await get_tree().physics_frame
	ok(j._p3_ok and j.obst.size() > 0 and j.obst[0].get("area") != null, "mundo 3D del corredor con %d zonas de obstáculo" % j.obst.size())
	# salto: sube y vuelve al suelo con la física real
	j.vy = 9.0
	j.py = 0.01
	var ymax := 0.0
	for i in 240:
		j._actualizar(1.0 / 120.0)
		ymax = maxf(ymax, j.py)
	ok(ymax > 1.0 and j.py < 0.02, "salto y aterrizaje reales (máx %.2f m, final %.2f)" % [ymax, j.py])
	# choque contra obstáculo detectado por Area3D
	var o: Dictionary = j.obst[0]
	j.dist = float(o["z"]) - 0.05
	j.carril = int(o["lane"])
	j.px = (o["lane"] - 1) * 2.2
	j.py = 0.0
	var v0: int = j.vidas
	j.inv = 0.0
	for i in 4:
		await get_tree().physics_frame
		j.dist = float(o["z"]) - 0.05
		j._actualizar(1.0 / 120.0)
	ok(j.vidas < v0 or j._escudos < 3, "el obstáculo golpea (vidas %d→%d)" % [v0, j.vidas])
	print("FALLOS ", fallos)
	get_tree().quit()
