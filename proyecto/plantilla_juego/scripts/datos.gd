extends Node
## Datos del creador (autoload "Datos"): catálogo, temas, nivel actual,
## deshacer/rehacer y guardado. El formato del nivel es el mismo JSON que usa
## la versión web del Atrapa Juegos Studio, así que los niveles son compatibles.

const Importar := preload("res://scripts/importar.gd")
const Assets3D := preload("res://scripts/assets3d.gd")

signal nivel_cambiado

const T := 48          # tamaño de una celda del nivel (px)
const FILAS := 14      # alto del nivel en celdas
const GUARDADO := "user://nivel_actual.json"

var temas := {
	"dia": {"n": "Día soleado", "cielo": [Color("6fc3ff"), Color("d9f1ff")], "lejos": Color("a6dcaa"), "cerca": Color("6cbf7a"), "deco": "sol", "plat": [Color("8a5a33"), Color("5fb54a")]},
	"atardecer": {"n": "Atardecer", "cielo": [Color("ff8a6b"), Color("ffd9a0")], "lejos": Color("d98aa0"), "cerca": Color("9a5fa3"), "deco": "sol2", "plat": [Color("6b3f3f"), Color("e0894f")]},
	"noche": {"n": "Noche estrellada", "cielo": [Color("0b1033"), Color("2f3475")], "lejos": Color("2e3a7a"), "cerca": Color("1f2a5e"), "deco": "estrellas", "plat": [Color("2a2f55"), Color("6c7be0")]},
	"bosque": {"n": "Bosque", "cielo": [Color("bfe8c4"), Color("f0fadf")], "lejos": Color("5aa86a"), "cerca": Color("2f7a47"), "deco": "arboles", "plat": [Color("5b3c26"), Color("3f9a3f")]},
	"desierto": {"n": "Desierto", "cielo": [Color("ffd070"), Color("fff1c9")], "lejos": Color("ecbf72"), "cerca": Color("d99a4a"), "deco": "sol", "plat": [Color("b87a3a"), Color("e8c070")]},
	"mar": {"n": "Fondo del mar", "cielo": [Color("2aa6d6"), Color("0b5a8f")], "lejos": Color("1c7fb0"), "cerca": Color("0f6a9b"), "deco": "burbujas", "plat": [Color("3c6e8a"), Color("58d0c0")]},
	"espacio": {"n": "Espacio", "cielo": [Color("05040f"), Color("1d1250")], "lejos": Color("2b1b5c"), "cerca": Color("1c1240"), "deco": "estrellas", "plat": [Color("4a4a6a"), Color("a78bfa")]},
	"pantano": {"n": "Pantano", "cielo": [Color("3b5a4a"), Color("a7c9a0")], "lejos": Color("456b4d"), "cerca": Color("2f5a3e"), "deco": "arboles", "plat": [Color("3d3a24"), Color("5f8a3a")]},
	"valle": {"n": "Valle de titanes", "cielo": [Color("e87b4a"), Color("ffd9a0")], "lejos": Color("b5703f"), "cerca": Color("8a5230"), "deco": "sol2", "plat": [Color("6b4a2c"), Color("c98a4a")]},
	"nieve": {"n": "Nieve", "cielo": [Color("bfe1ff"), Color("f4fbff")], "lejos": Color("dbeaf5"), "cerca": Color("b3cfe4"), "deco": "nieve", "plat": [Color("7fa3bd"), Color.WHITE]},
}

# [nombre, emoji]
var heroes := [["Gato", "🐱"], ["Perro", "🐶"], ["Dino", "🦖"], ["Conejo", "🐰"], ["Zorro", "🦊"], ["Panda", "🐼"], ["Robot", "🤖"], ["Mago", "🧙"]]
# [nombre, emoji, vuela, velocidad]
var enemigos := [["Caracol", "🐌", false, 40], ["Alien", "👾", false, 90], ["Abeja", "🐝", true, 80], ["Cangrejo", "🦀", false, 70], ["Fantasma", "👻", true, 60]]
# [nombre, emoji, tamaño]
var decoraciones := [["Árbol", "🌳", 64], ["Pino", "🌲", 64], ["Flor", "🌸", 34], ["Girasol", "🌻", 46], ["Hongo", "🍄", 34], ["Cactus", "🌵", 56], ["Casa", "🏠", 72], ["Castillo", "🏰", 84], ["Nube", "☁️", 70]]

var nivel: Dictionary = {}          # el nivel que se está editando
var niveles: Array = []             # copias de todos los niveles (el actual se sincroniza al cambiar)
var idx := 0                        # posición del nivel actual
var reglas: Dictionary = {}         # reglas del juego completo
const MAX_NIVELES := 10
const REGLAS_BASE := {"vidas": 3, "tiempo": 0, "meta": "meta", "pts_coin": 1, "pts_gem": 3, "pts_star": 5, "pts_enemy": 2, "titulo": true, "final": "¡Ganaste el juego!", "musica": "", "mascota": "", "poder": "escudo", "tienda": false, "jugadores": 1, "heroe2": ""}
var historial: Array[String] = []
var futuro: Array[String] = []
var _actual := ""
var _cache_tex := {}
var _contador := 1000


func _ready() -> void:
	cargar_guardado()


