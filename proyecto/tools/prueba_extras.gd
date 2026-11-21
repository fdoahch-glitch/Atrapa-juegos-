extends Node
const Progreso := preload("res://scripts/progreso.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("OK   " if c else "FALLA ") + m)
	if not c: fallos += 1
func _ready() -> void:
	await get_tree().process_frame
	var r := Datos.reglas_completas({"dificultad": "difícil", "misiones": true, "revivir": 50, "coleccion": [{"n": "X", "req": 3}], "skins": [{"id": "r", "n": "Rojo", "color": "#ff0000", "precio": 10}], "accesorios": [{"n": "Gafas", "emoji": "🕶", "lugar": "ojos", "precio": 5}]})
	ok(r["dificultad"] == "normal", "dificultad invalida -> normal")
	ok(r["revivir"] == 50 and r["coleccion"].size() == 1 and r["skins"].size() == 1 and r["accesorios"].size() == 1, "reglas nuevas")
	DirAccess.remove_absolute("user://progreso.json")
	ok(Progreso.misiones_hoy(r).size() == 3, "3 misiones")
	Progreso.modo_prueba(r)
	ok(Progreso.ficha_abierta(r["coleccion"][0]), "ficha abierta en modo prueba")
	var st := Progreso.cerrar_carrera(r, {"recogidos": 99, "monedas": 99, "puntos": 9999, "gemas": 9, "estrellas": 9, "perseguidor": 1}, 60.0)
	ok(st.size() >= 1, "mision cumplida")
	ok(Progreso.anotar_record("t", 500) == 1, "record 1")
	ok(Progreso.comprar_extra("skins", r["skins"][0]), "comprar skin")
	print("FALLOS ", fallos)
	get_tree().quit()
