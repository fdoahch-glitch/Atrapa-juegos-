extends Node
const JD := preload("res://scripts/juego_disparos.gd")
const J := preload("res://scripts/juego.gd")
const Part := preload("res://scripts/partida.gd")
const Rec := preload("res://scripts/recetas.gd")
const Cat := preload("res://scripts/categorias.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("  ok  " if c else "  MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	var n := Datos.nivel_arriba()
	n["estilo"] = "disparos"
	n = Datos.normalizar(n)
	ok(str(n.get("estilo", "")) == "disparos", "estilo disparos se conserva")
	ok(Part.clase_para(n) == JD, "clase de disparos")
	var j: Control = JD.new()
	add_child(j)
	j.size = Vector2(1280, 720)
	j.iniciar(n, false, false)
	var e0: int = j.enemigos.size()
	j._apunta = Vector2(1, 0)
	j._disparar(Vector2(1, 0))
	ok(j.balas.size() == 1, "dispara una bala")
	for i in 60: j._actualizar(1.0 / 60.0)
	ok(j.balas.size() == 0, "la bala termina")
	# matar enemigo: ponerlo frente
	if e0 > 0:
		var e: Dictionary = j.enemigos[0]
		j.balas = [{"p": Vector2((e["x"] + 0.5) * 48.0 - 30.0, (e["y"] + 0.5) * 48.0), "d": Vector2(1, 0), "r": 0.0}]
		var p0: int = j.puntos
		for i in 40: j._actualizar(1.0 / 60.0)
		ok(j.puntos > p0 and j.enemigos.size() < e0, "bala puede eliminar enemigo (%d -> %d)" % [e0, j.enemigos.size()])
	# corredor 2D
	var c := Datos.normalizar(Datos.nivel_corredor2d())
	ok(bool(c.get("autocorrer", false)), "corredor2d autocorrer")
	var k: Control = J.new()
	add_child(k)
	k.size = Vector2(1280, 720)
	k.iniciar(c, false, false)
	var x0: float = k.pos.x
	for i in 300: k._actualizar(1.0 / 60.0)
	ok(k.pos.x > x0 + 150.0, "avanza solo (%.1f -> %.1f)" % [x0, k.pos.x])
	# recetas y categorías
	for cat in Cat.CATEGORIAS:
		var ps := Rec.pasos(cat["id"])
		ok(ps.size() >= 5, "receta %s (%d pasos)" % [cat["id"], ps.size()])
	ok(Cat.categoria("disparos").has("tipos"), "categoría disparos")
	var Id := load("res://scripts/idea.gd")
	var r1: Dictionary = Id.recomendar("un juego de celular tipo Run pero en 2D con dinosaurios")
	ok(r1["tipo"] == "corredor2d" and r1["ok"], "idea: Run 2D -> corredor2d")
	var r2: Dictionary = Id.recomendar("quiero un shooter con armas")
	ok(r2["cat"] == "disparos", "idea: shooter")
	ok(not Id.recomendar("hola")["ok"], "idea vaga pide más datos")
	ok(Id.recomendar("quiero un juego de preguntas para el colegio")["tipo"] == "quiz", "idea: quiz")
	ok(Id.recomendar("defensa de torres con oleadas")["tipo"] == "defensa_e", "idea: defensa")
	var ini: Control = load("res://scripts/inicio.gd").new()
	add_child(ini)
	ini.size = Vector2(1280, 720)
	ini._mostrar_idea()
	ok(true, "pantalla idea se construye")
	# armas
	var e2: Control = JD.new()
	add_child(e2)
	e2.size = Vector2(1280, 720)
	var n2 := Datos.normalizar(Datos.nivel_arriba())
	n2["estilo"] = "disparos"
	n2 = Datos.normalizar(n2)
	n2["reglas"] = Datos.reglas_completas({"arma": "escopeta"})
	e2.iniciar(n2, false, false)
	e2._disparar(Vector2(1, 0))
	ok(e2.balas.size() == 5, "escopeta dispara 5 balas (%d)" % e2.balas.size())
	ok(Datos.reglas_completas({"arma": "xx"})["arma"] == "pistola", "arma inválida -> pistola")
	# logros
	var Pg := load("res://scripts/progreso.gd")
	DirAccess.remove_absolute("user://progreso.json")
	var lg: Array = Pg.logros_nuevos({"puntos": 120, "gemas": 0, "monedas": 0}, true, 0)
	ok(lg.size() >= 4, "logros nuevos (%d)" % lg.size())
	ok(Pg.logros_nuevos({"puntos": 120}, true, 0).size() == 0, "logros no se repiten")
	# panel de elementos
	var pe: Control = load("res://scripts/panel_elementos.gd").new()
	pe.size = Vector2(1280, 720)
	add_child(pe)
	ok(pe.get_child_count() > 0, "panel elementos se construye")
	# panel colores con tramos
	var nv := Datos.nivel_corredor()
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(nv)], "reglas": Datos.reglas_completas({})})
	var pc: Control = load("res://scripts/panel_colores.gd").new()
	pc.size = Vector2(1280, 720)
	add_child(pc)
	ok(pc.get_child_count() > 0, "panel colores con curvas se construye")
	print("FALLOS ", fallos)
	get_tree().quit()
