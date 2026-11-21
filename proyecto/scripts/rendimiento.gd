extends RefCounted
## Rendimiento y calidad (todo gratis y incluido en Godot):
## - perfiles recomendados por plataforma (escalado FSR, MSAA, límite de FPS, motor gráfico),
## - el verificador «Testear», que busca errores del juego y propone cómo arreglarlos.

const ESCALADOS := [["bilinear", "Normal (rápido)"], ["fsr1", "FSR 1 (AMD, nítido y rápido)"], ["fsr2", "FSR 2.2 (AMD, mejor calidad)"]]
const RENDERS := [["compat", "Compatibilidad (funciona en todo)"], ["vulkan", "Vulkan (más bonito, PC)"]]

const PERFILES := {
	"windows": {"nombre": "Windows", "render": "vulkan", "escalado": "fsr2", "escala": 1.0, "msaa": 4, "fps": 60,
		"nota": "Vulkan + FSR 2.2 da la mejor imagen. NVIDIA DLSS no viene incluido en Godot (sólo con complementos de terceros)."},
	"linux": {"nombre": "Linux", "render": "vulkan", "escalado": "fsr2", "escala": 1.0, "msaa": 4, "fps": 60,
		"nota": "Igual que Windows. Necesita una tarjeta gráfica con Vulkan."},
	"android": {"nombre": "Android", "render": "compat", "escalado": "bilinear", "escala": 0.75, "msaa": 0, "fps": 30,
		"nota": "En celulares conviene el motor «Compatibilidad», imagen al 75 % y 30 FPS para que no se caliente."},
	"web": {"nombre": "Navegador", "render": "compat", "escalado": "bilinear", "escala": 0.85, "msaa": 0, "fps": 60,
		"nota": "En internet sólo funciona el motor «Compatibilidad». Usa imágenes WebP para que cargue rápido."},
}


static func recomendado(plataforma: String) -> Dictionary:
	var p: Dictionary = PERFILES.get(plataforma, PERFILES["windows"]).duplicate()
	p.erase("nombre")
	p.erase("nota")
	return p


static func normal(r: Variant) -> Dictionary:
	var d: Dictionary = r if r is Dictionary else {}
	var base := recomendado("windows")
	var esc: Array = ESCALADOS.map(func(a): return a[0])
	var rnd: Array = RENDERS.map(func(a): return a[0])
	return {
		"render": str(d.get("render", base["render"])) if rnd.has(str(d.get("render", base["render"]))) else "compat",
		"escalado": str(d.get("escalado", base["escalado"])) if esc.has(str(d.get("escalado", base["escalado"]))) else "bilinear",
		"escala": clampf(float(d.get("escala", base["escala"])), 0.5, 1.0),
		"msaa": int(d.get("msaa", base["msaa"])) if [0, 2, 4, 8].has(int(d.get("msaa", base["msaa"]))) else 0,
		"fps": int(d.get("fps", base["fps"])) if [30, 60, 120, 0].has(int(d.get("fps", base["fps"]))) else 60,
	}


## Pone la calidad elegida en la ventana del juego. Sólo usa lo que el motor gráfico actual permite.
static func aplicar(vp: Viewport, r: Variant) -> void:
	var c := normal(r)
	var metodo := str(RenderingServer.get_current_rendering_method())
	var modo := 0
	if metodo == "forward_plus":
		modo = {"bilinear": 0, "fsr1": 1, "fsr2": 2}[c["escalado"]]
	elif metodo == "mobile" and c["escalado"] != "bilinear":
		modo = 1
	vp.scaling_3d_mode = modo
	vp.scaling_3d_scale = c["escala"]
	vp.msaa_3d = {0: Viewport.MSAA_DISABLED, 2: Viewport.MSAA_2X, 4: Viewport.MSAA_4X, 8: Viewport.MSAA_8X}[c["msaa"]]
	Engine.max_fps = c["fps"]


## Texto del archivo override.cfg que se pone junto al .exe para elegir el motor gráfico.
static func override_cfg(r: Variant) -> String:
	var c := normal(r)
	var m := "forward_plus" if c["render"] == "vulkan" else "gl_compatibility"
	return "[rendering]\n\nrenderer/rendering_method=\"%s\"\n" % m


