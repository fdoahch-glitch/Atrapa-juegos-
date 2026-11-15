extends Node
const Imp := preload("res://scripts/importar.gd")
func _ready() -> void:
	var g: String = Imp.importar_archivo("/tmp/glb/cubo rosa.glb")
	var f: String = Imp.importar_archivo("/tmp/med/atardecer.png")
	var m: String = Imp.importar_archivo("/tmp/med/musica_test.wav")
	var n: Dictionary = Datos.nivel_arriba()
	n["fondo"] = f
	Datos.establecer(Datos.normalizar(n))
	Datos.agregar_nivel(false)
	Datos.nivel["hero"] = g
	Datos.confirmar()
	Datos.reglas["musica"] = m
	var ex = load("res://scripts/exportador.gd").new()
	DirAccess.make_dir_recursive_absolute("/tmp/ex_out")
	var nombres: Array = ex._copiar_assets(Datos.a_json(), "/tmp/ex_out")
	print("copiados: ", nombres)
	var bien := nombres.size() == 3
	for x in ["cubo_rosa.glb", "atardecer.png", "musica_test.wav"]:
		bien = bien and FileAccess.file_exists("/tmp/ex_out/assets/" + x)
	print("FALLOS: ", 0 if bien else 1)
	get_tree().quit(0 if bien else 1)
