extends Node
# Prueba: varios niveles, reglas, tiempo, meta condicionada, siguiente nivel y fin.
const Partida := preload("res://scripts/partida.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("  ok  " if c else "  MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	# --- proyecto con 3 niveles
	Datos.establecer(Datos.normalizar(Datos.nivel_inicial()))
	ok(Datos.num_niveles() == 1, "empieza con 1 nivel")
	ok(Datos.agregar_nivel(false), "agregar nivel vacío")
	Datos.nivel["theme"] = "noche"
	Datos.confirmar()
	ok(Datos.agregar_nivel(true), "duplicar nivel")
	ok(Datos.num_niveles() == 3 and Datos.idx == 2, "3 niveles, editando el 3")
	Datos.ir_a_nivel(0)
	ok(Datos.nivel["items"].size() > 5, "nivel 1 conserva su contenido")
	Datos.ir_a_nivel(1)
	ok(str(Datos.nivel["theme"]) == "noche", "nivel 2 conserva su tema")
	var json := Datos.a_json()
	ok(Datos.desde_json(json) and Datos.num_niveles() == 3, "ida y vuelta por JSON (3 niveles)")
	var viejo := Datos.proyecto_desde({"name": "x", "cols": 30, "items": [{"t": "goal", "x": 3, "y": 3}]})
	ok(viejo["niveles"].size() == 1, "un nivel suelto antiguo se abre como proyecto")
	# --- reglas
	Datos.reglas["vidas"] = 5
	Datos.reglas["tiempo"] = 30
	Datos.reglas["meta"] = "todo"
	Datos.reglas["pts_coin"] = 10
	var p := Datos.proyecto()
	ok(p["reglas"]["vidas"] == 5 and p["reglas"]["pts_coin"] == 10, "reglas viajan en el proyecto")
	# nivel 1 y 2 sin monedas ni enemigos extra: dejamos el nivel 1 original (tiene 6 monedas)
	var pa: Control = Partida.new()
	add_child(pa)
	pa.size = Vector2(1280, 720)
	pa.iniciar(p, 0, false, false, false)
	await get_tree().process_frame
	var j = pa._juego
	ok(j != null and j.vidas == 5, "vidas según reglas: %d" % j.vidas)
	ok(absf(j.tiempo_rest - 30.0) < 0.5, "tiempo según reglas: %.1f" % j.tiempo_rest)
	ok(j._vale("coin") == 10, "moneda vale 10")
	ok(j._faltan() == j.total and j.total > 0, "faltan %d premios (todo)" % j._faltan())
	# llegar a la meta sin premios: no gana
	j.pos = Vector2(j.meta["x"] * 48.0, j.meta["y"] * 48.0)
	j._actualizar(0.016)
	ok(j.estado == "jugar" and j._msg != "", "sin premios no se abre la meta: '%s'" % j._msg)
	# con todos los premios: gana
	for c in j.recogibles:
		c["got"] = true
	j.recogidos = j.total
	j.puntos = 123
	j._actualizar(0.016)
	ok(j.estado == "gano", "con todos los premios gana")
	ok(pa._panel != null and pa.puntos_acum == 123, "aparece panel de siguiente nivel (puntos 123)")
	# siguiente nivel
	pa._empezar(1)
	await get_tree().process_frame
	j = pa._juego
	ok(j.puntos == 123 and j.etiqueta_nivel == "Nivel 2 de 3", "nivel 2 arrastra puntos y etiqueta: %s" % j.etiqueta_nivel)
	# tiempo agotado
	j.tiempo_rest = 0.01
	j._actualizar(0.05)
	ok(j.estado == "perdio" and pa._panel != null, "se acaba el tiempo -> panel de reintentar")
	# último nivel -> final
	pa._empezar(2)
	await get_tree().process_frame
	j = pa._juego
	Datos.reglas["meta"] = "meta"
	j.reglas["meta"] = "meta"
	j.pos = Vector2(j.meta["x"] * 48.0, j.meta["y"] * 48.0)
	j._actualizar(0.016)
	ok(j.estado == "gano" and pa._panel != null, "último nivel completado -> pantalla final")
	# reiniciar con título
	pa._reiniciar()
	await get_tree().process_frame
	ok(pa.puntos_acum == 0 and pa._titulo != null, "reiniciar vuelve a la pantalla de título")
	# borrar nivel
	Datos.ir_a_nivel(2)
	ok(Datos.borrar_nivel() and Datos.num_niveles() == 2, "borrar nivel")
	print("FALLOS: ", fallos)
	get_tree().quit(fallos)