# ------------------------------------------------------------------ medición real de FPS
const ARCHIVO_FPS := "user://rendimiento.json"

## Se llama cada cuadro mientras se juega; guarda el promedio y el mínimo de FPS cada 4 segundos.
static func medir(m: Dictionary, dt: float) -> void:
	if dt <= 0.0 or dt > 0.5:
		return   # pausas o cargas: no cuentan
	m["t"] = float(m.get("t", 0.0)) + dt
	m["n"] = int(m.get("n", 0)) + 1
	m["peor"] = maxf(float(m.get("peor", 0.0)), dt)
	if float(m["t"]) >= 4.0:
		var prom := float(m["n"]) / float(m["t"])
		var f := FileAccess.open(ARCHIVO_FPS, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify({"prom": prom, "min": 1.0 / maxf(float(m["peor"]), 0.001), "plataforma": OS.get_name(), "rend": str(RenderingServer.get_current_rendering_method())}))
			f.close()
		m["t"] = 0.0
		m["n"] = 0
		m["peor"] = 0.0


static func ultima_medicion() -> Dictionary:
	if not FileAccess.file_exists(ARCHIVO_FPS):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(ARCHIVO_FPS))
	return d if d is Dictionary else {}


# ------------------------------------------------------------------ verificador
## Cada problema: {nivel, sev: "error"|"aviso"|"consejo", txt, sol, fix: {op, …}}
static func _p(nivel: int, sev: String, txt: String, sol: String, fix: Dictionary) -> Dictionary:
	return {"nivel": nivel, "sev": sev, "txt": txt, "sol": sol, "fix": fix}


static func _bloqueada(plats: Array, c: Vector2i) -> bool:
	var r := Rect2i(c, Vector2i(1, 1))
	for p in plats:
		if p.intersects(r):
			return true
	return false


static func _libre_cerca(plats: Array, cols: int, desde: Vector2i, ocupadas: Dictionary = {}) -> Vector2i:
	for radio in range(0, 14):
		for dx in range(-radio, radio + 1):
			for dy in range(-radio, radio + 1):
				if maxi(absi(dx), absi(dy)) != radio:
					continue
				var c := desde + Vector2i(dx, dy)
				if c.x < 1 or c.y < 1 or c.x >= cols - 1 or c.y >= Datos.FILAS - 1:
					continue
				if not _bloqueada(plats, c) and not ocupadas.has(c):
					return c
	return Vector2i(-1, -1)


