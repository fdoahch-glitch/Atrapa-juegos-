extends Node
## Juegos de prueba por estilo: comprueba que los premios y la meta se puedan alcanzar,
## y juega cada uno con un bot para detectar errores. Capturas en /tmp/estilos/.
const Partida := preload("res://scripts/partida.gd")
var fallos := 0
var aviso := 0

func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1

# ---------------------------------------------------------------- alcanzabilidad
func _premios(n: Dictionary) -> Array:
	var r: Array = []
	for it in n["items"]:
		if ["coin", "star", "gem", "goal"].has(str(it["t"])):
			r.append(it)
	return r

func _inicio(n: Dictionary) -> Vector2i:
	for it in n["items"]:
		if str(it["t"]) == "player":
			return Vector2i(int(it["x"]), int(it["y"]))
	return Vector2i(1, 1)

## plataformas y 2.5D: superficies conectadas por saltos de hasta 3 filas y 4 columnas
func _alcanzables_plano(n: Dictionary) -> Array:
	var plats: Array = []
	for it in n["items"]:
		if str(it["t"]) == "plat":
			plats.append(it)
	var ini := _inicio(n)
	var cola: Array = []
	var vistos := {}
	for i in plats.size():
		var p: Dictionary = plats[i]
		if ini.x >= int(p["x"]) and ini.x < int(p["x"]) + int(p["w"]) and int(p["y"]) >= ini.y and int(p["y"]) <= ini.y + 3:
			cola.append(i); vistos[i] = true
	while not cola.is_empty():
		var a: Dictionary = plats[cola.pop_front()]
		for j in plats.size():
			if vistos.has(j): continue
			var b: Dictionary = plats[j]
			var hueco := maxi(0, maxi(int(b["x"]) - (int(a["x"]) + int(a["w"])), int(a["x"]) - (int(b["x"]) + int(b["w"]))))
			if hueco <= 4 and int(b["y"]) >= int(a["y"]) - 3:
				vistos[j] = true; cola.append(j)
	var fuera: Array = []
	for pr in _premios(n):
		var dentro := false
		var llega := false
		for j in vistos.keys():
			var p: Dictionary = plats[j]
			if int(pr["x"]) >= int(p["x"]) and int(pr["x"]) < int(p["x"]) + int(p["w"]) and int(pr["y"]) >= int(p["y"]) and int(pr["y"]) < int(p["y"]) + int(p["h"]):
				dentro = true
			if int(pr["x"]) >= int(p["x"]) - 3 and int(pr["x"]) <= int(p["x"]) + int(p["w"]) + 2 and int(pr["y"]) <= int(p["y"]) - 1 and int(pr["y"]) >= int(p["y"]) - 3:
				llega = true
		if dentro or not llega:
			fuera.append(pr)
	return fuera

## arriba y aventura: se camina por la cuadrícula; los bloques de altura 1-2 se suben
func _alcanzables_rejilla(n: Dictionary, aventura: bool) -> Array:
	var cols := int(n["cols"]); var filas := Datos.FILAS
	var pared := {}
	for it in n["items"]:
		if str(it["t"]) == "plat" and (not aventura or int(it.get("alt", 1)) > 2):
			for x in int(it["w"]):
				for y in int(it["h"]):
					pared[Vector2i(int(it["x"]) + x, int(it["y"]) + y)] = true
	var ini := _inicio(n)
	var vistos := {ini: true}
	var cola: Array = [ini]
	while not cola.is_empty():
		var c: Vector2i = cola.pop_front()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var s: Vector2i = c + d
			if s.x < 0 or s.y < 0 or s.x >= cols or s.y >= filas or pared.has(s) or vistos.has(s): continue
			vistos[s] = true; cola.append(s)
	var fuera: Array = []
	for pr in _premios(n):
		if not vistos.has(Vector2i(int(pr["x"]), int(pr["y"]))):
			fuera.append(pr)
	return fuera