# ---------------------------------------------------------------- texturas
func textura(e: String) -> Texture2D:
	if e == "":
		return null
	if _cache_tex.has(e):
		return _cache_tex[e]
	var tex: Texture2D = null
	if e.begins_with("a:"):
		# modelo genérico "horneado": assets/modelos2d/<id>.png
		var r2 := "res://assets/modelos2d/%s.png" % e.substr(2)
		if ResourceLoader.exists(r2):
			tex = load(r2)
	elif e.begins_with("u:") or e.begins_with("g:"):
		# archivos importados por el usuario (dibujo .png, o miniatura de un .glb)
		var f := Importar.ruta_dibujo(e)
		if FileAccess.file_exists(f):
			var img := Image.load_from_file(f)
			if img:
				tex = ImageTexture.create_from_image(img)
	else:
		var ruta := "res://assets/emoji/%x.png" % e.unicode_at(0)
		if ResourceLoader.exists(ruta):
			tex = load(ruta)
	_cache_tex[e] = tex
	return tex


func olvidar_textura(e: String) -> void:
	_cache_tex.erase(e)


## Ajusta la ventana/pantalla del juego exportado según lo elegido al crearlo.
func aplicar_pantalla(n: Dictionary) -> void:
	var vertical := str(n.get("orient", "horizontal")) == "vertical"
	if OS.has_feature("android") or OS.has_feature("ios"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_PORTRAIT if vertical else DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	elif not OS.has_feature("web") and DisplayServer.get_name() != "headless":
		var tam := Vector2i(540, 960) if vertical else Vector2i(1280, 720)
		var pant := DisplayServer.screen_get_size()
		if tam.y > pant.y - 80:
			tam = Vector2i(int(tam.x * (pant.y - 80.0) / tam.y), pant.y - 80)
		DisplayServer.window_set_size(tam)
		DisplayServer.window_set_position((pant - tam) / 2)


func es_nube(e: String) -> bool:
	return e == "a:nube" or (e != "" and e.unicode_at(0) == 0x2601)


# ---------------------------------------------------------------- niveles
func nuevo_id() -> String:
	_contador += 1
	return "i%d" % _contador


## Pista de ejemplo del modo 3D (corredor de 3 carriles).
func nivel_corredor() -> Dictionary:
	var items: Array = []
	var n := 0
	var add := func(t: String, x: int, c: int) -> void:
		n += 1
		items.append({"id": "i%d" % n, "t": t, "x": x, "y": CARRILES[c]})
	for x in range(4, 9):
		add.call("coin", x, 1)
	add.call("valla", 10, 1)
	for x in range(12, 16):
		add.call("coin", x, 0)
	add.call("pared", 14, 1)
	add.call("pared", 14, 2)
	add.call("viga", 18, 1)
	for x in range(20, 24):
		add.call("coin", x, 2)
	add.call("valla", 22, 0)
	add.call("pared", 22, 1)
	add.call("star", 26, 1)
	add.call("viga", 28, 0)
	add.call("viga", 28, 2)
	for x in range(30, 34):
		add.call("coin", x, 1)
	add.call("valla", 32, 1)
	add.call("gem", 36, 0)
	add.call("pared", 38, 0)
	add.call("pared", 38, 1)
	add.call("goal", 43, 1)
	for d in [["🌳", 3, 64], ["🌲", 9, 64], ["🌸", 15, 34], ["🌻", 21, 46], ["🌳", 27, 64], ["🌲", 34, 64], ["🍄", 40, 34]]:
		n += 1
		items.append({"id": "i%d" % n, "t": "deco", "e": d[0], "x": d[1], "y": 0 if d[1] % 2 == 1 else 12, "s": d[2]})
	return {"name": "Mi corredor", "modo": "3d", "theme": "dia", "hero": "🐱", "cols": 45, "rows": FILAS, "items": items}


## Mundo de ejemplo del modo 3D «Aventura»: se ve desde arriba; 1 celda = 2 metros.
func nivel_aventura() -> Dictionary:
	var items: Array = []
	var n := 0
	var add := func(o: Dictionary) -> void:
		o["id"] = nuevo_id()
		items.append(o)
	add.call({"t": "player", "x": 2, "y": 6})
	add.call({"t": "goal", "x": 27, "y": 6})
	for b in [[8, 3, 3, 2, 1], [12, 8, 4, 2, 2], [20, 5, 2, 4, 1], [16, 3, 2, 2, 3]]:
		add.call({"t": "plat", "x": b[0], "y": b[1], "w": b[2], "h": b[3], "alt": b[4]})
	for c in [[5, 6], [6, 6], [7, 6], [10, 5], [14, 6], [18, 9], [19, 9], [22, 7], [24, 4]]:
		add.call({"t": "coin", "x": c[0], "y": c[1]})
	add.call({"t": "star", "x": 17, "y": 2})
	add.call({"t": "gem", "x": 25, "y": 10})
	add.call({"t": "spike", "x": 11, "y": 6})
	add.call({"t": "enemy", "x": 15, "y": 10, "e": "a:slime", "r": 3, "sp": 60, "fly": false})
	add.call({"t": "enemy", "x": 23, "y": 3, "e": "a:esqueleto", "r": 3, "sp": 60, "fly": false})
	for d in [["a:arbol", 4, 2], ["a:pino", 6, 11], ["a:casa", 22, 11], ["a:roca", 9, 10], ["a:arbusto", 13, 11], ["a:farol", 3, 9], ["a:cerca", 24, 6], ["a:cofre", 26, 8], ["a:cactus", 19, 12], ["a:nube", 12, 1]]:
		var sz := Assets3D.cuadro_px(d[0].substr(2)) if Assets3D != null else 96
		add.call({"t": "deco", "e": d[0], "x": d[1], "y": d[2], "s": sz})
	return {"name": "Mi aventura", "modo": "3d", "tipo": "aventura", "theme": "dia", "hero": "a:explorador", "cols": 30, "rows": FILAS, "items": items}


## Nivel de ejemplo de «vista desde arriba»: un pequeño laberinto con tesoros.
func nivel_arriba() -> Dictionary:
	var items: Array = []
	var add := func(o: Dictionary) -> void:
		o["id"] = nuevo_id()
		items.append(o)
	for w in [[0, 0, 30, 1], [0, 13, 30, 1], [0, 1, 1, 12], [29, 1, 1, 12],
			[5, 1, 1, 7], [10, 5, 1, 8], [15, 1, 1, 7], [20, 5, 1, 8], [25, 1, 1, 7],
			[6, 6, 3, 1], [16, 9, 3, 1], [21, 4, 3, 1]]:
		add.call({"t": "plat", "x": w[0], "y": w[1], "w": w[2], "h": w[3]})
	add.call({"t": "player", "x": 2, "y": 2})
	add.call({"t": "goal", "x": 27, "y": 11})
	for c in [[3, 5], [7, 3], [8, 9], [12, 2], [13, 10], [17, 4], [18, 11], [22, 8], [24, 3], [27, 6]]:
		add.call({"t": "coin", "x": c[0], "y": c[1]})
	add.call({"t": "star", "x": 23, "y": 2})
	add.call({"t": "gem", "x": 12, "y": 7})
	for sp in [[2, 8], [8, 11], [17, 7]]:
		add.call({"t": "spike", "x": sp[0], "y": sp[1]})
	add.call({"t": "enemy", "x": 6, "y": 4, "e": "🐌", "r": 3, "sp": 40, "fly": false})
	add.call({"t": "enemy", "x": 11, "y": 1, "e": "🐝", "r": 3, "sp": 70, "fly": true})
	add.call({"t": "enemy", "x": 21, "y": 11, "e": "👾", "r": 3, "sp": 60, "fly": false})
	return {"name": "Mi laberinto", "modo": "2d", "tipo": "arriba", "theme": "dia", "hero": "🐱", "cols": 30, "rows": FILAS, "items": items}


func nivel_inicial() -> Dictionary:
	var items: Array = []
	var n := 0
	var add := func(o: Dictionary) -> void:
		o["id"] = nuevo_id()
		items.append(o)
	add.call({"t": "plat", "x": 0, "y": 12, "w": 10, "h": 2})
	add.call({"t": "plat", "x": 13, "y": 12, "w": 17, "h": 2})
	add.call({"t": "plat", "x": 6, "y": 9, "w": 3, "h": 1})
	add.call({"t": "plat", "x": 15, "y": 9, "w": 3, "h": 1})
	add.call({"t": "plat", "x": 20, "y": 7, "w": 3, "h": 1})
	for d in [[1, 11, "player"], [6, 8, "coin"], [7, 8, "coin"], [8, 8, "coin"], [15, 8, "coin"], [16, 8, "coin"], [17, 8, "coin"], [21, 6, "star"], [11, 10, "gem"], [28, 11, "goal"], [17, 11, "spike"], [24, 11, "spring"]]:
		add.call({"t": d[2], "x": d[0], "y": d[1]})
	add.call({"t": "enemy", "x": 21, "y": 11, "e": "🐌", "r": 3, "sp": 40})
	for d in [[3, 11, "🌳", 64], [5, 11, "🌸", 34], [8, 11, "🍄", 34], [14, 11, "🌻", 46], [8, 3, "☁️", 70], [20, 2, "☁️", 70]]:
		add.call({"t": "deco", "x": d[0], "y": d[1], "e": d[2], "s": d[3]})
	return {"name": "Mi primer juego", "theme": "dia", "hero": "🐱", "cols": 30, "rows": FILAS, "items": items}


## Tipo de juego de un nivel: "plataformas", "25d", "arriba", "aventura" o "corredor".
func tipo_de(n: Dictionary) -> String:
	var m := str(n.get("modo", "2d"))
	var t := str(n.get("tipo", ""))
	if m == "25d":
		return "25d"
	if m == "3d":
		return "aventura" if t == "aventura" else "corredor"
	return "arriba" if t == "arriba" else "plataformas"


## Convierte un nivel a otro tipo de juego (2D, 2.5D, 3D, vista desde arriba…) conservando lo que se pueda:
## héroe, tema, fondo, monedas, estrellas, gemas, enemigos, pinchos, meta y decoración.
func convertir(origen: Dictionary, destino: String) -> Dictionary:
	var n: Dictionary = origen.duplicate(true)
	var de := tipo_de(origen)
	if de == destino:
		return n
	var cols := int(n.get("cols", 30))
	var items: Array = n.get("items", [])
	var salida: Array = []
	var add := func(o: Dictionary) -> void:
		o["id"] = nuevo_id()
		salida.append(o)
	var tier := func(t: String) -> String:
		return "plano" if t in ["plataformas", "25d"] else ("arriba" if t in ["arriba", "aventura"] else "carril")
	var a: String = tier.call(de)
	var b: String = tier.call(destino)
	if a == b:
		salida = items
	else:
		var jug := Vector2i(2, 6)
		var meta := Vector2i(cols - 3, 6)
		for it in items:
			if it.get("t", "") == "player":
				jug = Vector2i(int(it["x"]), int(it["y"]))
			if it.get("t", "") == "goal":
				meta = Vector2i(int(it["x"]), int(it["y"]))
		if b == "carril":
			cols = clampi(maxi(cols, 45), 45, 120)
			for it in items:
				var t := str(it.get("t", ""))
				var x := int(it.get("x", 0))
				var y := int(it.get("y", 0))
				var c := a_carril(y) if a == "plano" else a_carril(3 + (y % 7))
				if a == "arriba":
					c = (y * 3) / Datos.FILAS
				if t in ["coin", "star", "gem"]:
					add.call({"t": t, "x": maxi(4, x), "y": CARRILES[c]})
				elif t in ["enemy", "spike"]:
					add.call({"t": "valla", "x": maxi(5, x), "y": CARRILES[c]})
				elif t == "deco":
					var d: Dictionary = it.duplicate(true)
					add.call(d)
			add.call({"t": "goal", "x": cols - 2, "y": CARRILES[1]})
		elif b == "arriba":
			for it in items:
				var t := str(it.get("t", ""))
				if a == "carril":
					var y := int(it.get("y", 6))
					var c2 := a_carril(y)
					var fila := 3 + c2 * 3
					var x := int(it.get("x", 0))
					if t in ["coin", "star", "gem"]:
						add.call({"t": t, "x": x % 27 + 1, "y": fila})
					elif t == "valla":
						add.call({"t": "spike", "x": x % 27 + 1, "y": fila})
					elif t == "pared":
						add.call({"t": "plat", "x": x % 27 + 1, "y": fila, "w": 1, "h": 1})
				elif t in ["plat"]:
					continue
				elif t in ["spring"]:
					continue
				else:
					add.call(it.duplicate(true))
			for w in [[0, 0, cols, 1], [0, 13, cols, 1], [0, 1, 1, 12], [cols - 1, 1, 1, 12]]:
				add.call({"t": "plat", "x": w[0], "y": w[1], "w": w[2], "h": w[3]})
			if a == "carril":
				add.call({"t": "player", "x": 2, "y": 6})
				add.call({"t": "goal", "x": cols - 3, "y": 6})
		else:
			# destino plano: todo va sobre un suelo
			add.call({"t": "plat", "x": 0, "y": 12, "w": cols, "h": 2})
			add.call({"t": "player", "x": 1, "y": 11})
			add.call({"t": "goal", "x": cols - 2, "y": 11})
			for it in items:
				var t := str(it.get("t", ""))
				var x := int(it.get("x", 0))
				var y := int(it.get("y", 0))
				if a == "arriba":
					if t == "plat" and not (int(it.get("y", 0)) in [0, 13] or int(it.get("x", 0)) in [0, cols - 1]) and int(it.get("h", 1)) <= 2:
						var p: Dictionary = it.duplicate(true)
						p["y"] = 8 + int(y) % 3
						p["h"] = 1
						add.call(p)
					elif t in ["coin", "star", "gem"]:
						add.call({"t": t, "x": x, "y": 8 + y % 3})
					elif t == "spike":
						add.call({"t": "spike", "x": x, "y": 11})
					elif t == "enemy":
						var e: Dictionary = it.duplicate(true)
						e["y"] = 11
						add.call(e)
					elif t == "deco":
						var d2: Dictionary = it.duplicate(true)
						d2["y"] = 11
						add.call(d2)
				else:
					if t in ["coin", "star", "gem"]:
						add.call({"t": t, "x": x, "y": 11 - (2 - a_carril(y)) * 2 - 0})
					elif t == "valla":
						add.call({"t": "spike", "x": x, "y": 11})
					elif t == "pared":
						add.call({"t": "enemy", "x": x, "y": 11, "e": "🐌", "r": 2, "sp": 40})
					elif t == "deco":
						var d3: Dictionary = it.duplicate(true)
						d3["y"] = 11
						add.call(d3)
	n["items"] = salida
	n["cols"] = cols
	match destino:
		"plataformas":
			n["modo"] = "2d"
			n["tipo"] = "plataformas"
		"25d":
			n["modo"] = "25d"
			n["tipo"] = "plataformas"
		"arriba":
			n["modo"] = "2d"
			n["tipo"] = "arriba"
		"aventura":
			n["modo"] = "3d"
			n["tipo"] = "aventura"
		"corredor":
			n["modo"] = "3d"
			n["tipo"] = "corredor"
	return normalizar(n)


func nivel_en_blanco(modo: String = "") -> Dictionary:
	if modo == "":
		modo = str(nivel.get("modo", "2d"))
	if modo == "2d" and str(nivel.get("tipo", "")) == "arriba":
		return {"name": "Laberinto nuevo", "modo": "2d", "tipo": "arriba", "theme": "dia", "hero": "🐱", "cols": 30, "rows": FILAS, "items": [
			{"id": "i1", "t": "plat", "x": 0, "y": 0, "w": 30, "h": 1}, {"id": "i2", "t": "plat", "x": 0, "y": 13, "w": 30, "h": 1},
			{"id": "i3", "t": "plat", "x": 0, "y": 1, "w": 1, "h": 12}, {"id": "i4", "t": "plat", "x": 29, "y": 1, "w": 1, "h": 12},
			{"id": "i5", "t": "player", "x": 2, "y": 6}, {"id": "i6", "t": "goal", "x": 27, "y": 6}]}
	if modo == "3d" and str(nivel.get("tipo", "")) == "aventura":
		return {"name": "Aventura nueva", "modo": "3d", "tipo": "aventura", "theme": "dia", "hero": "a:explorador", "cols": 30, "rows": FILAS, "items": [
			{"id": "i1", "t": "player", "x": 2, "y": 6}, {"id": "i2", "t": "goal", "x": 27, "y": 6}]}
	if modo == "3d":
		return {"name": "Corredor nuevo", "modo": "3d", "theme": "dia", "hero": "🐱", "cols": 45, "rows": FILAS, "items": [
			{"id": "i1", "t": "goal", "x": 43, "y": 6}]}
	return {"name": "Juego nuevo", "modo": modo, "theme": "dia", "hero": "🐱", "cols": 30, "rows": FILAS, "items": [
		{"id": "i1", "t": "plat", "x": 0, "y": 12, "w": 30, "h": 2},
		{"id": "i2", "t": "player", "x": 1, "y": 11},
		{"id": "i3", "t": "goal", "x": 28, "y": 11}]}


## Deja el nivel con tipos correctos (el JSON trae números decimales).
func normalizar(n: Dictionary) -> Dictionary:
	n["cols"] = clampi(int(n.get("cols", 30)), 10, 120)
	n["rows"] = FILAS
	n["name"] = str(n.get("name", "Mi juego"))
	n["disp"] = "movil" if str(n.get("disp", "pc")) == "movil" else "pc"
	n["orient"] = "vertical" if str(n.get("orient", "horizontal")) == "vertical" else "horizontal"
	n["tipo"] = str(n.get("tipo", "")) if ["corredor", "aventura", "plataformas", "arriba"].has(str(n.get("tipo", ""))) else ("corredor" if str(n.get("modo", "2d")) == "3d" else "plataformas")
	n["modo"] = str(n.get("modo", "2d")) if ["2d", "25d", "3d"].has(str(n.get("modo", "2d"))) else "2d"
	if not temas.has(str(n.get("theme", "dia"))):
		n["theme"] = "dia"
	n["theme"] = str(n.get("theme", "dia"))
	if str(n.get("hero", "")) == "":
		n["hero"] = "🐱"
	if not (n.get("items") is Array):
		n["items"] = []
	var limpios: Array = []
	for it in n["items"]:
		if not (it is Dictionary) or not it.has("t"):
			continue
		# sin posición no se puede colocar: se descarta en vez de romper el juego
		if not ((it.get("x") is int or it.get("x") is float) and (it.get("y") is int or it.get("y") is float)):
			continue
		for k in ["x", "y", "w", "h", "r", "sp", "s", "alt"]:
			if it.has(k):
				if it[k] is int or it[k] is float:
					it[k] = int(it[k])
				else:
					it.erase(k)
		if ["plat", "pared", "viga", "valla"].has(str(it["t"])):
			it["w"] = maxi(1, int(it.get("w", 1)))
			it["h"] = maxi(1, int(it.get("h", 1)))
		if ["deco", "enemy"].has(str(it["t"])) and str(it.get("e", "")) == "":
			it["e"] = "👾" if str(it["t"]) == "enemy" else "🌳"
		if not it.has("id"):
			it["id"] = nuevo_id()
		limpios.append(it)
	n["items"] = limpios
	return n


## Reglas con todos los valores presentes (los que falten usan el valor base).
func reglas_completas(r: Dictionary) -> Dictionary:
	var o: Dictionary = REGLAS_BASE.duplicate()
	for k in o.keys():
		if r.has(k):
			var v = r[k]
			if o[k] is bool:
				o[k] = bool(v)
			elif o[k] is String:
				o[k] = str(v)
			else:
				o[k] = int(v)
	var cat: Array = []
	if r.get("catalogo", []) is Array:
		for it in r.get("catalogo", []):
			if it is Dictionary and it.has("id") and it.has("poder"):
				cat.append({"id": str(it["id"]), "n": str(it.get("n", "Mascota")), "poder": str(it["poder"]), "precio": int(it.get("precio", 10)), "desc": str(it.get("desc", ""))})
	o["catalogo"] = cat
	var jug: Array = []
	if r.get("jugables", []) is Array:
		for it in r.get("jugables", []):
			if it is Dictionary and it.has("id"):
				jug.append({"id": str(it["id"]), "n": str(it.get("n", "Personaje")), "poder": str(it.get("poder", "")), "desc": str(it.get("desc", ""))})
	o["jugables"] = jug
	o["jugadores"] = 2 if int(o["jugadores"]) == 2 else 1
	if not preload("res://scripts/tienda.gd").EFECTOS.has(str(o["poder"])):
		o["poder"] = "escudo"
	o["vidas"] = clampi(int(o["vidas"]), 1, 9)
	o["tiempo"] = clampi(int(o["tiempo"]), 0, 900)
	if not ["meta", "mitad", "todo"].has(str(o["meta"])):
		o["meta"] = "meta"
	for k in ["pts_coin", "pts_gem", "pts_star", "pts_enemy"]:
		o[k] = clampi(int(o[k]), 0, 99)
	return o


## Convierte lo que haya en el JSON (un nivel suelto o un proyecto) en
## {"niveles": [...], "reglas": {...}} con todo normalizado. Vacío si no sirve.
func proyecto_desde(r: Variant) -> Dictionary:
	if not (r is Dictionary):
		return {}
	var lista: Array = []
	if r.has("niveles") and r["niveles"] is Array:
		for n in r["niveles"]:
			if n is Dictionary and n.has("items"):
				lista.append(normalizar(n))
	elif r.has("items"):
		lista.append(normalizar(r))
	if lista.is_empty():
		return {}
	if lista.size() > MAX_NIVELES:
		lista.resize(MAX_NIVELES)
	return {"niveles": lista, "reglas": reglas_completas(r.get("reglas", {}) if r.get("reglas", {}) is Dictionary else {})}


func leer_proyecto(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		return {}
	return proyecto_desde(JSON.parse_string(f.get_as_text()))


## El proyecto completo tal como está ahora (el nivel actual incluido).
func proyecto() -> Dictionary:
	_guardar_actual_en_lista()
	var lista: Array = []
	for n in niveles:
		var c: Dictionary = n.duplicate(true)
		for k in ["disp", "orient"]:  # del proyecto entero; nombre, modo y tipo son de cada nivel
			c[k] = nivel.get(k, c.get(k))
		lista.append(c)
	return {"v": 2, "reglas": reglas_completas(reglas), "niveles": lista}


func a_json() -> String:
	return JSON.stringify(proyecto())


func desde_json(texto: String) -> bool:
	var p := proyecto_desde(JSON.parse_string(texto))
	if p.is_empty():
		return false
	establecer_proyecto(p)
	return true


# ---------------------------------------------------------------- niveles
func num_niveles() -> int:
	return maxi(1, niveles.size())


func _guardar_actual_en_lista() -> void:
	if niveles.is_empty():
		niveles = [nivel.duplicate(true)]
		idx = 0
	else:
		idx = clampi(idx, 0, niveles.size() - 1)
		niveles[idx] = nivel.duplicate(true)


func _poner_nivel(n: Dictionary) -> void:
	nivel = n
	_actual = JSON.stringify(nivel)
	historial.clear()
	futuro.clear()
	guardar()
	nivel_cambiado.emit()


func establecer_proyecto(p: Dictionary) -> void:
	respaldar()
	niveles = p["niveles"]
	reglas = reglas_completas(p.get("reglas", {}))
	idx = 0
	_poner_nivel(niveles[0].duplicate(true))


func ir_a_nivel(i: int) -> void:
	_guardar_actual_en_lista()
	i = clampi(i, 0, niveles.size() - 1)
	if i == idx:
		return
	idx = i
	_poner_nivel(niveles[idx].duplicate(true))


## Agrega un nivel al final (vacío o copia del actual) y se pone a editarlo.
func agregar_nivel(copiar: bool = false) -> bool:
	_guardar_actual_en_lista()
	if niveles.size() >= MAX_NIVELES:
		return false
	var n: Dictionary
	if copiar:
		n = nivel.duplicate(true)
		for it in n["items"]:
			it["id"] = nuevo_id()
	else:
		n = nivel_en_blanco()
		for k in ["name", "modo", "disp", "orient", "tipo", "theme", "hero"]:
			n[k] = nivel.get(k, n.get(k))
		n = normalizar(n)
	niveles.append(n)
	idx = niveles.size() - 1
	_poner_nivel(n.duplicate(true))
	return true


const NOMBRES_TIPO := {"plataformas": "Plataformas 2D", "25d": "Plataformas 2.5D", "arriba": "Vista desde arriba", "aventura": "Aventura 3D", "corredor": "Corredor 3D"}


## Convierte el nivel actual a otro tipo de juego. Si hay espacio, la versión nueva se guarda como
## un nivel más (el original queda intacto); si no, reemplaza al actual.
func convertir_actual(destino: String) -> bool:
	_guardar_actual_en_lista()
	var conv := convertir(nivel, destino)
	conv["name"] = ("%s · %s" % [str(nivel.get("name", "Nivel")).left(18), NOMBRES_TIPO.get(destino, destino)])
	if niveles.size() < MAX_NIVELES:
		niveles.append(conv)
		idx = niveles.size() - 1
		_poner_nivel(conv.duplicate(true))
		return true
	niveles[idx] = conv
	_poner_nivel(conv.duplicate(true))
	return false


func borrar_nivel() -> bool:
	_guardar_actual_en_lista()
	if niveles.size() <= 1:
		return false
	niveles.remove_at(idx)
	idx = clampi(idx, 0, niveles.size() - 1)
	_poner_nivel(niveles[idx].duplicate(true))
	return true


# ---------------------------------------------------------------- historial
## Empieza un juego nuevo con un solo nivel.
func establecer(n: Dictionary) -> void:
	respaldar()
	niveles = [n]
	idx = 0
	reglas = reglas_completas({})
	_poner_nivel(n)


func confirmar() -> void:
	var s := JSON.stringify(nivel)
	if s == _actual:
		return
	historial.append(_actual)
	if historial.size() > 80:
		historial.pop_front()
	_actual = s
	futuro.clear()
	guardar()
	nivel_cambiado.emit()


func deshacer() -> void:
	if historial.is_empty():
		return
	futuro.append(_actual)
	_actual = historial.pop_back()
	nivel = normalizar(JSON.parse_string(_actual))
	_actual = JSON.stringify(nivel)
	guardar()
	nivel_cambiado.emit()


func rehacer() -> void:
	if futuro.is_empty():
		return
	historial.append(_actual)
	_actual = futuro.pop_back()
	nivel = normalizar(JSON.parse_string(_actual))
	_actual = JSON.stringify(nivel)
	guardar()
	nivel_cambiado.emit()


## Guarda sin riesgo: escribe en un archivo temporal, comprueba que se lee bien y recién entonces
## reemplaza el anterior (que queda como copia «.bak»). Así un corte a mitad no borra el juego.
func guardar() -> void:
	var texto := a_json()
	var tmp := GUARDADO + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(texto)
	f.close()
	if not (JSON.parse_string(texto) is Dictionary):
		return
	if FileAccess.file_exists(GUARDADO):
		DirAccess.copy_absolute(GUARDADO, GUARDADO + ".bak")
	DirAccess.rename_absolute(tmp, GUARDADO)


const DIR_RESPALDOS := "user://respaldos"


## Antes de reemplazar el juego por otro, guarda una copia (se conservan las últimas 5).
func respaldar() -> void:
	if not FileAccess.file_exists(GUARDADO):
		return
	DirAccess.make_dir_recursive_absolute(DIR_RESPALDOS)
	var t := Time.get_datetime_dict_from_system()
	var nombre := "%04d%02d%02d_%02d%02d%02d.json" % [t["year"], t["month"], t["day"], t["hour"], t["minute"], t["second"]]
	DirAccess.copy_absolute(GUARDADO, DIR_RESPALDOS + "/" + nombre)
	var viejos := Array(DirAccess.get_files_at(DIR_RESPALDOS))
	viejos.sort()
	while viejos.size() > 5:
		DirAccess.remove_absolute(DIR_RESPALDOS + "/" + str(viejos.pop_front()))


func cargar_guardado() -> void:
	var p := leer_proyecto(GUARDADO)
	if p.is_empty():
		p = leer_proyecto(GUARDADO + ".bak")  # si el principal se dañó, usa la copia
	if p.is_empty():
		p = {"niveles": [normalizar(nivel_inicial())], "reglas": reglas_completas({})}
	niveles = p["niveles"]
	reglas = p["reglas"]
	idx = 0
	nivel = niveles[0].duplicate(true)
	_actual = JSON.stringify(nivel)
	for n in niveles:
		for it in n["items"]:
			var num := int(str(it["id"]).substr(1))
			if num >= _contador:
				_contador = num + 1


# ---------------------------------------------------------------- objetos
const CAPAS := {"deco": 0, "plat": 1, "spike": 2, "spring": 2, "valla": 2, "pared": 2, "viga": 2, "coin": 3, "star": 3, "gem": 3, "goal": 3, "enemy": 3, "player": 4}

# Modo 3D (corredor): la pista se ve desde arriba; el corredor avanza hacia la derecha.
# Tres carriles: arriba = izquierda, centro, abajo = derecha.
const CARRILES := [3, 6, 9]
const TIPOS_PISTA := ["coin", "star", "gem", "valla", "pared", "viga", "goal"]


## En modo 3D hay dos tipos de juego: "corredor" (3 carriles) y "aventura" (caminar libre).
func tipo_3d() -> String:
	return str(nivel.get("tipo", "corredor"))


func es_corredor() -> bool:
	return es_3d() and tipo_3d() == "corredor"


func es_3d() -> bool:
	return str(nivel.get("modo", "2d")) == "3d"


func a_carril(cy: int) -> int:
	var mejor := 0
	for i in 3:
		if absi(cy - CARRILES[i]) < absi(cy - CARRILES[mejor]):
			mejor = i
	return mejor


func fila_de_carril(i: int) -> int:
	return CARRILES[clampi(i, 0, 2)]


func capa(it: Dictionary) -> int:
	return CAPAS.get(it["t"], 3)


## Rectángulo del objeto en celdas (para tocar/seleccionar).
func caja_de(it: Dictionary) -> Rect2:
	if it["t"] == "plat":
		return Rect2(it["x"], it["y"], it["w"], it["h"])
	if it["t"] == "deco" and int(it.get("s", 0)) >= 60:
		var alto := int(ceil(float(it["s"]) / 48.0 - 0.01))
		var ancho := maxi(1, int(ceil(float(it["s"]) / 48.0 * 0.6)))
		return Rect2(it["x"] - (ancho - 1) / 2, it["y"] - (alto - 1), ancho, alto)
	return Rect2(it["x"], it["y"], 1, 1)


func objeto_en(celda: Vector2) -> Variant:
	var mejor: Variant = null
	var mejor_capa := -1
	for it in nivel["items"]:
		if caja_de(it).has_point(celda) and capa(it) >= mejor_capa:
			mejor = it
			mejor_capa = capa(it)
	return mejor


func quitar(it: Dictionary) -> void:
	nivel["items"].erase(it)


## Coloca un objeto de la biblioteca. Devuelve el objeto creado o movido.
func colocar(def: Dictionary, cx: int, cy: int) -> Dictionary:
	cx = clampi(cx, 0, nivel["cols"] - 1)
	cy = clampi(cy, 0, FILAS - 1)
	var t: String = def["t"]
	if es_corredor() and TIPOS_PISTA.has(t):
		cy = fila_de_carril(a_carril(cy))
	if t == "hero":
		nivel["hero"] = def["e"]
		t = "player"
	if t == "player" or t == "goal":
		for it in nivel["items"]:
			if it["t"] == t:
				it["x"] = cx
				it["y"] = cy
				return it
	var o: Dictionary = {"t": t, "x": cx, "y": cy, "id": nuevo_id()}
	match t:
		"plat":
			o["w"] = mini(3, nivel["cols"] - cx)
			o["h"] = 1
		"enemy":
			o["e"] = def["e"]
			o["r"] = 3
			o["sp"] = int(def.get("sp", 60))
			o["fly"] = bool(def.get("fly", false))
		"deco":
			o["e"] = def["e"]
			o["s"] = int(def.get("s", 56))
	nivel["items"].append(o)
	return o


## Proyecto «Dino Run»: 5 mundos de corredor con dinosaurios 3D animados.
func proyecto_dinorun() -> Dictionary:
	var mundos := [
		["Jungla", "bosque", "g:chilesaurus.glb", 60, 1],
		["Desierto de los fósiles", "desierto", "g:atacamatitan.glb", 64, 2],
		["Cordillera del hielo", "nieve", "g:stegouros.glb", 68, 3],
		["Pantano de las luciérnagas", "pantano", "g:arackar.glb", 72, 4],
		["Valle de los titanes", "valle", "g:gonkoken.glb", 80, 5],
	]
	var lista: Array = []
	for k in mundos.size():
		var m: Array = mundos[k]
		var rng := RandomNumberGenerator.new()
		rng.seed = 1000 + k
		var items: Array = []
		var n := 0
		var cols: int = m[3]
		var dificultad: int = m[4]
		var x := 6
		while x < cols - 8:
			var c := rng.randi_range(0, 2)
			var r := rng.randf()
			# huevos en fila
			if r < 0.45:
				for j in 4:
					n += 1
					items.append({"id": "d%d_%d" % [k, n], "t": "coin", "x": x + j, "y": CARRILES[c]})
			# obstáculos (más cuanto más difícil)
			var tipo: String = ["valla", "pared", "viga"][rng.randi_range(0, 2)]
			n += 1
			items.append({"id": "d%d_%d" % [k, n], "t": tipo, "x": x + 5, "y": CARRILES[c]})
			if tipo == "pared" and rng.randf() < 0.3 + 0.1 * dificultad:
				var c2 := (c + 1) % 3
				n += 1
				items.append({"id": "d%d_%d" % [k, n], "t": "pared", "x": x + 5, "y": CARRILES[c2]})
			if rng.randf() < 0.18:
				n += 1
				items.append({"id": "d%d_%d" % [k, n], "t": "gem", "x": x + 8, "y": CARRILES[rng.randi_range(0, 2)]})
			x += maxi(6, 11 - dificultad)
		n += 1
		items.append({"id": "d%d_%d" % [k, n], "t": "star", "x": cols - 12, "y": CARRILES[1]})
		n += 1
		items.append({"id": "d%d_%d" % [k, n], "t": "goal", "x": cols - 4, "y": CARRILES[1]})
		lista.append({"name": m[0], "modo": "3d", "tipo": "corredor", "disp": "pc", "orient": "horizontal",
			"theme": m[1], "hero": m[2], "cols": cols, "rows": FILAS, "items": items})
	var reglas := REGLAS_BASE.duplicate(true)
	reglas["vidas"] = 3
	reglas["titulo"] = true
	reglas["final"] = "¡Completaste Dino Run!"
	reglas["mascota"] = ""
	reglas["poder"] = "escudo"
	reglas["tienda"] = true
	reglas["jugadores"] = 1
	reglas["heroe2"] = "g:gonkoken.glb"
	reglas["pts_coin"] = 10
	reglas["pts_gem"] = 50
	reglas["pts_star"] = 100
	# Personajes jugables: los 5 dinosaurios chilenos, cada uno con su habilidad original.
	reglas["jugables"] = [
		{"id": "g:chilesaurus.glb", "n": "Chilesaurus", "poder": "salto15", "desc": "Chilesaurus diegosuarezi · salta más alto"},
		{"id": "g:atacamatitan.glb", "n": "Atacamatitán", "poder": "huevos20", "desc": "Atacamatitan chilensis · la comida vale +20%"},
		{"id": "g:arackar.glb", "n": "Arackar", "poder": "vida", "desc": "Arackar licanantay · empiezas con 4 vidas"},
		{"id": "g:stegouros.glb", "n": "Stegouros", "poder": "inv26", "desc": "Stegouros elengassen · 2,6 s de protección tras un golpe"},
		{"id": "g:gonkoken.glb", "n": "Gonkoken", "poder": "salto15", "desc": "Gonkoken nanoi · salta más alto y ágil"},
	]
	# Las 15 mascotas de la tienda (ninguna es dinosaurio chileno), con su precio y poder originales.
	var pets := [
		["g:pterodactylus.glb", "Pteranodón", 600, "escudo", "Empiezas con escudo"],
		["g:triceratops.glb", "Triceratops", 750, "comida25", "La comida vale +25%"],
		["a:d_velociraptor", "Velociraptor", 900, "doble12", "Doble puntos al empezar (12 s)"],
		["a:d_dilofosaurio", "Dilofosaurio", 1050, "iman8", "Imán de monedas al empezar (8 s)"],
		["a:d_iguanodon", "Iguanodón", 1200, "huevos10", "Los huevos valen +10%"],
		["g:stegosaurus.glb", "Estegosaurio", 1350, "escudo", "Absorbe 1 golpe por carrera"],
		["a:d_parasaurolophus", "Parasaurolophus", 1500, "iman12", "Imán de huevos +4 s"],
		["g:pachycephalosaurus.glb", "Pachycephalosaurus (Mini)", 1800, "rompe", "Rompe 1 obstáculo por carrera"],
		["g:ankylosaurus.glb", "Anquilosaurio", 2400, "vida", "+1 vida al empezar"],
		["a:d_apatosaurio", "Apatosaurio", 3000, "fosiles", "Los fósiles dan el doble de puntos"],
		["g:spinosaurus.glb", "Espinosaurio", 4200, "lento30", "Enemigos 30% más lentos"],
		["g:trex.glb", "Tyrannosaurus Rex (Mini)", 5400, "monedas25", "+25% monedas por carrera"],
		["g:oviraptor.glb", "Oviraptor", 2700, "huevos20", "Los huevos valen +20%"],
		["g:carnotaurus.glb", "Carnotaurio", 4800, "lento15", "Enemigos 15% más lentos y +15% monedas"],
		["g:plesiosaurus.glb", "Plesiosaurio", 3600, "escudo_h10", "Absorbe 1 golpe y los huevos valen +10%"],
	]
	var cat: Array = []
	for p in pets:
		cat.append({"id": p[0], "n": p[1], "precio": p[2], "poder": p[3], "desc": p[4]})
	reglas["catalogo"] = cat
	var niveles: Array = []
	for l in lista:
		niveles.append(normalizar(l))
	return {"v": 2, "reglas": reglas, "niveles": niveles}
