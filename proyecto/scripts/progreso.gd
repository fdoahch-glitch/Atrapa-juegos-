extends RefCounted
## Lo que el jugador va ganando y se guarda en su aparato (user://progreso.json):
## misiones del día, fósiles (gemas) para la bitácora, minutos jugados, récords, skin y accesorios puestos, dificultad.

const RUTA := "user://progreso.json"
const Tienda := preload("res://scripts/tienda.gd")

## Misiones de fábrica (se pueden cambiar con reglas.misiones_lista). tipo: recogidos | puntos | gemas | estrellas | perseguidor | sin_golpes
const MISIONES := [
	{"txt": "Recoge 12 huevos (monedas) en una carrera", "tipo": "recogidos", "valor": 12, "premio": 30},
	{"txt": "Consigue 30 monedas en una carrera", "tipo": "monedas", "valor": 30, "premio": 40},
	{"txt": "Llega a 800 puntos", "tipo": "puntos", "valor": 800, "premio": 50},
	{"txt": "Recoge un fósil (gema)", "tipo": "gemas", "valor": 1, "premio": 30},
	{"txt": "Sobrevive a una persecución", "tipo": "perseguidor", "valor": 1, "premio": 60},
	{"txt": "Recoge una estrella", "tipo": "estrellas", "valor": 1, "premio": 30},
]
const DIFICULTADES := {
	"facil": {"n": "Fácil", "vel": 0.85, "vidas": 1},
	"normal": {"n": "Normal", "vel": 1.0, "vidas": 0},
	"dificil": {"n": "Difícil", "vel": 1.15, "vidas": -1},
	"extrema": {"n": "Extrema", "vel": 1.3, "vidas": -2},
}


static func leer() -> Dictionary:
	var d := {"dificultad": "", "fosiles": 0, "minutos": 0.0, "rank": [], "skin": "", "skins": [], "accesorios": [], "puestos": [], "dia": 0, "hechas": [], "ficha_vista": 0}
	if FileAccess.file_exists(RUTA):
		var r = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
		if r is Dictionary:
			for k in d.keys():
				if r.has(k):
					d[k] = r[k]
	return d


static func guardar(d: Dictionary) -> void:
	var f := FileAccess.open(RUTA + ".tmp", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))
		f.close()
		DirAccess.rename_absolute(RUTA + ".tmp", RUTA)


static func dificultad(reglas: Dictionary) -> String:
	var d := leer()
	if bool(reglas.get("elegir_dificultad", false)) and DIFICULTADES.has(str(d["dificultad"])):
		return str(d["dificultad"])
	return str(reglas.get("dificultad", "normal"))


static func ciclar_dificultad() -> String:
	var d := leer()
	var orden := ["facil", "normal", "dificil", "extrema"]
	var i := orden.find(str(d["dificultad"]) if str(d["dificultad"]) != "" else "normal")
	d["dificultad"] = orden[(i + 1) % orden.size()]
	guardar(d)
	return d["dificultad"]


static func _dia() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)


## Las 3 misiones de hoy (cambian cada día).
static func misiones_hoy(reglas: Dictionary) -> Array:
	var lista: Array = reglas.get("misiones_lista", []) if (reglas.get("misiones_lista", []) as Array).size() > 0 else MISIONES
	var dia := _dia()
	var r: Array = []
	for k in mini(3, lista.size()):
		var m: Dictionary = lista[(dia + k * 2) % lista.size()]
		if not r.any(func(x): return x["txt"] == m["txt"]):
			r.append(m)
	return r


static func hechas_hoy() -> Array:
	var d := leer()
	return d["hechas"] if int(d["dia"]) == _dia() else []


## Al terminar una carrera: cuenta lo logrado. «stats»: {recogidos, monedas, puntos, gemas, estrellas, perseguidor}.
## Devuelve el texto de las misiones cumplidas (y paga el premio).
static func cerrar_carrera(reglas: Dictionary, stats: Dictionary, segundos: float) -> Array:
	var d := leer()
	d["fosiles"] = int(d["fosiles"]) + int(stats.get("gemas", 0))
	d["minutos"] = float(d["minutos"]) + segundos / 60.0
	var cumplidas: Array = []
	if bool(reglas.get("misiones", false)):
		if int(d["dia"]) != _dia():
			d["dia"] = _dia()
			d["hechas"] = []
		for m in misiones_hoy(reglas):
			if (d["hechas"] as Array).has(m["txt"]):
				continue
			var tipo := str(m["tipo"])
			if int(stats.get(tipo, 0)) >= int(m["valor"]):
				(d["hechas"] as Array).append(m["txt"])
				cumplidas.append("%s  (+%d monedas)" % [m["txt"], int(m["premio"])])
				Tienda.ganar(int(m["premio"]))
	guardar(d)
	return cumplidas


static func anotar_record(titulo: String, puntos: int) -> int:
	var d := leer()
	var r: Array = d["rank"]
	r.append({"j": titulo, "p": puntos, "f": Time.get_date_string_from_system()})
	r.sort_custom(func(a, b): return int(a["p"]) > int(b["p"]))
	d["rank"] = r.slice(0, 8)
	guardar(d)
	for i in (d["rank"] as Array).size():
		if int(d["rank"][i]["p"]) == puntos:
			return i + 1
	return 0


static func ficha_abierta(f: Dictionary) -> bool:
	var d := leer()
	return int(d["fosiles"]) >= int(f.get("req", 0)) and float(d["minutos"]) >= float(f.get("min", 0))


## Skins y accesorios: se compran en la tienda con las mismas monedas.
static func comprar_extra(clase: String, item: Dictionary) -> bool:
	var d := leer()
	var lista: Array = d[clase]
	if lista.has(item["id"]):
		return true
	var t := Tienda.leer()
	if int(t["monedas"]) < int(item["precio"]):
		return false
	t["monedas"] = int(t["monedas"]) - int(item["precio"])
	Tienda.guardar(t)
	lista.append(item["id"])
	if clase == "skins":
		d["skin"] = item["id"]
	else:
		(d["puestos"] as Array).append(item["id"])
	guardar(d)
	return true


static func poner_skin(id: String) -> void:
	var d := leer()
	d["skin"] = id
	guardar(d)


static func alternar_accesorio(id: String) -> void:
	var d := leer()
	var p: Array = d["puestos"]
	if p.has(id):
		p.erase(id)
	elif (d["accesorios"] as Array).has(id):
		p.append(id)
	guardar(d)


## Modo prueba: todo desbloqueado y monedas de sobra (el progreso real no se borra: se guarda aparte).
static func modo_prueba(reglas: Dictionary) -> void:
	var t := Tienda.leer()
	t["monedas"] = maxi(int(t["monedas"]), 9999)
	for it in reglas.get("catalogo", []):
		if not (t["tengo"] as Array).has(it["id"]):
			(t["tengo"] as Array).append(it["id"])
	Tienda.guardar(t)
	var d := leer()
	d["fosiles"] = maxi(int(d["fosiles"]), 99)
	d["minutos"] = maxf(float(d["minutos"]), 999.0)
	for it in reglas.get("skins", []):
		if not (d["skins"] as Array).has(it["id"]):
			(d["skins"] as Array).append(it["id"])
	for it in reglas.get("accesorios", []):
		if not (d["accesorios"] as Array).has(it["id"]):
			(d["accesorios"] as Array).append(it["id"])
	guardar(d)


static func gastar(cantidad: int) -> bool:
	var t := Tienda.leer()
	if int(t["monedas"]) < cantidad:
		return false
	t["monedas"] = int(t["monedas"]) - cantidad
	Tienda.guardar(t)
	return true
