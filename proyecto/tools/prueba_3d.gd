extends Node
# Prueba lógica del corredor 3D: sin jugar pierde vidas; con un "robot" llega a la meta.
const Juego3D := preload("res://scripts/juego3d.gd")
func _crear() -> Control:
	var j: Control = Juego3D.new()
	add_child(j)
	j.size = Vector2(1280, 720)
	j.iniciar(Datos.nivel_corredor(), false, false)
	return j
func _ready() -> void:
	var fallos := 0
	# 1) quieto: choca y pierde
	var a := _crear()
	for i in 3000:
		a._actualizar(1.0 / 60.0)
		if a.estado != "jugar":
			break
	print("quieto -> estado=", a.estado, " vidas=", a.vidas, " dist=", int(a.dist))
	if a.estado == "jugar":
		fallos += 1
	a.queue_free()
	# 2) robot: salta vallas, se agacha, esquiva paredes
	var b := _crear()
	for i in 6000:
		var sig: Variant = null
		for o in b.obst:
			if not o["golpeado"] and o["z"] > b.dist - 0.5 and (sig == null or o["z"] < sig["z"]):
				if o["lane"] == b.carril or true:
					sig = o if (o["lane"] == b.carril and o["z"] - b.dist < 12.0) else sig
		if sig != null:
			var d: float = sig["z"] - b.dist
			match sig["t"]:
				"valla":
					if d < 3.4 and b.py <= 0.01:
						b._saltar()
				"viga":
					if d < 3.4:
						b._agachar()
				"pared":
					if d < 8.0:
						# elegir carril libre
						var libre := [0, 1, 2].filter(func(l): return not b.obst.any(func(o): return o["lane"] == l and absf(o["z"] - sig["z"]) < 12.0 and o["t"] == "pared"))
						if libre.is_empty():
							libre = [1]
						if not libre.has(b.carril):
							b._cambiar_carril(1 if libre[0] > b.carril else -1)
		b._actualizar(1.0 / 60.0)
		if b.estado != "jugar":
			break
	print("robot -> estado=", b.estado, " vidas=", b.vidas, " monedas=", b.recogidos, "/", b.total, " dist=", int(b.dist))
	if b.estado != "gano":
		fallos += 1
	print("FALLOS: ", fallos)
	get_tree().quit(fallos)
