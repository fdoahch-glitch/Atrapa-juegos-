extends Node
## Datos del creador (autoload "Datos"): catálogo, temas, nivel actual,
## deshacer/rehacer y guardado. El formato del nivel es el mismo JSON que usa
## la versión web del Atrapa Juegos Studio, así que los niveles son compatibles.

const Importar := preload("res://scripts/importar.gd")
const Assets3D := preload("res://scripts/assets3d.gd")
const Rendimiento := preload("res://scripts/rendimiento.gd")
const Minis := preload("res://scripts/minis.gd")

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

## El tema de un nivel con sus colores propios («paleta») ya aplicados.
## paleta: {"cielo": ["#rrggbb", "#rrggbb"], "lejos": "#..", "cerca": "#..", "plat": ["#.. tierra", "#.. pasto"]}
func tema_de(niv: Dictionary) -> Dictionary:
	var base: Dictionary = temas.get(str(niv.get("theme", "dia")), temas["dia"]).duplicate(true)
	var pal = niv.get("paleta", {})
	if pal is Dictionary and not pal.is_empty():
		if pal.get("cielo") is Array and pal["cielo"].size() >= 2:
			base["cielo"] = [Color(str(pal["cielo"][0])), Color(str(pal["cielo"][1]))]
		for k in ["lejos", "cerca"]:
			if pal.has(k):
				base[k] = Color(str(pal[k]))
		if pal.get("plat") is Array and pal["plat"].size() >= 2:
			base["plat"] = [Color(str(pal["plat"][0])), Color(str(pal["plat"][1]))]
	return base


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
const REGLAS_BASE := {"vidas": 3, "tiempo": 0, "meta": "meta", "pts_coin": 1, "pts_gem": 3, "pts_star": 5, "pts_enemy": 2, "titulo": true, "final": "¡Ganaste el juego!", "musica": "", "mascota": "", "poder": "escudo", "tienda": false, "jugadores": 1, "heroe2": "", "plataforma": "windows", "categoria": "", "subtipo": "", "rend": {}, "dificultad": "normal", "elegir_dificultad": false, "misiones": false, "revivir": 0, "modo_prueba": false, "arma": "pistola", "espera": false, "logros": true, "sin_fin": false, "fis": {}, "mec": {}, "sonidos": {}, "fx": {}, "cam_suave": 100, "cam_temblor": true, "trans": "fundido", "idioma": "es", "creditos": "", "paleta": "", "paleta_fuerza": 80, "paleta_todo": false}
var historial: Array[String] = []
var futuro: Array[String] = []
var _actual := ""
var _cache_tex := {}
var _contador := 1000


func _ready() -> void:
	cargar_guardado()


# ---------------------------------------------------------------- texturas
## Quita los emojis de un texto (la letra del juego no los dibuja y salen como cuadritos). Los emojis van como icono.
func limpiar_emoji(s: String) -> String:
	var r := ""
	for i in s.length():
		var c := s.unicode_at(i)
		if c >= 0x2190 or c == 0xFE0F or c == 0x200D:
			continue
		r += s[i]
	return r.strip_edges()


func _textura_base(e: String) -> Texture2D:
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
			var img: Image = null
			if f.ends_with(".bib"):
				img = Image.new()
				if img.load_png_from_buffer(FileAccess.get_file_as_bytes(f)) != OK:
					img = null
			else:
				img = Image.load_from_file(f)
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
	for k in _cache_pal.keys():
		if str(k).begins_with(e + "|"):
			_cache_pal.erase(k)


# ------------------------------------------------------------ paleta de colores
## Cada paleta: id, nombre y 5 colores de lo más oscuro a lo más claro.
const PALETAS := [
	["desierto", "🏜 Desierto", ["3b2314", "8a4b2a", "c9833f", "e8c78b", "fff1d0"]],
	["nieve", "❄ Nieve", ["1b2a4a", "4a6fa5", "9ec5e8", "dcefff", "ffffff"]],
	["bosque", "🌲 Bosque", ["10281a", "24572f", "4a9a45", "a8d86a", "f2ffd0"]],
	["noche", "🌙 Noche", ["070718", "1c1b4f", "4b3f9e", "8a7bdc", "d9d0ff"]],
	["atardecer", "🌅 Atardecer", ["2a0f3a", "8a2a5a", "e8553a", "ffb347", "fff0c0"]],
	["dulces", "🍬 Dulces", ["5a1a4a", "d6459a", "ff9ad0", "ffd6ec", "fffaf5"]],
	["oceano", "🌊 Océano", ["031a33", "0b4f8a", "1fa3c4", "8fe3e0", "f0ffff"]],
	["volcan", "🌋 Volcán", ["1a0505", "6a1000", "d62e00", "ff9a1f", "ffe9a0"]],
	["gameboy", "🎮 Retro verde", ["0f380f", "306230", "8bac0f", "9bbc0f", "c8e07a"]],
	["bn", "⚫ Blanco y negro", ["000000", "444444", "888888", "cccccc", "ffffff"]],
]
var _cache_pal := {}
var _cache_lut := {}
## Paleta de un objeto puesto en pantalla (la fija Dibujo.objeto mientras dibuja).
var pal_item := ""


func olvidar_texturas_pal() -> void:
	_cache_pal.clear()


func pal_efectiva(del_objeto: String = "") -> String:
	var q := del_objeto
	if q == "no":
		return ""
	if q == "" or not PALETAS.any(func(c): return c[0] == q):
		q = str(reglas.get("paleta", ""))
	return q if PALETAS.any(func(c): return c[0] == q) else ""


func pal_fuerza() -> float:
	return clampf(float(reglas.get("paleta_fuerza", 80)) / 100.0, 0.0, 1.0)