static func analizar(p: Dictionary) -> Array:
	var res: Array = []
	var reglas: Dictionary = p["reglas"]
	var plataforma := str(reglas.get("plataforma", "windows"))
	var niveles: Array = p["niveles"]
	var total_obj := 0
	for i in niveles.size():
		var n: Dictionary = niveles[i]
		var cols := int(n.get("cols", 30))
		var tipo := Datos.tipo_de(n)
		var estilo := str(n.get("estilo", ""))
		var items: Array = n.get("items", [])
		total_obj += items.size()
		var plats: Array = []
		var hay_inicio := false
		var hay_meta := false
		var enemigos := 0
		var vistos := {}
		for it in items:
			var t := str(it.get("t", ""))
			if t == "plat":
				plats.append(Rect2i(int(it["x"]), int(it["y"]), maxi(1, int(it.get("w", 1))), maxi(1, int(it.get("h", 1)))))
			elif t == "player":
				hay_inicio = true
			elif t == "goal":
				hay_meta = true
			elif t == "enemy":
				enemigos += 1
		var nom := str(n.get("name", "Mundo %d" % (i + 1)))
		# --- lo básico
		if tipo != "corredor" and not hay_inicio:
			res.append(_p(i, "error", "%s: no hay lugar de inicio. El personaje no sabe dónde aparecer." % nom, "Poner el inicio en un lugar libre.", {"op": "poner", "t": "player"}))
		if not hay_meta and estilo != "pelea":
			res.append(_p(i, "error", "%s: no hay meta. No se puede ganar." % nom, "Poner una meta en un lugar libre del lado derecho.", {"op": "poner", "t": "goal"}))
		if estilo == "pelea" and enemigos == 0:
			res.append(_p(i, "error", "%s: no hay rival para pelear." % nom, "Agregar un rival.", {"op": "poner", "t": "enemy"}))
		if estilo in ["carrera", "kart"] and enemigos == 0:
			res.append(_p(i, "aviso", "%s: corres solo, sin rivales." % nom, "Agregar 3 corredores rivales.", {"op": "rivales"}))
		# --- cosas mal puestas
		var ocupadas := {}
		for it in items:
			var t2 := str(it.get("t", ""))
			var c := Vector2i(int(it.get("x", 0)), int(it.get("y", 0)))
			if t2 in ["coin", "star", "gem", "spike", "spring", "enemy", "goal", "player"]:
				ocupadas[c] = true
		for it in items:
			var t3 := str(it.get("t", ""))
			var c := Vector2i(int(it.get("x", 0)), int(it.get("y", 0)))
			if t3 == "deco":
				continue
			var fuera: bool = c.x < 0 or c.y < 0 or c.x >= cols or c.y >= Datos.FILAS
			if fuera:
				res.append(_p(i, "error", "%s: un objeto (%s) quedó fuera del mundo y no se va a ver." % [nom, t3], "Traerlo adentro del mundo.", {"op": "mover", "id": str(it.get("id", ""))}))
				continue
			if t3 in ["coin", "star", "gem", "spike", "spring", "enemy", "goal", "player"] and tipo != "corredor" and _bloqueada(plats, c):
				res.append(_p(i, "error", "%s: un objeto (%s) está dentro de un muro o bloque: no se va a ver ni se va a poder alcanzar." % [nom, t3], "Moverlo a la casilla libre más cercana.", {"op": "mover", "id": str(it.get("id", ""))}))
				continue
			if t3 in ["coin", "star", "gem"]:
				var clave := "%s:%d,%d" % [t3, c.x, c.y]
				if vistos.has(clave):
					res.append(_p(i, "consejo", "%s: dos %s en el mismo lugar." % [nom, t3], "Borrar el repetido.", {"op": "borrar", "id": str(it.get("id", ""))}))
				vistos[clave] = true
		# --- alcanzables (vista desde arriba y carreras)
		if tipo in ["arriba"] and hay_inicio:
			var ini := Vector2i(2, 6)
			for it in items:
				if it.get("t", "") == "player":
					ini = Vector2i(int(it["x"]), int(it["y"]))
			var alcanza := _inundar(plats, cols, ini)
			for it in items:
				var tt := str(it.get("t", ""))
				if tt in ["goal", "coin", "star", "gem"]:
					var c := Vector2i(int(it.get("x", 0)), int(it.get("y", 0)))
					if c.x >= 0 and c.y >= 0 and c.x < cols and c.y < Datos.FILAS and not _bloqueada(plats, c) and not alcanza.has(c):
						res.append(_p(i, "error" if tt == "goal" else "aviso", "%s: %s encerrado, no hay camino hasta ahí." % [nom, "la meta quedó" if tt == "goal" else "un premio quedó"], "Moverlo a una zona a la que sí se llega.", {"op": "mover_alcanzable", "id": str(it.get("id", ""))}))
		# --- peso del mundo
		var pesados := 0
		for it in items:
			if str(it.get("e", "")).begins_with("g:") or str(it.get("e", "")).begins_with("a:"):
				pesados += 1
		if items.size() > 450:
			res.append(_p(i, "aviso", "%s: tiene %d objetos. En celulares y navegadores puede ir lento (bajo de 30 FPS)." % [nom, items.size()], "Bajar la calidad (imagen al 75 %% y menos FPS).", {"op": "calidad", "perfil": "android"}))
		elif n.get("modo", "2d") == "3d" and pesados > 60 and plataforma in ["android", "web"]:
			res.append(_p(i, "aviso", "%s: %d modelos 3D. Detectamos que en %s los cuadros por segundo pueden bajar." % [nom, pesados, PERFILES[plataforma]["nombre"]], "Usar el perfil recomendado para %s." % PERFILES[plataforma]["nombre"], {"op": "calidad", "perfil": plataforma}))
		# --- imágenes pesadas
		for clave in ["fondo"]:
			var im := str(n.get(clave, ""))
			var peso := _peso_mb(im)
			if peso > 2.0:
				res.append(_p(i, "aviso", "%s: el fondo pesa %.1f MB. Tarda en cargar." % [nom, peso], "Convertirlo a WebP (mucho más liviano).", {"op": "webp", "id": im, "donde": "fondo", "nivel": i}))
	# --- portada
	var por: Dictionary = Datos.portada_normal(reglas.get("portada", {}))
	if (por["botones"] as Array).is_empty():
		res.append(_p(-1, "aviso", "La portada no tiene botones: nadie podría empezar el juego.", "Agregar un botón «Jugar».", {"op": "boton_jugar"}))
	else:
		var hay_jugar := false
		for b in por["botones"]:
			if str(b["accion"]) in ["jugar", "personajes"] or str(b["accion"]).begins_with("mundo:"):
				hay_jugar = true
		if not hay_jugar:
			res.append(_p(-1, "error", "Ningún botón de la portada empieza el juego.", "Agregar un botón «Jugar».", {"op": "boton_jugar"}))
	var pf := str(por.get("fondo", ""))
	if _peso_mb(pf) > 2.0:
		res.append(_p(-1, "aviso", "El fondo de la portada pesa %.1f MB." % _peso_mb(pf), "Convertirlo a WebP.", {"op": "webp", "id": pf, "donde": "portada"}))
	# --- calidad según plataforma
	var rend: Dictionary = normal(reglas.get("rend", {}))
	var rec := recomendado(plataforma)
	if plataforma == "android" and (rend["msaa"] > 2 or rend["escala"] > 0.85):
		res.append(_p(-1, "aviso", "Para Android tienes la calidad muy alta (puede calentar el celular y gastar batería).", "Aplicar el perfil recomendado para Android.", {"op": "calidad", "perfil": "android"}))
	if plataforma in ["windows", "linux"] and rend["render"] == "compat" and rend["escalado"] != "bilinear":
		res.append(_p(-1, "consejo", "FSR sólo funciona con el motor Vulkan; con «Compatibilidad» no se nota.", "Elegir Vulkan para PC.", {"op": "calidad", "perfil": plataforma}))
	if total_obj > 1500 and plataforma != "windows":
		res.append(_p(-1, "consejo", "Tu juego completo tiene muchos objetos (%d)." % total_obj, "Aplicar el perfil recomendado.", {"op": "calidad", "perfil": plataforma}))
	var med := ultima_medicion()
	if not med.is_empty() and float(med.get("prom", 60.0)) < 30.0:
		res.append(_p(-1, "aviso", "En tu última prueba el juego iba a %.0f FPS en promedio (se siente lento)." % float(med["prom"]), "Bajar la calidad: imagen al 75 %% y sin bordes suaves.", {"op": "calidad", "perfil": "android"}))
	elif not med.is_empty() and float(med.get("min", 60.0)) < 20.0:
		res.append(_p(-1, "consejo", "Hubo tirones (bajó hasta %.0f FPS) en tu última prueba." % float(med["min"]), "Usar el perfil recomendado para tu plataforma.", {"op": "calidad", "perfil": plataforma}))
	return res


