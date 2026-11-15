extends Node
const Partida := preload("res://scripts/partida.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("  ok  " if c else "  MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	var base := {"plataformas": Datos.nivel_inicial(), "arriba": Datos.nivel_arriba(), "corredor": Datos.nivel_corredor(), "aventura": Datos.nivel_aventura()}
	for k in base:
		base[k] = Datos.normalizar(base[k])
	for de in base:
		for a in ["plataformas", "25d", "arriba", "aventura", "corredor"]:
			var n: Dictionary = Datos.convertir(base[de], a)
			var t: String = Datos.tipo_de(n)
			var monedas := 0
			var meta := 0
			var jug := 0
			for it in n["items"]:
				if it["t"] == "coin": monedas += 1
				if it["t"] == "goal": meta += 1
				if it["t"] == "player": jug += 1
			var necesita_jug: bool = a != "corredor"
			ok(t == a and meta == 1 and (jug == 1 or not necesita_jug) and monedas > 0, "%s -> %s (monedas %d, meta %d, inicio %d)" % [de, a, monedas, meta, jug])
			var p := Datos.proyecto_desde(n)
			var pa: Control = Partida.new()
			add_child(pa)
			pa.size = Vector2(1280, 720)
			pa.iniciar(p, 0, false, false, false)
			for f in 3:
				await get_tree().process_frame
			ok(pa._juego != null and pa._juego.estado == "jugar", "   corre en %s" % a)
			pa.queue_free()
			await get_tree().process_frame
	# en el editor
	Datos.establecer(Datos.normalizar(Datos.nivel_inicial()))
	Datos.convertir_actual("corredor")
	ok(Datos.num_niveles() == 2 and Datos.tipo_de(Datos.nivel) == "corredor", "convertir_actual crea nivel nuevo")
	Datos.ir_a_nivel(0)
	ok(Datos.tipo_de(Datos.nivel) == "plataformas", "el original sigue igual")
	print("FALLOS: ", fallos)
	get_tree().quit(fallos)