## 256 colores (r, g, b seguidos) que van del oscuro al claro de la paleta.
func pal_lut(id: String) -> PackedByteArray:
	if _cache_lut.has(id):
		return _cache_lut[id]
	var cols: Array = []
	for p in PALETAS:
		if p[0] == id:
			for h in p[2]:
				cols.append(Color(str(h)))
	var lut := PackedByteArray()
	lut.resize(768)
	if cols.is_empty():
		for i in 256:
			lut[i * 3] = i
			lut[i * 3 + 1] = i
			lut[i * 3 + 2] = i
	else:
		for i in 256:
			var t := float(i) / 255.0 * float(cols.size() - 1)
			var k := mini(int(t), cols.size() - 2)
			var c: Color = (cols[k] as Color).lerp(cols[k + 1], t - float(k))
			lut[i * 3] = int(c.r * 255.0)
			lut[i * 3 + 1] = int(c.g * 255.0)
			lut[i * 3 + 2] = int(c.b * 255.0)
	_cache_lut[id] = lut
	return lut


## Pasa los colores de una imagen a la paleta (el brillo manda; `fuerza` 0..1 mezcla con el original).
func pal_imagen(img: Image, id: String, fuerza: float) -> Image:
	var im := img.duplicate() as Image
	if im.is_compressed():
		im.decompress()
	im.convert(Image.FORMAT_RGBA8)
	var d := im.get_data()
	var lut := pal_lut(id)
	var k := int(clampf(fuerza, 0.0, 1.0) * 256.0)
	var n := d.size()
	var i := 0
	while i < n:
		if d[i + 3] > 0:
			var r: int = d[i]
			var g: int = d[i + 1]
			var b: int = d[i + 2]
			var j := ((r * 77 + g * 150 + b * 29) >> 8) * 3
			d[i] = (r * (256 - k) + lut[j] * k) >> 8
			d[i + 1] = (g * (256 - k) + lut[j + 1] * k) >> 8
			d[i + 2] = (b * (256 - k) + lut[j + 2] * k) >> 8
		i += 4
	im.set_data(im.get_width(), im.get_height(), false, Image.FORMAT_RGBA8, d)
	return im


func pal_color(c: Color, id: String, fuerza: float) -> Color:
	var lut := pal_lut(id)
	var j := int(clampf(c.get_luminance(), 0.0, 1.0) * 255.0) * 3
	return c.lerp(Color(lut[j] / 255.0, lut[j + 1] / 255.0, lut[j + 2] / 255.0, c.a), fuerza)


## Cambia los colores de un modelo 3D a la paleta (colores y texturas de sus materiales).
func pal_modelo(raiz: Node, id: String, fuerza: float) -> void:
	var texs := {}
	for m in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(s)
			if not (mat is BaseMaterial3D):
				continue
			var nm := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
			nm.albedo_color = pal_color(nm.albedo_color, id, fuerza)
			var t := nm.albedo_texture
			if t != null:
				var key := t.get_rid().get_id()
				if not texs.has(key):
					var im := t.get_image()
					texs[key] = ImageTexture.create_from_image(pal_imagen(im, id, fuerza)) if im != null else t
				nm.albedo_texture = texs[key]
			mi.set_surface_override_material(s, nm)


func textura(e: String) -> Texture2D:
	var base := _textura_base(e)
	if base == null:
		return null
	var q := pal_efectiva(pal_item)
	if q == "":
		return base
	if base.get_width() * base.get_height() > 1500000:
		return base
	var f := pal_fuerza()
	var key := "%s|%s|%d" % [e, q, int(f * 100.0)]
	if _cache_pal.has(key):
		return _cache_pal[key]
	var img := base.get_image()
	var res: Texture2D = base
	if img != null:
		res = ImageTexture.create_from_image(pal_imagen(img, q, f))
	_cache_pal[key] = res
	return res


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
## Plataformas con tres héroes que se cambian al vuelo (como Trine): caballero, mago y ladrón.
## Une los bloques sueltos (plataformas de 1 celda pintadas) que quedan uno al lado del otro.
func unir_bloques() -> void:
	var por_fila := {}
	var otros: Array = []
	for it in nivel["items"]:
		if it["t"] == "plat" and int(it.get("h", 1)) == 1:
			var y := int(it["y"])
			if not por_fila.has(y):
				por_fila[y] = []
			por_fila[y].append(it)
		else:
			otros.append(it)
	var res: Array = otros
	for y in por_fila.keys():
		var fila: Array = por_fila[y]
		fila.sort_custom(func(a, b): return int(a["x"]) < int(b["x"]))
		var cur: Dictionary = fila[0]
		for i in range(1, fila.size()):
			var sig: Dictionary = fila[i]
			if int(cur["x"]) + int(cur["w"]) >= int(sig["x"]):
				cur["w"] = maxi(int(cur["w"]), int(sig["x"]) + int(sig["w"]) - int(cur["x"]))
			else:
				res.append(cur)
				cur = sig
		res.append(cur)
	nivel["items"] = res


func nivel_trio() -> Dictionary:
	var n := nivel_inicial()
	n["name"] = "Mi trío"
	n["trio"] = true
	n["hero"] = "a:caballero"
	n["cols"] = 40
	var items: Array = n["items"]
	items = items.filter(func(it): return it["t"] != "enemy" and it["t"] != "goal")
	var add := func(o: Dictionary) -> void:
		o["id"] = nuevo_id()
		items.append(o)
	add.call({"t": "plat", "x": 30, "y": 12, "w": 10, "h": 2})
	add.call({"t": "plat", "x": 33, "y": 8, "w": 2, "h": 1})
	add.call({"t": "enemy", "x": 21, "y": 11, "e": "a:slime", "r": 3, "sp": 40, "ia": "patrulla"})
	add.call({"t": "enemy", "x": 27, "y": 11, "e": "a:esqueleto", "r": 2, "sp": 50, "ia": "persigue"})
	add.call({"t": "enemy", "x": 35, "y": 11, "e": "a:esqueleto", "r": 1, "sp": 0, "ia": "dispara"})
	add.call({"t": "star", "x": 33, "y": 7})
	add.call({"t": "goal", "x": 38, "y": 11})
	n["items"] = items
	return n


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


