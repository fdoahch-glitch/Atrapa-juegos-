extends Node
const Part := preload("res://scripts/partida.gd")
const Minis := preload("res://scripts/minis.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("  ok  " if c else "  MAL ") + m)
	if not c: fallos += 1
func _crear(n: Dictionary) -> Control:
	var j: Control = Part.clase_para(n).new()
	add_child(j)
	j.size = Vector2(1280, 720)
	j.iniciar(n, false, false)
	return j
func _marcos(j, k: int) -> void:
	for i in k:
		await get_tree().process_frame
func _ready() -> void:
	DirAccess.remove_absolute("user://progreso.json")
	# 1) cada minijuego se crea, se normaliza y dibuja sin errores
	for id in Minis.MINIS.keys():
		var n := Datos.normalizar(Datos.nivel_mini(id))
		ok(str(n.get("estilo", "")) == "mini" and n["mini"] == id and n["mini_cfg"].size() > 0, "normaliza %s" % id)
		var j := _crear(n)
		await _marcos(j, 4)
		for i in 30:
			j._actualizar(1.0 / 60.0)
		await _marcos(j, 2)
		ok(j._zonas.size() >= 0 and j.estado in ["jugar", "gano", "perdio"], "%s corre (%s, zonas %d)" % [id, j.estado, j._zonas.size()])
		j.queue_free()
	# 2) parejas: resolver
	var jp := _crear(Datos.normalizar(Datos.nivel_mini("puzzle")))
	await _marcos(jp, 3)
	var por: Dictionary = {}
	for i in jp.cartas.size():
		por[jp.cartas[i]["e"]] = por.get(jp.cartas[i]["e"], []) + [i]
	for e in por:
		jp._al_pulsar(por[e][0])
		jp._al_pulsar(por[e][1])
	ok(jp.estado == "gano", "parejas: se gana al emparejar todo")
	# 3) ritmo: acertar todas
	var jr := _crear(Datos.normalizar(Datos.nivel_mini("ritmo")))
	await _marcos(jr, 3)
	var ult := 0.0
	for n in jr.notas:
		ult = maxf(ult, n["t"])
	while jr.t < ult + 0.5 and jr.estado == "jugar":
		for n in jr.notas:
			if not n["hecha"] and absf(n["t"] - jr.t) < 0.02:
				jr._golpear(n["c"])
		jr._actualizar(1.0 / 60.0)
	ok(jr.estado == "gano" and jr.aciertos == jr.notas.size(), "ritmo: %d aciertos, estado %s" % [jr.aciertos, jr.estado])
	# 4) ritmo sin tocar: pierde
	var jr2 := _crear(Datos.normalizar(Datos.nivel_mini("ritmo")))
	for i in 1500:
		jr2._actualizar(1.0 / 60.0)
	ok(jr2.estado == "perdio", "ritmo: sin tocar se pierde")
	# 5) defensa: poner torres y ganar
	var jd := _crear(Datos.normalizar(Datos.nivel_mini("defensa")))
	await _marcos(jd, 3)
	jd.monedas = 999
	for c in [3, 4, 5, 6]:
		jd._al_pulsar(c + 1 * 9)
		jd._al_pulsar(c + 3 * 9)
	ok(jd.torres.size() == 8, "defensa: 8 torres")
	for i in 60 * 120:
		jd._actualizar(1.0 / 60.0)
		if jd.estado != "jugar":
			break
	ok(jd.estado == "gano", "defensa: con torres se ganan las oleadas (%s)" % jd.estado)
	# 6) defensa sin torres: pierde
	var jd2 := _crear(Datos.normalizar(Datos.nivel_mini("defensa")))
	for i in 60 * 120:
		jd2._actualizar(1.0 / 60.0)
		if jd2.estado != "jugar":
			break
	ok(jd2.estado == "perdio", "defensa: sin torres se pierde")
	# 7) penales: tirar
	var jn := _crear(Datos.normalizar(Datos.nivel_mini("penales")))
	await _marcos(jn, 2)
	for k in 5:
		jn._al_suelo(Vector2(300 + k * 150, 200))
		for i in 150:
			jn._actualizar(1.0 / 60.0)
	ok(jn.tiros_hechos == 5, "penales: 5 tiros (%d, goles %d)" % [jn.tiros_hechos, jn.goles])
	ok(jn.estado in ["gano", "perdio"], "penales termina (%s)" % jn.estado)
	# 8) granja
	var jg := _crear(Datos.normalizar(Datos.nivel_mini("granja")))
	await _marcos(jg, 2)
	jg._al_pulsar(0)
	ok(jg.parcelas[0]["c"] == 0 and jg.monedas == 8, "granja: siembra")
	for i in 60 * 10:
		jg._actualizar(1.0 / 60.0)
	jg._al_pulsar(0)
	ok(jg.monedas == 14, "granja: cosecha (%d)" % jg.monedas)
	# 9) novela
	var jv := _crear(Datos.normalizar(Datos.nivel_mini("novela")))
	await _marcos(jv, 2)
	jv._al_pulsar("mapa")
	jv._al_pulsar("cueva")
	ok(jv.actual == "cueva", "novela: avanza de escena")
	jv._al_pulsar("gana")
	ok(jv.estado == "gano", "novela: final feliz")
	# 10) quiz
	var jq := _crear(Datos.normalizar(Datos.nivel_mini("educativo")))
	await _marcos(jq, 2)
	for q in jq.preguntas.duplicate():
		jq._al_pulsar(q["ok"])
		for i in 90:
			jq._actualizar(1.0 / 60.0)
	ok(jq.estado == "gano", "quiz: todo correcto gana (%s)" % jq.estado)
	var jq2 := _crear(Datos.normalizar(Datos.nivel_mini("educativo")))
	for k in 5:
		jq2._al_pulsar((jq2.preguntas[jq2.i_preg]["ok"] + 1) % 3 if jq2.i_preg < jq2.preguntas.size() else 0)
		for i in 90:
			jq2._actualizar(1.0 / 60.0)
	ok(jq2.estado == "perdio", "quiz: errores pierden (%s)" % jq2.estado)
	# 11) conquista
	var jc := _crear(Datos.normalizar(Datos.nivel_mini("estrategia")))
	await _marcos(jc, 2)
	jc._al_pulsar(0)
	jc._al_pulsar(1)
	ok(jc.grupos.size() == 1, "conquista: envía tropas")
	for i in 60 * 600:
		jc._actualizar(1.0 / 60.0)
		if jc.estado != "jugar":
			break
	ok(jc.estado in ["gano", "perdio"], "conquista termina (%s)" % jc.estado)
	# 12) frontal
	var jf := _crear(Datos.normalizar(Datos.nivel_mini("frontal")))
	await _marcos(jf, 2)
	for i in 60 * 60:
		jf._actualizar(1.0 / 60.0)
		if jf.estado != "jugar":
			break
	ok(jf.estado in ["gano", "perdio"] and jf.pos_m > 100.0, "frontal avanza (%.0f m, %s)" % [jf.pos_m, jf.estado])
	# 13) supervivencia
	var ns := Datos.normalizar(Datos.nivel_supervivencia())
	ok(ns.get("estilo", "") == "supervivencia", "superv normaliza")
	var js := _crear(ns)
	for i in 60 * 10:
		js._actualizar(1.0 / 60.0)
		if js.estado != "jugar":
			break
	ok(js.enemigos.size() > 0 or js.estado == "perdio", "superv: aparecen enemigos")
	# 14) RPG con diálogo y 3D
	var nr := Datos.normalizar(Datos.nivel_rpg())
	var dl := (nr["items"] as Array).filter(func(it): return it.has("dlg"))
	ok(dl.size() == 4, "rpg conserva diálogos (%d)" % dl.size())
	var n3 := Datos.normalizar(Datos.nivel_disparos3d())
	ok(n3.get("estilo", "") == "disparos3d" and Part.clase_para(n3) != Part.JuegoAventura, "disparos3d normaliza")
	var ci := Datos.normalizar(Datos.nivel_ciudad())
	ok(ci["modo"] == "3d" and Part.clase_para(ci) == Part.JuegoAventura, "ciudad es aventura 3D")
	print("FALLOS ", fallos)
	get_tree().quit()
