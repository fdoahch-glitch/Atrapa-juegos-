extends Node
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _jugar(n: Dictionary, nombre: String, seg: float) -> Control:
	var P = load("res://scripts/partida.gd")
	var cl = P.clase_para(n)
	var j: Control = cl.new()
	add_child(j)
	j.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	j.iniciar(n, false, false)
	return j
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/asis")
	var P = load("res://scripts/partida.gd")
	for k in [false, true]:
		var n := Datos.normalizar(Datos.nivel_carrera(k))
		ok(n.get("estilo") == ("kart" if k else "carrera") and n["tipo"] == "arriba", "normalizar conserva estilo")
		var j := _jugar(n, "", 0)
		await get_tree().create_timer(0.5).timeout
		ok(j.rivales.size() == 3, "3 rivales")
		ok(not j._campo_cp.is_empty() and not j._campo_meta.is_empty(), "campos de ruta calculados")
		ok(j._lin_meta.size() >= 5 and j._lin_cp.size() >= 3, "líneas de meta y control (%d, %d)" % [j._lin_meta.size(), j._lin_cp.size()])
		# acelera durante unos segundos con las flechas simuladas
		await get_tree().create_timer(4.0).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/asis/carrera_%s.png" % ("kart" if k else "pista"))
		# acelerar más rápido: simular el tiempo del juego
		for i in 12000:
			j._actualizar(1.0 / 120.0)
			if j.estado != "jugar": break
		ok(j.rivales[0]["lap"] >= 1 or j.rivales[0]["hecho"], "los rivales completan vueltas (lap %d)" % j.rivales[0]["lap"])
		ok(j.estado != "jugar" or j._tras_ganador > 0.0, "la carrera termina o avisa (estado %s)" % j.estado)
		j.queue_free()
	# pelea
	var np := Datos.normalizar(Datos.nivel_pelea())
	ok(P.clase_para(np) == load("res://scripts/juego_pelea.gd"), "pelea usa el motor de lucha")
	var jp := _jugar(np, "", 0)
	await get_tree().create_timer(2.8).timeout
	jp._atacar(jp.yo, "puno")
	jp.rival["x"] = jp.yo["x"] + 40.0
	for i in 60: jp._actualizar(1.0 / 60.0)
	ok(jp.rival["hp"] < 100.0 or jp.yo["hp"] < 100.0, "los golpes quitan vida (%.0f / %.0f)" % [jp.yo["hp"], jp.rival["hp"]])
	get_viewport().get_texture().get_image().save_png("/tmp/asis/pelea.png")
	for i in 60 * 130:
		jp._actualizar(1.0 / 60.0)
		if jp.estado != "jugar": break
	ok(jp.estado != "jugar", "el combate termina (%s)" % jp.estado)
	print("FALLOS: ", fallos)
	get_tree().quit()