static func _peso_mb(id: String) -> float:
	if id == "" or not (id.begins_with("u:")):
		return 0.0
	var ruta := Importar.ruta_archivo(id)
	if not FileAccess.file_exists(ruta) or ruta.get_extension().to_lower() == "webp":
		return 0.0
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		return 0.0
	return float(f.get_length()) / 1048576.0


static func _inundar(plats: Array, cols: int, ini: Vector2i) -> Dictionary:
	var vis := {ini: true}
	var cola: Array = [ini]
	var k := 0
	while k < cola.size():
		var c: Vector2i = cola[k]
		k += 1
		for v in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + v
			if n.x < 0 or n.y < 0 or n.x >= cols or n.y >= Datos.FILAS or vis.has(n) or _bloqueada(plats, n):
				continue
			vis[n] = true
			cola.append(n)
	return vis


## Aplica la corrección de un problema sobre el proyecto actual. Devuelve true si cambió algo.
static func corregir(prob: Dictionary) -> bool:
	var proy := Datos.proyecto()
	var idx_actual := Datos.idx
	var fix: Dictionary = prob["fix"]
	var i: int = prob["nivel"]
	var cambio := false
	var op := str(fix.get("op", ""))
	if op == "calidad":
		proy["reglas"]["rend"] = recomendado(str(fix["perfil"]))
		cambio = true
	elif op == "boton_jugar":
		var por: Dictionary = Datos.portada_normal(proy["reglas"].get("portada", {}))
		por["botones"].append({"txt": "Jugar", "img": "", "x": 0.5, "y": 0.78, "w": 0.42, "h": 0.12, "anim": "latir", "accion": "jugar"})
		proy["reglas"]["portada"] = por
		cambio = true
	elif op == "webp":
		var nuevo: String = PortadaConv.convertir_e_importar(Importar.ruta_archivo(str(fix["id"])), "webp")
		if nuevo != "":
			if str(fix["donde"]) == "portada":
				var por2: Dictionary = Datos.portada_normal(proy["reglas"].get("portada", {}))
				por2["fondo"] = nuevo
				proy["reglas"]["portada"] = por2
			else:
				proy["niveles"][int(fix["nivel"])]["fondo"] = nuevo
			cambio = true
	elif i >= 0 and i < proy["niveles"].size():
		var n: Dictionary = proy["niveles"][i]
		var items: Array = n["items"]
		var cols := int(n.get("cols", 30))
		var plats: Array = []
		for it in items:
			if it.get("t", "") == "plat":
				plats.append(Rect2i(int(it["x"]), int(it["y"]), maxi(1, int(it.get("w", 1))), maxi(1, int(it.get("h", 1)))))
		var ocup := {}
		for it in items:
			ocup[Vector2i(int(it.get("x", 0)), int(it.get("y", 0)))] = true
		match op:
			"poner":
				var t := str(fix["t"])
				var objetivo: Vector2i = {"player": Vector2i(2, 6), "goal": Vector2i(cols - 3, 6), "enemy": Vector2i(cols - 8, 11)}[t]
				var c := _libre_cerca(plats, cols, objetivo, ocup)
				if c.x >= 0:
					var o := {"id": Datos.nuevo_id(), "t": t, "x": c.x, "y": c.y}
					if t == "enemy":
						o.merge({"e": "🦊", "r": 3, "sp": 60, "fly": false})
					items.append(o)
					cambio = true
			"rivales":
				var k := 0
				for e in [["🐶", 2, 8], ["🦊", 3, 10], ["🐼", 6, 10]]:
					var c := _libre_cerca(plats, cols, Vector2i(e[1], e[2]), ocup)
					if c.x >= 0:
						ocup[c] = true
						items.append({"id": Datos.nuevo_id(), "t": "enemy", "x": c.x, "y": c.y, "e": e[0], "r": 3, "sp": 60, "fly": false})
						cambio = true
					k += 1
			"mover", "mover_alcanzable":
				for it in items:
					if str(it.get("id", "")) == str(fix["id"]):
						var c := Vector2i(clampi(int(it.get("x", 1)), 1, cols - 2), clampi(int(it.get("y", 1)), 1, Datos.FILAS - 2))
						var ini := Vector2i(2, 6)
						for q in items:
							if q.get("t", "") == "player":
								ini = Vector2i(int(q["x"]), int(q["y"]))
						if op == "mover_alcanzable":
							var al := _inundar(plats, cols, ini)
							var mejor := Vector2i(-1, -1)
							var md := 1 << 30
							for k2 in al:
								var d := absi(k2.x - c.x) + absi(k2.y - c.y)
								if d < md and not ocup.has(k2):
									md = d
									mejor = k2
							c = mejor
						else:
							c = _libre_cerca(plats, cols, c, ocup)
						if c.x >= 0:
							it["x"] = c.x
							it["y"] = c.y
							cambio = true
			"borrar":
				for k3 in items.size():
					if str(items[k3].get("id", "")) == str(fix["id"]):
						items.remove_at(k3)
						cambio = true
						break
	if cambio:
		Datos.establecer_proyecto(Datos.proyecto_desde(proy))
		Datos.ir_a_nivel(clampi(idx_actual, 0, Datos.num_niveles() - 1))
	return cambio


const PortadaConv := preload("res://scripts/portada_editor.gd")
const Importar := preload("res://scripts/importar.gd")
