extends Node
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _ready() -> void:
	Datos.establecer(Datos.normalizar(Datos.nivel_inicial()))
	Datos.convertir_actual("corredor")
	Datos.nuevo_nivel() if Datos.has_method("nuevo_nivel") else null
	var p := Datos.proyecto()
	var tipos := []
	for n in p["niveles"]: tipos.append(Datos.tipo_de(n))
	print(tipos)
	ok(p["niveles"].size() >= 1, "proyecto con niveles")
	ok(FileAccess.file_exists(Datos.GUARDADO), "guardado existe")
	Datos.guardar()
	ok(FileAccess.file_exists(Datos.GUARDADO + ".bak"), "copia .bak creada")
	ok(not FileAccess.file_exists(Datos.GUARDADO + ".tmp"), "sin temporal colgado")
	# dañar el principal: se recupera de la copia
	var f := FileAccess.open(Datos.GUARDADO, FileAccess.WRITE); f.store_string("{roto"); f.close()
	Datos.cargar_guardado()
	ok(Datos.niveles.size() >= 1 and Datos.nivel.has("items"), "recupera desde .bak si el principal se dañó")
	Datos.establecer(Datos.normalizar(Datos.nivel_inicial()))
	ok(DirAccess.dir_exists_absolute(Datos.DIR_RESPALDOS) and DirAccess.get_files_at(Datos.DIR_RESPALDOS).size() >= 1, "respaldo creado al reemplazar")
	# deshacer conserva enteros
	Datos.confirmar()
	var n0: int = Datos.nivel["cols"]
	Datos.nivel["cols"] = n0 + 1
	Datos.confirmar(); Datos.deshacer()
	ok(typeof(Datos.nivel["cols"]) == TYPE_INT and Datos.nivel["cols"] == n0, "deshacer mantiene números enteros")
	print("FALLOS: ", fallos)
	get_tree().quit()
