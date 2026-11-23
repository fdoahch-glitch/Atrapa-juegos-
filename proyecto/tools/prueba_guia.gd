extends Node
const Guia := preload("res://scripts/guia.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	await get_tree().process_frame
	var n: Dictionary = Datos.normalizar(Datos.nivel_inicial())
	n["items"] = [{"t": "player", "x": 2, "y": 8, "id": "a1"}, {"t": "plat", "x": 0, "y": 9, "w": 30, "h": 1, "id": "a2"}, {"t": "goal", "x": 28, "y": 8, "id": "a5"}]
	var reg := Datos.reglas_completas({"plataforma": "web", "portada": {"botones": []}})
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(n)], "reglas": reg})
	ok(Guia.ahora(Datos.proyecto())["abre"] == "portada", "primero: armar la portada")
	Datos.reglas["portada"] = Datos.portada_normal({"botones": [{"txt": "Jugar", "accion": "jugar"}]})
	ok(Guia.ahora(Datos.proyecto())["abre"] == "objetos", "luego: llenar el mundo")
	for k in 7:
		Datos.nivel["items"].append({"t": "coin", "x": 3 + k, "y": 7, "id": "c%d" % k})
	ok(Guia.ahora(Datos.proyecto())["abre"] == "deco", "luego: decorar")
	Datos.nivel["items"].append({"t": "deco", "e": "🌳", "x": 4, "y": 8, "s": 60, "id": "d1"})
	ok(Guia.ahora(Datos.proyecto())["abre"] == "reglas", "luego: música")
	Datos.reglas["musica"] = "alegre"
	var a: Dictionary = Guia.ahora(Datos.proyecto())
	print(a)
	ok(a["abre"] in ["rendimiento", "exportar", ""], "luego: analizar o exportar")
	ok(Guia.tutorial("mundo", "objetos", "web").contains("WebP"), "tutorial según plataforma")
	var Ed = load("res://scripts/editor.gd")
	var e = Ed.new()
	add_child(e)
	e.size = Vector2(1280, 720)
	await get_tree().process_frame
	ok(e._b_ahora != null and e._b_ahora.text.length() > 3, "el editor muestra «Ahora…»: %s" % e._b_ahora.text)
	e._abrir_ahora()
	ok(e._modal != null, "se abre la ayuda")
	print("FALLOS ", fallos)
	get_tree().quit()