## Circuito de ejemplo: un óvalo con isla central. kart = true añade conos y turbos extra.
func nivel_carrera(kart: bool = false) -> Dictionary:
	var items: Array = []
	var add := func(o: Dictionary) -> void:
		o["id"] = nuevo_id()
		items.append(o)
	for w in [[0, 0, 30, 1], [0, 13, 30, 1], [0, 1, 1, 12], [29, 1, 1, 12], [8, 4, 14, 6]]:
		add.call({"t": "plat", "x": w[0], "y": w[1], "w": w[2], "h": w[3]})
	if kart:
		for w in [[14, 1, 1, 1], [18, 12, 1, 1], [4, 11, 1, 1], [25, 2, 1, 1], [3, 3, 1, 1]]:
			add.call({"t": "plat", "x": w[0], "y": w[1], "w": w[2], "h": w[3]})
	add.call({"t": "goal", "x": 4, "y": 6})
	add.call({"t": "player", "x": 5, "y": 8})
	for r in [[2, 8, "🐶"], [3, 10, "🦊"], [6, 10, "🐼"]]:
		add.call({"t": "enemy", "x": r[0], "y": r[1], "e": r[2], "r": 3, "sp": 60, "fly": false})
	for x in range(10, 21, 2):
		add.call({"t": "coin", "x": x, "y": 2})
	for x in range(10, 21, 2):
		add.call({"t": "coin", "x": x, "y": 11})
	for y in [3, 6, 9]:
		add.call({"t": "coin", "x": 25, "y": y})
	for tp in [[12, 2], [24, 5], [16, 11]] if kart else [[24, 5]]:
		add.call({"t": "spring", "x": tp[0], "y": tp[1]})
	add.call({"t": "spike", "x": 5, "y": 11 if not kart else 12})
	add.call({"t": "spike", "x": 26, "y": 8})
	return {"name": "Mi kart" if kart else "Mi circuito", "modo": "2d", "tipo": "arriba", "estilo": "kart" if kart else "carrera", "vueltas": 3 if kart else 2,
		"theme": "desierto" if kart else "dia", "hero": "🦊" if kart else "🐱", "cols": 30, "rows": FILAS, "items": items}


## Arena de lucha: un suelo largo, tu luchador a la izquierda y el rival a la derecha.
func nivel_pelea(tema: String = "dia") -> Dictionary:
	var items: Array = []
	var add := func(o: Dictionary) -> void:
		o["id"] = nuevo_id()
		items.append(o)
	add.call({"t": "plat", "x": 0, "y": 12, "w": 30, "h": 2})
	add.call({"t": "player", "x": 9, "y": 11})
	add.call({"t": "enemy", "x": 20, "y": 11, "e": "🦊", "r": 3, "sp": 60, "fly": false})
	for d in [["a:arbol", 3, 11, 96], ["a:roca", 14, 11, 64], ["a:pino", 26, 11, 96], ["a:nube", 8, 2, 96], ["a:nube", 21, 3, 96]]:
		add.call({"t": "deco", "e": d[0], "x": d[1], "y": d[2], "s": d[3]})
	return {"name": "Mi lucha", "modo": "2d", "tipo": "plataformas", "estilo": "pelea", "theme": tema, "hero": "🐼", "cols": 30, "rows": FILAS, "items": items}


## Texto corto del estilo de un nivel (Carreras, Go-karts, Lucha…); "" si no tiene.
func nombre_estilo(n: Dictionary) -> String:
	return {"carrera": "Carreras de pista", "kart": "Go-karts", "pelea": "Lucha 2D", "disparos": "Disparos desde arriba", "supervivencia": "Supervivencia", "disparos3d": "Disparos 3D"}.get(str(n.get("estilo", "")), str(Minis.MINIS.get(str(n.get("mini", "")), {}).get("n", "")) if str(n.get("estilo", "")) == "mini" else "")


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


## Corredor 2D lateral: el personaje corre solo hacia la derecha; tú saltas pinchos y enemigos.
func nivel_corredor2d() -> Dictionary:
	var items: Array = []
	var add := func(o: Dictionary) -> void:
		o["id"] = nuevo_id()
		items.append(o)
	add.call({"t": "plat", "x": 0, "y": 12, "w": 90, "h": 2})
	add.call({"t": "player", "x": 1, "y": 11})
	var x := 10
	var k := 0
	while x < 84:
		match k % 4:
			0:
				add.call({"t": "spike", "x": x, "y": 11})
				add.call({"t": "coin", "x": x, "y": 8})
			1:
				add.call({"t": "enemy", "x": x, "y": 11, "e": "🐌", "r": 2, "sp": 40})
			2:
				add.call({"t": "spike", "x": x, "y": 11})
				add.call({"t": "spike", "x": x + 1, "y": 11})
				add.call({"t": "star", "x": x, "y": 7})
			3:
				add.call({"t": "coin", "x": x, "y": 10})
				add.call({"t": "coin", "x": x + 1, "y": 9})
				add.call({"t": "coin", "x": x + 2, "y": 10})
		x += 7
		k += 1
	add.call({"t": "goal", "x": 88, "y": 11})
	for d in [[4, 11, "🌳", 64], [14, 11, "🌸", 34], [30, 11, "🍄", 34], [50, 11, "🌻", 46], [20, 3, "☁️", 70], [60, 2, "☁️", 70]]:
		add.call({"t": "deco", "x": d[0], "y": d[1], "e": d[2], "s": d[3]})
	return {"name": "Mi corredor", "modo": "2d", "tipo": "plataformas", "autocorrer": true, "theme": "dia", "hero": "🐱", "cols": 90, "rows": FILAS, "items": items}


