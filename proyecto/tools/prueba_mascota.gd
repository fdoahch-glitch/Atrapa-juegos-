extends Node
# Prueba: poderes de la mascota en plataformas, corredor, aventura y desde arriba.
const Partida := preload("res://scripts/partida.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("  ok  " if c else "  MAL ") + m)
	if not c: fallos += 1
func _juego(nivel: Dictionary, poder: String, mascota: String = "🐱") -> Control:
	var p := Datos.proyecto_desde(Datos.normalizar(nivel))
	p["reglas"]["mascota"] = mascota
	p["reglas"]["poder"] = poder
	p["reglas"]["vidas"] = 3
	var pa: Control = Partida.new()
	add_child(pa)
	pa.size = Vector2(1280, 720)
	pa.iniciar(p, 0, false, false, false)
	await get_tree().process_frame
	return pa
func _ready() -> void:
	var casos := {"plataformas": Datos.nivel_inicial(), "corredor": Datos.nivel_corredor(), "aventura": Datos.nivel_aventura(), "arriba": Datos.nivel_arriba()}
	for k in casos:
		var n: Dictionary = casos[k].duplicate(true)
		if k == "corredor" or k == "aventura":
			n["modo"] = "3d"; n["tipo"] = k
		elif k == "arriba":
			n["tipo"] = "arriba"
		var pa = await _juego(n, "escudo")
		var j = pa._juego
		ok(j._escudos == 1 and j.vidas == 3, "%s: escudo listo" % k)
		j._herir()
		ok(j.vidas == 3 and j._escudos == 0, "%s: el escudo absorbió el golpe" % k)
		j.inv = 0.0
		j._herir()
		ok(j.vidas == 2, "%s: sin escudo, pierde vida" % k)
		pa.queue_free()
		pa = await _juego(n, "vida")
		ok(pa._juego.vidas == 4, "%s: vida extra (%d)" % [k, pa._juego.vidas])
		pa.queue_free()
		pa = await _juego(n, "bono")
		ok(pa._juego._vale("coin") == 2 or pa._juego._vale("coin") == 1, "%s: bono moneda=%d" % [k, pa._juego._vale("coin")])
		ok(pa._juego._vale("star") == 8, "%s: bono estrella=%d" % [k, pa._juego._vale("star")])
		pa.queue_free()
		pa = await _juego(n, "escudo", "")
		ok(pa._juego._escudos == 0, "%s: sin mascota no hay poder" % k)
		pa.queue_free()
		pa = await _juego(n, "iman", "g:oviraptor.glb")
		ok(pa._juego._iman, "%s: imán activo" % k)
		for f in 5:
			await get_tree().process_frame
		pa.queue_free()
		await get_tree().process_frame
	print("FALLOS: ", fallos)
	get_tree().quit(fallos)
