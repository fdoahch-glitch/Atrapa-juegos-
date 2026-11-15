extends Node
const Partida := preload("res://scripts/partida.gd")
const Tienda := preload("res://scripts/tienda.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("  ok  " if c else "  MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	DirAccess.remove_absolute(Tienda.RUTA)
	var p := Datos.proyecto_dinorun()
	var r := Datos.reglas_completas(p["reglas"])
	for it in r["catalogo"]:
		DirAccess.remove_absolute(Importar_ruta(it["id"]))
		await preload("res://scripts/importar.gd").hacer_miniatura(get_tree(), it["id"])
	ok(r["tienda"] and r["catalogo"].size() == 15 and r["jugables"].size() == 5, "15 mascotas y 5 dinosaurios jugables")
	ok(Tienda.leer()["monedas"] == 0, "empieza sin monedas")
	ok(not Tienda.comprar(r["catalogo"][0]), "sin monedas no compra")
	Tienda.ganar(650)
	ok(Tienda.comprar(r["catalogo"][0]) and Tienda.leer()["monedas"] == 50, "compra la 1ª (600 monedas)")
	ok(Tienda.leer()["elegida"] == r["catalogo"][0]["id"], "queda elegida")
	ok(not Tienda.comprar(r["catalogo"][2]), "la 3ª cuesta 900: no alcanza")
	Tienda.elegir(r["catalogo"][0]["id"])
	var rr := Tienda.reglas_con_mascota(r)
	ok(rr["mascota"] == r["catalogo"][0]["id"] and rr["poder"] == r["catalogo"][0]["poder"], "la mascota elegida entra al juego")
	Tienda.elegir_personaje(r["jugables"][2]["id"])
	ok(Tienda.personaje(r)["id"] == r["jugables"][2]["id"] and Tienda.reglas_con_mascota(r)["poder_heroe"] == "vida", "personaje jugable elegido y su habilidad")
	p["reglas"] = r
	var pa: Control = Partida.new()
	add_child(pa)
	pa.size = Vector2(1280, 720)
	pa.iniciar(p, 0, true, false, false)
	for f in 4:
		await get_tree().process_frame
	ok(pa._titulo != null, "título con botón de tienda")
	pa._mostrar_tienda()
	for f in 4:
		await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/dino/tienda.png")
	pa._empezar(0)
	for f in 3:
		await get_tree().process_frame
	ok(pa._juego._tiene_mascota() and pa._juego._escudos >= 0, "partida con mascota elegida")
	var j = pa._juego
	j.puntos = 12
	j.estado = "gano"
	j._mostrar_fin("🎉", "x", "y")
	await get_tree().process_frame
	ok(Tienda.leer()["monedas"] > 50, "al terminar el nivel suma monedas: %d" % Tienda.leer()["monedas"])
	DirAccess.remove_absolute(Tienda.RUTA)
	print("FALLOS: ", fallos)
	get_tree().quit(fallos)

func Importar_ruta(id: String) -> String:
	return preload("res://scripts/importar.gd").ruta_dibujo(id)