## Minijuego de ejemplo (demo que el creador amplía desde el panel Contenido).
func nivel_mini(id: String) -> Dictionary:
	var m: Dictionary = Minis.MINIS[id]
	var n := nivel_arriba()
	n["items"] = [{"id": nuevo_id(), "t": "player", "x": 2, "y": 6}]
	n["name"] = "Mi " + str(m["n"]).to_lower()
	n["estilo"] = "mini"
	n["mini"] = id
	n["mini_cfg"] = Minis.cfg_base(id)
	n["theme"] = str(m["tema"])
	n["hero"] = str(m["hero"])
	return n


## RPG con personajes que hablan: acércate a ellos para leer su diálogo; recoge tesoros para abrir la meta.
func nivel_rpg() -> Dictionary:
	var n := nivel_arriba()
	n["name"] = "Mi RPG"
	n["theme"] = "bosque"
	n["hero"] = "🧙"
	var items: Array = n["items"]
	for d in [["🧑‍🌾", 3, 3, "Hola, viajero. Los tesoros están al otro lado del laberinto."], ["👸", 8, 10, "Cuidado con los pinchos. Junta todo para abrir la meta."], ["🧙", 14, 3, "Los bichos solo caminan de lado a lado. ¡Cruza rápido!"], ["🐉", 24, 9, "Soy el guardián. ¡Casi llegas!"]]:
		items.append({"id": nuevo_id(), "t": "deco", "e": d[0], "x": d[1], "y": d[2], "s": 52, "dlg": d[3]})
	return n


## Supervivencia: el mapa del laberinto, pero llegan enemigos sin parar. Aguanta el tiempo pedido.
func nivel_supervivencia() -> Dictionary:
	var n := nivel_arriba()
	n["items"] = (n["items"] as Array).filter(func(it): return not (str(it["t"]) in ["enemy", "goal", "spike"]))
	n["items"] = (n["items"] as Array).filter(func(it): return not (str(it["t"]) == "plat" and int(it["h"]) > 1 and int(it["w"]) == 1))
	n["name"] = "Mi supervivencia"
	n["estilo"] = "supervivencia"
	n["aguantar"] = 45
	n["theme"] = "noche"
	n["hero"] = "🤖"
	return n


## Disparos 3D: la aventura 3D con enemigos; disparas hacia donde miras (Espacio / F o toca a la derecha).
func nivel_disparos3d() -> Dictionary:
	var n := nivel_aventura()
	n["name"] = "Mi shooter 3D"
	n["estilo"] = "disparos3d"
	n["camara"] = "tercera"
	n["theme"] = "noche"
	for pos in [[8, 9], [16, 7], [22, 10], [12, 11]]:
		(n["items"] as Array).append({"id": nuevo_id(), "t": "enemy", "x": pos[0], "y": pos[1], "e": "a:esqueleto", "r": 3, "sp": 50, "fly": false})
	return n


