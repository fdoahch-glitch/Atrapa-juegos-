extends Node
var fallos := 0
func chk(c: bool, m: String) -> void:
	if not c:
		fallos += 1
		print("FALLO: ", m)
func _ready() -> void:
	var a = load("res://arranque.tscn").instantiate()
	add_child(a)
	await get_tree().create_timer(0.5).timeout
	# traduccion
	chk(Datos.traducir("Recogiste 3 de 5 premios", "en") == "You collected 3 of 5 items", "traduce regex: " + Datos.traducir("Recogiste 3 de 5 premios", "en"))
	chk(Datos.traducir("¡Nivel completado!", "en") == "Level complete!", "traduce frase")
	chk(Datos.traducir("¡Nivel completado!", "es") == "¡Nivel completado!", "es no cambia")
	# partida guardada
	var Pr = load("res://scripts/progreso.gd")
	Pr.guardar_partida("zz_prueba", 2, 77)
	chk(Pr.leer_partida("zz_prueba").get("idx") == 2, "guarda partida")
	Pr.borrar_partida("zz_prueba")
	chk(Pr.leer_partida("zz_prueba").is_empty(), "borra partida")
	# bloques unidos
	var n := Datos.normalizar(Datos.nivel_en_blanco("2d"))
	Datos.establecer_proyecto({"niveles": [n], "reglas": Datos.reglas_completas({})})
	for x in [3, 4, 5, 8]:
		var it := Datos.colocar({"t": "plat"}, x, 5)
		it["w"] = 1
		it["h"] = 1
	Datos.unir_bloques()
	var anchos := []
	for it in Datos.nivel["items"]:
		if it["t"] == "plat" and int(it["y"]) == 5:
			anchos.append(int(it["w"]))
	anchos.sort()
	chk(anchos == [1, 3], "pintar une bloques: " + str(anchos))
	# hoja
	var Imp = load("res://scripts/importar.gd")
	Imp.poner_hoja("u:fake.png", 4, 1, 8)
	chk(Imp.hoja("u:fake.png").get("c") == 4, "hoja guardada")
	Imp.poner_hoja("u:fake.png", 1, 1, 8)
	chk(Imp.hoja("u:fake.png").is_empty(), "hoja quitada")
	# juego: pausa, tactil, vigila, filtro
	var nn := Datos.normalizar(Datos.nivel_trio())
	nn["items"].append({"t": "enemy", "x": 14, "y": 11, "e": "a:slime", "r": 3, "sp": 40, "ia": "vigila", "id": "v1"})
	nn["filtro"] = "bn"
	nn["oscuridad"] = 0.7
	nn = Datos.normalizar(nn)
	var J = load("res://scripts/juego.gd").new()
	add_child(J)
	J.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nn["reglas"] = Datos.reglas_completas({"idioma": "en", "creditos": "Hecho por mi", "mec": {"dash": true, "disparar": true}})
	J.iniciar(nn, true, false)
	await get_tree().create_timer(0.3).timeout
	chk(J._zonas_extra().size() >= 2, "botones tactiles extra")
	chk(J._rect_zona("disp").size.x > 0, "rect zona disp")
	J._pausar()
	await get_tree().create_timer(0.2).timeout
	chk(J._menu_pausa != null, "menu pausa abre")
	var t0: float = J.t
	J._avanzar(0.5)
	chk(J.t == t0, "pausa congela")
	J._pausar()
	chk(J._menu_pausa == null, "pausa cierra")
	J._decir("¡Puerta abierta!")
	chk(J._msg == "Door opened!", "decir traduce")
	J.pos = Vector2(16 * 48, 11 * 48)
	for i in 30:
		J._actualizar(1.0 / 120.0)
	var vig = null
	for e in J.enemigos:
		if e["it"].get("ia") == "vigila":
			vig = e
	chk(vig != null and float(vig.get("alerta", 0.0)) > 0.0, "vigila se alerta")
	# partida: transicion y continuar
	var P = load("res://scripts/partida.gd").new()
	add_child(P)
	await get_tree().create_timer(0.2).timeout
	print("FALLOS ", fallos)
	get_tree().quit()