func _revisar(nombre: String, n: Dictionary) -> void:
	var fuera: Array = []
	match Datos.tipo_de(n):
		"plataformas", "25d": fuera = _alcanzables_plano(n)
		"arriba": fuera = _alcanzables_rejilla(n, false)
		"aventura": fuera = _alcanzables_rejilla(n, true)
	var txt := ""
	for f in fuera: txt += " %s(%d,%d)" % [f["t"], f["x"], f["y"]]
	ok(fuera.is_empty(), "%s [%s]: premios y meta alcanzables%s" % [nombre, Datos.tipo_de(n), txt])

# ---------------------------------------------------------------- bot
func _tecla(k: int, p: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = k as Key; e.physical_keycode = k as Key; e.pressed = p
	Input.parse_input_event(e)

func _jugar(nombre: String, p: Dictionary, seg: float) -> void:
	var pa: Control = Partida.new()
	add_child(pa)
	pa.size = Vector2(1280, 720)
	pa.iniciar(p, 0, false, false, false)
	for f in 3: await get_tree().process_frame
	var j = pa._juego
	var t0 := Time.get_ticks_msec()
	var x0: float = j.pos.x if "pos" in j and j.pos is Vector2 else 0.0
	var k := 0
	while (Time.get_ticks_msec() - t0) / 1000.0 < seg and j.estado == "jugar":
		k += 1
		_tecla(KEY_D, true)
		_tecla(KEY_W if k % 20 < 10 else KEY_S, true)
		_tecla(KEY_SPACE, k % 12 < 2)
		_tecla(KEY_A, k % 150 > 120)
		await get_tree().process_frame
	for q in [KEY_D, KEY_W, KEY_S, KEY_SPACE, KEY_A]: _tecla(q, false)
	DirAccess.make_dir_recursive_absolute("/tmp/estilos")
	get_viewport().get_texture().get_image().save_png("/tmp/estilos/%s.png" % nombre)
	print("    %s: estado=%s puntos=%d recogidos=%d/%d vidas=%d" % [nombre, j.estado, j.puntos, j.recogidos, j.total, j.vidas])
	ok(j.estado in ["jugar", "gano", "perdio"], nombre + ": el juego sigue en un estado válido")
	pa.queue_free()
	await get_tree().process_frame

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/estilos")
	var base := {"plataformas": Datos.nivel_inicial(), "arriba": Datos.nivel_arriba(), "corredor": Datos.nivel_corredor(), "aventura": Datos.nivel_aventura()}
	# 1) niveles de muestra de cada estilo
	for k in base.keys():
		var n: Dictionary = Datos.normalizar(base[k])
		_revisar("muestra_" + k, n)
	# 2) los 5 ejemplos de la carpeta docs
	var ej: Array = []
	for f in DirAccess.get_files_at("res://docs/ejemplos"):
		if f.ends_with(".json"): ej.append(f)
	ej.sort()
	for f in ej:
		var p := Datos.leer_proyecto("res://docs/ejemplos/" + f)
		for i in p["niveles"].size():
			_revisar("%s#%d" % [f.get_basename(), i + 1], p["niveles"][i])
	# 3) las conversiones entre tipos
	var tipos := ["plataformas", "25d", "arriba", "aventura", "corredor"]
	for o in ["plataformas", "arriba", "aventura", "corredor"]:
		for d in tipos:
			if d == o: continue
			var c: Dictionary = Datos.convertir(Datos.normalizar(base[o].duplicate(true)), d)
			_revisar("%s->%s" % [o, d], c)
	# 4) un bot juega cada estilo
	var juegos := {
		"plataformas": Datos.normalizar(base["plataformas"].duplicate(true)),
		"25d": Datos.convertir(Datos.normalizar(base["plataformas"].duplicate(true)), "25d"),
		"arriba": Datos.normalizar(base["arriba"].duplicate(true)),
		"corredor3d": Datos.normalizar(base["corredor"].duplicate(true)),
		"aventura3d": Datos.normalizar(base["aventura"].duplicate(true)),
	}
	for nombre in juegos.keys():
		var pr := {"v": 2, "reglas": Datos.reglas_completas({}), "niveles": [juegos[nombre]]}
		await _jugar(nombre, pr, 8.0)
	print("FALLOS: ", fallos)
	get_tree().quit()