## Ciudad abierta: calles, edificios altos y autos que cruzan, para recorrer en 3D.
func nivel_ciudad() -> Dictionary:
	var n := nivel_aventura()
	var items: Array = [{"id": nuevo_id(), "t": "player", "x": 2, "y": 6}, {"id": nuevo_id(), "t": "goal", "x": 27, "y": 6}]
	for b in [[5, 1, 4, 4, 4], [11, 1, 3, 3, 6], [17, 1, 4, 4, 3], [23, 1, 4, 4, 5], [5, 9, 4, 4, 5], [11, 9, 3, 3, 3], [17, 9, 4, 4, 6], [23, 9, 4, 4, 4]]:
		items.append({"id": nuevo_id(), "t": "plat", "x": b[0], "y": b[1], "w": b[2], "h": b[3], "alt": b[4]})
	for c in [[4, 6], [8, 6], [13, 6], [19, 6], [25, 6], [9, 5], [15, 8], [21, 5]]:
		items.append({"id": nuevo_id(), "t": "coin", "x": c[0], "y": c[1]})
	items.append({"id": nuevo_id(), "t": "star", "x": 14, "y": 6})
	items.append({"id": nuevo_id(), "t": "gem", "x": 26, "y": 12})
	for auto in [[9, 6, "🚗"], [18, 6, "🚕"], [24, 6, "🚙"]]:
		items.append({"id": nuevo_id(), "t": "enemy", "x": auto[0], "y": auto[1], "e": auto[2], "r": 5, "sp": 90, "fly": false})
	for d in [["a:farol", 3, 4], ["a:farol", 10, 8], ["a:farol", 16, 4], ["a:farol", 22, 8], ["a:arbol", 8, 3], ["a:arbol", 14, 11], ["a:casa", 28, 2], ["a:casa", 28, 11]]:
		items.append({"id": nuevo_id(), "t": "deco", "e": d[0], "x": d[1], "y": d[2], "s": 96})
	n["items"] = items
	n["name"] = "Mi ciudad"
	n["theme"] = "atardecer"
	n["hero"] = "a:explorador"
	return n


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
	n.erase("estilo")
	n.erase("vueltas")
	n.erase("vista3d")
	n.erase("mini")
	n.erase("mini_cfg")
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
						p["y"] = 10 + int(y) % 2  # a 1 o 2 filas sobre el suelo: se sube de un salto
						p["h"] = 1
						add.call(p)
					elif t in ["coin", "star", "gem"]:
						add.call({"t": t, "x": x, "y": 9 + y % 3})
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
						add.call({"t": t, "x": x, "y": 11 - (2 - a_carril(y))})
					elif t == "valla":
						add.call({"t": "spike", "x": x, "y": 11})
					elif t == "pared":
						add.call({"t": "enemy", "x": x, "y": 11, "e": "🐌", "r": 2, "sp": 40})
					elif t == "deco":
						var d3: Dictionary = it.duplicate(true)
						d3["y"] = 11
						add.call(d3)
			# ningún premio queda dentro de una plataforma ni fuera del alcance de un salto
			for it in salida:
				if not ["coin", "star", "gem"].has(str(it.get("t", ""))):
					continue
				for p2 in salida:
					if str(p2.get("t", "")) == "plat" and int(p2["y"]) < 12 and int(it["x"]) >= int(p2["x"]) and int(it["x"]) < int(p2["x"]) + int(p2["w"]) and int(it["y"]) >= int(p2["y"]) and int(it["y"]) < int(p2["y"]) + int(p2["h"]):
						it["y"] = int(p2["y"]) - 1
				it["y"] = clampi(int(it["y"]), 8, 11)
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
	var est := str(n.get("estilo", ""))
	if not ((est in ["carrera", "kart", "disparos", "supervivencia"] and n["tipo"] == "arriba" and n["modo"] == "2d") or (est == "pelea" and n["tipo"] == "plataformas" and n["modo"] == "2d") \
			or (est == "mini" and n["tipo"] == "arriba" and n["modo"] == "2d" and Minis.existe(str(n.get("mini", "")))) or (est == "disparos3d" and n["tipo"] == "aventura" and n["modo"] == "3d")):
		est = ""
	if est == "mini":
		n["mini_cfg"] = Minis.cfg_limpia(str(n["mini"]), n.get("mini_cfg", {}))
	else:
		n.erase("mini")
		n.erase("mini_cfg")
	if est == "":
		n.erase("estilo")
	else:
		n["estilo"] = est
	if est in ["carrera", "kart"] and bool(n.get("vista3d", false)):
		n["vista3d"] = true
	else:
		n.erase("vista3d")
	if est in ["carrera", "kart"]:
		n["vueltas"] = clampi(int(n.get("vueltas", 3 if est == "kart" else 2)), 1, 9)
	else:
		n.erase("vueltas")
	if not temas.has(str(n.get("theme", "dia"))):
		n["theme"] = "dia"
	n["theme"] = str(n.get("theme", "dia"))
	if not (n.get("paleta") is Dictionary) or (n["paleta"] as Dictionary).is_empty():
		n.erase("paleta")
	else:
		var pal_ok := {}
		for k in ["cielo", "plat"]:
			var l = n["paleta"].get(k)
			if l is Array and l.size() >= 2 and str(l[0]).is_valid_html_color() and str(l[1]).is_valid_html_color():
				pal_ok[k] = [str(l[0]), str(l[1])]
		for k in ["lejos", "cerca"]:
			if str(n["paleta"].get(k, "")).is_valid_html_color():
				pal_ok[k] = str(n["paleta"][k])
		if pal_ok.is_empty():
			n.erase("paleta")
		else:
			n["paleta"] = pal_ok
	if not ["", "ninguno", "lluvia", "tormenta", "nieve", "ventisca", "erupcion", "variable"].has(str(n.get("clima", ""))):
		n["clima"] = ""
	if str(n.get("clima", "")) in ["", "ninguno"]:
		n.erase("clima")
	if not ["", "dia", "atardecer", "noche", "ciclo"].has(str(n.get("hora", ""))) or str(n.get("hora", "")) == "":
		n.erase("hora")
	if bool(n.get("perseguidor", false)):
		n["perseguidor"] = true
	else:
		n.erase("perseguidor")
	if not (n.get("decorado", []) is Array) or (n.get("decorado", []) as Array).is_empty():
		n.erase("decorado")
	else:
		var dl: Array = []
		for d in n["decorado"]:
			if d is Dictionary and str(d.get("e", "")) != "":
				dl.append({"e": str(d["e"]), "alto": clampf(float(d.get("alto", 3.0)), 0.2, 20.0), "dist": d.get("dist", [5.5, 11.0])})
		n["decorado"] = dl
	if not (n.get("obstaculos", {}) is Dictionary) or (n.get("obstaculos", {}) as Dictionary).is_empty():
		n.erase("obstaculos")
	if not (n.get("premios", {}) is Dictionary) or (n.get("premios", {}) as Dictionary).is_empty():
		n.erase("premios")
	if n.has("hero_alto"):
		n["hero_alto"] = clampf(float(n["hero_alto"]), 0.5, 6.0)
		if is_equal_approx(float(n["hero_alto"]), 1.7):
			n.erase("hero_alto")
	var pt: Array = []
	if n.get("pista", []) is Array:
		for tr in n.get("pista", []):
			if tr is Dictionary and tr.get("d", []) is Array and tr["d"].size() == 2:
				var a := clampf(float(tr["d"][0]), 0.0, 99.0)
				var b := clampf(float(tr["d"][1]), a + 1.0, 100.0)
				pt.append({"d": [a, b], "curva": clampf(float(tr.get("curva", 0.0)), -1.0, 1.0), "subida": clampf(float(tr.get("subida", 0.0)), -1.0, 1.0)})
	if pt.is_empty():
		n.erase("pista")
	else:
		n["pista"] = pt
	if bool(n.get("autocorrer", false)):
		n["autocorrer"] = true
	else:
		n.erase("autocorrer")
	if n.has("densidad"):
		n["densidad"] = clampf(float(n["densidad"]), 0.2, 2.5)
		if is_equal_approx(float(n["densidad"]), 1.0):
			n.erase("densidad")
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
		if it.has("fx") and not PART_TIPOS.any(func(c): return c[0] == str(it["fx"])):
			it.erase("fx")
		if it.has("ia") and not COMPORTAMIENTOS.any(func(c): return c[0] == str(it["ia"])):
			it.erase("ia")
		if it.has("pal") and str(it["pal"]) != "no" and not PALETAS.any(func(c): return c[0] == str(it["pal"])):
			it.erase("pal")
		if it.has("anim") and not ANIM_OBJ.any(func(c): return c[0] == str(it["anim"])):
			it.erase("anim")
		if not it.has("id"):
			it["id"] = nuevo_id()
		limpios.append(it)
	n["items"] = limpios
	var evs: Array = []
	if n.get("eventos") is Array:
		for ev in n["eventos"]:
			if ev is Dictionary and EVENTOS_SI.any(func(c): return c[0] == str(ev.get("si", ""))) and EVENTOS_HAZ.any(func(c): return c[0] == str(ev.get("haz", ""))):
				evs.append({"si": str(ev["si"]), "n": clampi(int(ev.get("n", 1)), 1, 9999), "haz": str(ev["haz"]), "txt": str(ev.get("txt", "")).left(80), "v": clampi(int(ev.get("v", 1)), 0, 9999)})
	if evs.is_empty():
		n.erase("eventos")
	else:
		n["eventos"] = evs
	if float(n.get("oscuridad", 0.0)) <= 0.0:
		n.erase("oscuridad")
	else:
		n["oscuridad"] = clampf(float(n["oscuridad"]), 0.0, 0.95)
	if not FILTROS.any(func(c): return c[0] == str(n.get("filtro", ""))) or str(n.get("filtro", "")) == "":
		n.erase("filtro")
	return n


