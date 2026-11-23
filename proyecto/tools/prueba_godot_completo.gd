extends Node
const Exp := preload("res://scripts/exportador.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	await get_tree().process_frame
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(Datos.nivel_inicial())], "reglas": Datos.reglas_completas({})})
	var e = Exp.new()
	add_child(e)
	var res := []
	e.terminado.connect(func(o, m, c): res.append([o, m, c]))
	e._proyecto_godot("Prueba Godot Completo", Datos.a_json())
	await get_tree().process_frame
	await get_tree().process_frame
	ok(res.size() == 1 and res[0][0], "el proyecto se exporta: %s" % (res[0][1] if res.size() else "sin respuesta"))
	var dir: String = res[0][2]
	ok(FileAccess.file_exists(dir.path_join("project.godot")), "tiene project.godot")
	ok(FileAccess.file_exists(dir.path_join("nivel.json")), "tiene nivel.json con tu juego")
	ok(DirAccess.dir_exists_absolute(dir.path_join("scripts")), "tiene los scripts editables")
	ok(FileAccess.get_file_as_string(dir.path_join("project.godot")).contains("Prueba Godot Completo"), "lleva el nombre del juego")
	e._borrar(e.carpeta_salida("Prueba Godot Completo"))
	print("FALLOS ", fallos)
	get_tree().quit()
