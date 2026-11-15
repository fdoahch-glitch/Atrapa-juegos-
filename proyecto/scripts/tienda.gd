extends RefCounted
## Tienda de mascotas: las monedas que ganas en cada partida se guardan y sirven para
## comprar mascotas con poder. Se guarda en el aparato del jugador (user://tienda.json).

const RUTA := "user://tienda.json"
const PODERES := ["escudo", "vida", "iman", "bono", "escudo2"]
## Efectos de cada poder (de mascotas y de los personajes jugables).
##  esc = golpes que absorbe · vida = vidas extra · iman = imán todo el nivel · iman_s = imán los primeros s segundos
##  doble = puntos dobles los primeros s segundos · coin/gem/star/enemy = multiplica esos puntos · todo = multiplica todo
##  salto = salto más alto · inv = segundos de invulnerabilidad tras un golpe · lento = enemigos más lentos (0.7 = 30% menos)
const EFECTOS := {
	"escudo": {"esc": 1}, "escudo2": {"esc": 2}, "vida": {"vida": 1}, "iman": {"iman": true}, "bono": {"todo": 1.5}, "salto": {"salto": 1.25},
	"comida25": {"coin": 1.25}, "huevos10": {"coin": 1.1}, "huevos20": {"coin": 1.2}, "doble12": {"doble": 12.0},
	"iman8": {"iman_s": 8.0}, "iman12": {"iman_s": 12.0}, "rompe": {"esc": 1}, "fosiles": {"gem": 2.0},
	"lento30": {"lento": 0.7}, "lento15": {"lento": 0.85, "coin": 1.15}, "monedas25": {"coin": 1.25},
	"escudo_h10": {"esc": 1, "coin": 1.1}, "inv26": {"inv": 2.6}, "salto15": {"salto": 1.15},
}
const NOMBRE_PODER := {"comida25": "Comida +25%", "huevos10": "Huevos +10%", "huevos20": "Huevos +20%", "doble12": "Doble puntos al empezar",
	"iman8": "Imán al empezar", "iman12": "Imán de huevos", "rompe": "Rompe 1 obstáculo", "fosiles": "Fósiles x2", "lento30": "Enemigos 30% más lentos",
	"lento15": "Enemigos 15% más lentos y +15% monedas", "monedas25": "+25% monedas", "escudo_h10": "Escudo y huevos +10%", "inv26": "Protección larga", "salto15": "Salto alto",
	"salto": "Salto alto", "escudo": "Escudo", "escudo2": "Doble escudo", "vida": "Vida extra", "iman": "Imán", "bono": "Más puntos"}


static func leer() -> Dictionary:
	var d := {"monedas": 0, "tengo": [], "elegida": "", "personaje": ""}
	if FileAccess.file_exists(RUTA):
		var f := FileAccess.open(RUTA, FileAccess.READ)
		var r = JSON.parse_string(f.get_as_text()) if f else null
		if r is Dictionary:
			d["monedas"] = int(r.get("monedas", 0))
			d["tengo"] = r.get("tengo", []) if r.get("tengo", []) is Array else []
			d["elegida"] = str(r.get("elegida", ""))
			d["personaje"] = str(r.get("personaje", ""))
	return d


static func guardar(d: Dictionary) -> void:
	var f := FileAccess.open(RUTA, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


static func ganar(cantidad: int) -> void:
	if cantidad <= 0:
		return
	var d := leer()
	d["monedas"] = int(d["monedas"]) + cantidad
	guardar(d)


## Arma un catálogo de mascotas con poder a partir de una lista de ids [{id, n}, ...].
static func catalogo_desde(lista: Array, maximo: int = 10) -> Array:
	var r: Array = []
	for i in mini(lista.size(), maximo):
		r.append({"id": str(lista[i]["id"]), "n": str(lista[i].get("n", "Mascota")), "poder": PODERES[i % PODERES.size()], "precio": 10 * (i + 1)})
	return r


## Comprar: devuelve true si alcanzó.
static func comprar(item: Dictionary) -> bool:
	var d := leer()
	if (d["tengo"] as Array).has(item["id"]):
		return true
	if int(d["monedas"]) < int(item["precio"]):
		return false
	d["monedas"] = int(d["monedas"]) - int(item["precio"])
	(d["tengo"] as Array).append(item["id"])
	d["elegida"] = item["id"]
	guardar(d)
	return true


static func elegir(id: String) -> void:
	var d := leer()
	d["elegida"] = id
	guardar(d)


## Las reglas del juego con la mascota que el jugador eligió en la tienda.
static func reglas_con_mascota(reglas: Dictionary) -> Dictionary:
	var r: Dictionary = reglas.duplicate(true)
	var pj := personaje(r)
	if not pj.is_empty():
		r["poder_heroe"] = str(pj.get("poder", ""))
	if not bool(r.get("tienda", false)):
		return r
	var elegida := str(leer()["elegida"])
	for it in r.get("catalogo", []):
		if str(it["id"]) == elegida:
			r["mascota"] = elegida
			r["poder"] = str(it["poder"])
	return r


## El personaje jugable que eligió el jugador (por defecto, el primero).
static func personaje(reglas: Dictionary) -> Dictionary:
	var lista: Array = reglas.get("jugables", [])
	if lista.is_empty():
		return {}
	var id := str(leer().get("personaje", ""))
	for it in lista:
		if str(it["id"]) == id:
			return it
	return lista[0]


static func elegir_personaje(id: String) -> void:
	var d := leer()
	d["personaje"] = id
	guardar(d)