## Reglas con todos los valores presentes (los que falten usan el valor base).
## Física del mundo (plataformas): 1.0 = normal. Cada número multiplica el valor de siempre.
## Sonidos: cada evento del juego usa uno de estos (o un sonido tuyo "m:..."). Vacío = silencio.
const SFX_PRE := {"pip": [880.0, 0.08, "cuadrada"], "moneda": [988.0, 0.1, "triangulo"], "salto": [520.0, 0.12, "cuadrada"], "laser": [1400.0, 0.1, "sierra"],
	"golpe": [150.0, 0.25, "sierra"], "pop": [300.0, 0.12, "seno"], "magia": [1200.0, 0.25, "triangulo"], "victoria": [1000.0, 0.4, "triangulo"], "grave": [110.0, 0.3, "cuadrada"]}
const SFX_NOMBRES := {"": "Silencio", "pip": "Pip", "moneda": "Moneda", "salto": "Salto", "laser": "Láser", "golpe": "Golpe", "pop": "Pop", "magia": "Magia", "victoria": "Victoria", "grave": "Grave"}
const SFX_EVENTOS := [["saltar", "Al saltar", "salto"], ["recoger", "Al recoger un premio", "moneda"], ["pisar", "Al derrotar un enemigo", "pop"], ["golpe", "Al recibir un golpe", "golpe"], ["disparar", "Al disparar", "laser"], ["ganar", "Al ganar", "victoria"], ["perder", "Al perder", "grave"]]
## Partículas: efectos de chispas, humo, fuego…
const PART_TIPOS := [["", "Ninguna"], ["chispas", "Chispas"], ["estrellas", "Estrellas"], ["polvo", "Polvo"], ["humo", "Humo"], ["fuego", "Fuego"], ["nieve", "Nieve"], ["explosion", "Explosión"]]
const FX_EVENTOS := [["recoger", "Al recoger un premio", "chispas"], ["saltar", "Al saltar", ""], ["pisar", "Al derrotar un enemigo", "explosion"], ["golpe", "Al recibir un golpe", "estrellas"]]
## Eventos: «si pasa esto, haz aquello».
const EVENTOS_SI := [["monedas", "Recojo monedas"], ["enemigos", "Derroto enemigos"], ["puntos", "Llego a puntos"], ["tiempo", "Pasan segundos"], ["llave", "Recojo una llave"], ["boton", "Piso un botón"]]
const EVENTOS_HAZ := [["mensaje", "Mostrar un mensaje"], ["puertas", "Abrir las puertas"], ["meta", "Mostrar la meta"], ["vida", "Dar una vida"], ["puntos", "Dar puntos"], ["efecto", "Lanzar partículas"], ["ganar", "Ganar el nivel"], ["perder", "Perder el nivel"]]
const FILTROS := [["", "Ninguno"], ["bn", "Blanco y negro"], ["sepia", "Sepia"], ["retro", "Pixelado retro"], ["vineta", "Viñeta"], ["frio", "Frío"], ["calido", "Cálido"]]
const TRANSICIONES := [["ninguna", "Ninguna"], ["fundido", "Fundido"], ["cortina", "Cortina"]]


func sfx_normal(d: Variant) -> Dictionary:
	var m: Dictionary = d if d is Dictionary else {}
	var o := {}
	for e in SFX_EVENTOS:
		var v := str(m.get(e[0], e[2]))
		o[e[0]] = v if (SFX_NOMBRES.has(v) or v.begins_with("m:")) else e[2]
	return o


func fx_normal(d: Variant) -> Dictionary:
	var m: Dictionary = d if d is Dictionary else {}
	var o := {}
	for e in FX_EVENTOS:
		var v := str(m.get(e[0], e[2]))
		o[e[0]] = v if PART_TIPOS.any(func(p): return p[0] == v) else e[2]
	return o


## Traducción de los textos que trae el programa (los tuyos no se traducen).
const TRAD_RE := [["Recogiste (\\d+) de (\\d+) premios", "You collected $1 of $2 items"], ["Te faltan (\\d+) premios para abrir la meta", "$1 items missing to open the goal"],
	["Te faltaron (\\d+) premios para ganar", "You missed $1 items to win"], ["¡Nivel (\\d+) completado!", "Level $1 complete!"], ["Nivel (\\d+) de (\\d+)", "Level $1 of $2"],
	["Vuelta (\\d+)", "Lap $1"], ["(\\d+) niveles", "$1 levels"], ["Revivir \\((\\d+) monedas\\)", "Revive ($1 coins)"], ["\\+(\\d+) monedas", "+$1 coins"]]
const TRAD := {"¡Jugar!": "Play!", "Jugar otra vez": "Play again", "Siguiente nivel": "Next level", "Reintentar": "Try again", "Volver al inicio": "Back to start", "Editar": "Edit",
	"Elegir personaje": "Choose character", "Tienda de mascotas": "Pet shop", "Misiones del día": "Daily missions", "Bitácora": "Logbook", "Vestuario": "Wardrobe", "Logros": "Achievements",
	"Récords": "Records", "¡Nivel completado!": "Level complete!", "Puntos": "Points", "¡Ups! Se acabaron las vidas": "Oops! You ran out of lives", "¡Se acabó el tiempo!": "Time's up!",
	"¡Llegaste a la meta!": "You reached the goal!", "¡Casi! Faltaron premios": "So close! Items missing", "Continuar": "Continue", "Pausa": "Paused", "Salir": "Quit", "Créditos": "Credits",
	"Volumen": "Volume", "Sonido": "Sound", "¡Puerta abierta!": "Door opened!", "Necesitas una llave": "You need a key", "¡Tienes una llave!": "You got a key!",
	"¡Se abrieron las puertas!": "The doors opened!", "¡Apareció la meta!": "The goal appeared!", "¡Perdiste!": "You lost!", "¡Ganaste el juego!": "You won the game!",
	"Nuevo récord": "New record", "Logro": "Achievement", "Misión cumplida": "Mission complete", "¡Muy bien!": "Well done!", "¡Algo pasó!": "Something happened!"}


func traducir(s: String, idioma: String) -> String:
	if idioma != "en" or s == "":
		return s
	var r := s
	for par in TRAD_RE:
		var re := RegEx.create_from_string(str(par[0]))
		r = re.sub(r, str(par[1]), true)
	var claves: Array = TRAD.keys()
	claves.sort_custom(func(a, b): return str(a).length() > str(b).length())
	for k in claves:
		r = r.replace(str(k), str(TRAD[k]))
	return r


func traducir_arbol(n: Node, idioma: String) -> void:
	if idioma != "en":
		return
	if n is Button:
		(n as Button).text = traducir((n as Button).text, idioma)
	elif n is Label:
		(n as Label).text = traducir((n as Label).text, idioma)
	for c in n.get_children():
		traducir_arbol(c, idioma)


const FIS_BASE := {"grav": 1.0, "salto": 1.0, "vel": 1.0, "friccion": 1.0, "caida": 1.0, "rebote": 0.0}
const FIS_RANGOS := {"grav": [0.3, 2.0], "salto": [0.5, 1.8], "vel": [0.5, 2.0], "friccion": [0.2, 3.0], "caida": [0.4, 2.0], "rebote": [0.0, 0.9]}
const FIS_PRESETS := [["Normal", {}], ["Luna", {"grav": 0.45, "salto": 1.1, "caida": 0.6}], ["Pesado", {"grav": 1.5, "salto": 1.25, "vel": 0.85}], ["Resbaloso", {"friccion": 0.25}], ["Rebotón", {"rebote": 0.7, "salto": 1.1}], ["Veloz", {"vel": 1.6, "friccion": 1.5}]]
## Mecánicas: lo que el personaje sabe hacer. [clave, nombre, explicación, valor de fábrica]
const MEC_LISTA := [
	["pisar", "Pisar enemigos", "Saltar encima de un enemigo lo derrota.", true],
	["doble_salto", "Doble salto", "Salta otra vez en el aire.", false],
	["planear", "Planear", "Mantén el salto al caer y bajas despacio.", false],
	["correr", "Correr", "Mantén Shift para ir más rápido.", false],
	["dash", "Impulso", "Tecla X o K: un empujón rápido hacia adelante.", false],
	["disparar", "Disparar", "Tecla F o J: lanza bolitas que derrotan enemigos.", false],
	["espada", "Espada", "Tecla H: golpea a los enemigos que tienes cerca.", false],
	["conjurar", "Crear bloques", "Tecla G: aparece un bloque para subirte (máximo 3).", false]]
## Cómo se comportan los enemigos.
const COMPORTAMIENTOS := [["patrulla", "Patrulla"], ["vigila", "Vigila"], ["quieto", "Quieto"], ["persigue", "Persigue"], ["salta", "Salta"], ["dispara", "Dispara"]]
## Animación de objetos y personajes del mundo.
const ANIM_OBJ := [["ninguna", "Quieto"], ["flotar", "Flotar"], ["rebotar", "Rebotar"], ["balancear", "Balancear"], ["latir", "Latir"], ["temblar", "Temblar"]]


func fis_normal(f: Variant) -> Dictionary:
	var d: Dictionary = f if f is Dictionary else {}
	var o := FIS_BASE.duplicate()
	for k in FIS_BASE.keys():
		if d.has(k) and (d[k] is float or d[k] is int):
			var r: Array = FIS_RANGOS[k]
			o[k] = clampf(float(d[k]), float(r[0]), float(r[1]))
	return o


func mec_normal(m: Variant) -> Dictionary:
	var d: Dictionary = m if m is Dictionary else {}
	var o := {}
	for x in MEC_LISTA:
		o[x[0]] = bool(d[x[0]]) if d.has(x[0]) else bool(x[3])
	return o


const ANIMACIONES := [["ninguna", "Quieto"], ["flotar", "Flotar"], ["latir", "Latir"], ["balancear", "Balancear"], ["rebotar", "Rebotar"], ["brillar", "Brillar"], ["girar", "Girar"]]
const ACCIONES := [["ninguna", "Nada"], ["jugar", "Jugar"], ["personajes", "Elegir personaje"], ["tienda", "Tienda"], ["salir", "Salir"]]


## La portada de un juego: título, imagen de fondo y botones (con su animación y su acción).
## Las posiciones son fracciones del lienzo (0 a 1), así sirven en cualquier pantalla.
func portada_normal(p: Variant) -> Dictionary:
	var d: Dictionary = p if p is Dictionary else {}
	var o := {"titulo": str(d.get("titulo", "")), "fondo": str(d.get("fondo", "")), "color": str(d.get("color", "#6f4ad8")), "botones": []}
	var anims: Array = []
	for a in ANIMACIONES:
		anims.append(a[0])
	var accs: Array = []
	for a in ACCIONES:
		accs.append(a[0])
	var lista: Array = d.get("botones", []) if d.get("botones", []) is Array else []
	for b in lista:
		if not (b is Dictionary):
			continue
		var accion := str(b.get("accion", "ninguna"))
		if not accs.has(accion) and not accion.begins_with("mundo:"):
			accion = "ninguna"
		o["botones"].append({
			"txt": str(b.get("txt", "")),
			"img": str(b.get("img", "")),
			"x": clampf(float(b.get("x", 0.5)), 0.0, 1.0),
			"y": clampf(float(b.get("y", 0.7)), 0.0, 1.0),
			"w": clampf(float(b.get("w", 0.4)), 0.05, 1.0),
			"h": clampf(float(b.get("h", 0.12)), 0.03, 1.0),
			"anim": str(b.get("anim", "ninguna")) if anims.has(str(b.get("anim", "ninguna"))) else "ninguna",
			"accion": accion,
		})
	return o


func portada_nueva(nombre: String) -> Dictionary:
	return portada_normal({"titulo": nombre, "botones": [{"txt": "Jugar", "x": 0.5, "y": 0.78, "w": 0.42, "h": 0.12, "anim": "latir", "accion": "jugar"}]})


func reglas_completas(r: Dictionary) -> Dictionary:
	var o: Dictionary = REGLAS_BASE.duplicate()
	for k in o.keys():
		if r.has(k):
			var v = r[k]
			if o[k] is bool:
				o[k] = bool(v)
			elif o[k] is String:
				o[k] = str(v)
			elif o[k] is Dictionary:
				pass   # se normaliza más abajo
			else:
				o[k] = int(v)
	o["portada"] = portada_normal(r.get("portada", {}))
	o["sonidos"] = sfx_normal(r.get("sonidos", {}))
	o["fx"] = fx_normal(r.get("fx", {}))
	o["cam_suave"] = clampi(int(o["cam_suave"]), 30, 300)
	o["paleta_fuerza"] = clampi(int(o["paleta_fuerza"]), 0, 100)
	if str(o["paleta"]) != "" and not PALETAS.any(func(q): return q[0] == str(o["paleta"])):
		o["paleta"] = ""
	if not TRANSICIONES.any(func(p): return p[0] == str(o["trans"])):
		o["trans"] = "fundido"
	if not ["es", "en"].has(str(o["idioma"])):
		o["idioma"] = "es"
	o["creditos"] = str(o["creditos"]).left(300)
	o["fis"] = fis_normal(r.get("fis", {}))
	o["mec"] = mec_normal(r.get("mec", {}))
	o["rend"] = Rendimiento.normal(r.get("rend", {}))
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
	if not ["facil", "normal", "dificil", "extrema"].has(str(o["dificultad"])):
		o["dificultad"] = "normal"
	o["revivir"] = clampi(int(o["revivir"]), 0, 9999)
	if not ["pistola", "rafaga", "escopeta", "rifle"].has(str(o["arma"])):
		o["arma"] = "pistola"
	o["espera"] = bool(o["espera"])
	o["logros"] = bool(o["logros"])
	# fichas de colección, skins y accesorios (opcionales)
	var col: Array = []
	for it in (r.get("coleccion", []) if r.get("coleccion", []) is Array else []):
		if it is Dictionary and str(it.get("n", "")) != "":
			col.append({"n": str(it["n"]), "sub": str(it.get("sub", "")), "lineas": (it.get("lineas", []) if it.get("lineas", []) is Array else []).map(func(x): return str(x)),
				"req": clampi(int(it.get("req", 0)), 0, 9999), "min": clampi(int(it.get("min", 0)), 0, 999), "img": str(it.get("img", ""))})
	o["coleccion"] = col
	var skins: Array = []
	for it in (r.get("skins", []) if r.get("skins", []) is Array else []):
		if it is Dictionary and str(it.get("color", "")).is_valid_html_color():
			skins.append({"id": str(it.get("id", it.get("n", "skin"))), "n": str(it.get("n", "Skin")), "color": str(it["color"]), "precio": clampi(int(it.get("precio", 0)), 0, 99999)})
	o["skins"] = skins
	var accs: Array = []
	for it in (r.get("accesorios", []) if r.get("accesorios", []) is Array else []):
		if it is Dictionary and str(it.get("n", "")) != "":
			accs.append({"id": str(it.get("id", it.get("n", "acc"))), "n": str(it["n"]), "emoji": str(it.get("emoji", "🎩")), "lugar": str(it.get("lugar", "cabeza")), "precio": clampi(int(it.get("precio", 0)), 0, 99999)})
	o["accesorios"] = accs
	var mis: Array = []
	for it in (r.get("misiones_lista", []) if r.get("misiones_lista", []) is Array else []):
		if it is Dictionary and str(it.get("txt", "")) != "":
			mis.append({"txt": str(it["txt"]), "tipo": str(it.get("tipo", "recogidos")), "valor": clampi(int(it.get("valor", 1)), 1, 99999), "premio": clampi(int(it.get("premio", 20)), 0, 9999)})
	o["misiones_lista"] = mis
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
		for k in ["name", "modo", "disp", "orient", "tipo", "theme", "hero", "paleta", "clima", "hora", "perseguidor", "densidad", "decorado", "obstaculos", "premios", "autocorrer", "pista", "hero_alto", "mini", "mini_cfg", "camara", "trio", "eventos", "oscuridad", "filtro"]:
			if nivel.has(k) or n.has(k):
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
const CAPAS := {"deco": 0, "plat": 1, "platmov": 1, "caja": 2, "puerta": 2, "boton": 2, "llave": 3, "spike": 2, "spring": 2, "valla": 2, "pared": 2, "viga": 2, "coin": 3, "star": 3, "gem": 3, "goal": 3, "enemy": 3, "player": 4}

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
	if it["t"] == "plat" or it["t"] == "platmov":
		return Rect2(it["x"], it["y"], it.get("w", 3), it.get("h", 1))
	if it["t"] == "puerta":
		return Rect2(it["x"], it["y"], 1, 2)
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
		"platmov":
			o["w"] = mini(3, nivel["cols"] - cx)
			o["h"] = 1
			o["r"] = 3
			o["sp"] = 60
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
