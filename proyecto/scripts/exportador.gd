extends Node
## "Botón mágico": convierte el juego del niño en una página web, un programa
## de Windows o una app de Android. Por debajo usa Godot en modo silencioso
## (hay que tenerlo instalado una sola vez, con sus plantillas de exportación).

signal terminado(ok: bool, mensaje: String, carpeta: String)

const Rendimiento := preload("res://scripts/rendimiento.gd")
const Importar := preload("res://scripts/importar.gd")
const CONFIG := "user://ajustes.cfg"

var godot_ruta := ""
var _hilo: Thread


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG) == OK:
		godot_ruta = str(cfg.get_value("exportar", "godot", ""))
	if godot_ruta == "" and OS.has_feature("editor"):
		godot_ruta = OS.get_executable_path()   # estamos corriendo desde Godot mismo


func disponible() -> bool:
	return OS.has_feature("windows") or OS.has_feature("linuxbsd") or OS.has_feature("macos")


func tiene_godot() -> bool:
	return godot_ruta != "" and FileAccess.file_exists(godot_ruta)


func guardar_ruta(r: String) -> void:
	godot_ruta = r
	var cfg := ConfigFile.new()
	cfg.load(CONFIG)
	cfg.set_value("exportar", "godot", r)
	cfg.save(CONFIG)


func elegir_godot(al_elegir: Callable) -> void:
	DisplayServer.file_dialog_show("Elige el programa de Godot", "", "", false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, PackedStringArray(["*"]),
		func(ok: bool, rutas: PackedStringArray, _f: int) -> void:
			if ok and rutas.size() > 0:
				guardar_ruta(rutas[0])
				al_elegir.call())


func plantilla_dir() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://plantilla_juego")
	return OS.get_executable_path().get_base_dir().path_join("plantilla_juego")


func carpeta_base() -> String:
	var base := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if base == "" or not DirAccess.dir_exists_absolute(base):
		base = OS.get_environment("USERPROFILE") if OS.has_feature("windows") else OS.get_environment("HOME")
	if base == "":
		base = ProjectSettings.globalize_path("user://")
	return base.path_join("Mis juegos")


func carpeta_salida(nombre: String) -> String:
	return carpeta_base().path_join(_seguro(nombre))


func _seguro(n: String) -> String:
	var r := ""
	var mapa := {"á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "ñ": "n", "ü": "u", "Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ñ": "N"}
	for ch in n.strip_edges():
		var c: String = mapa.get(ch, ch)
		if c.is_valid_identifier() or c.is_valid_int() or c in [" ", "-"]:
			r += c
	r = r.strip_edges().replace(" ", "-")
	return r if r != "" else "mi-juego"


func exportar(plataforma: String, nombre: String, nivel_json: String) -> void:
	if _hilo != null and _hilo.is_started():
		if _hilo.is_alive():
			return  # ya hay una exportación en marcha: no empezar otra encima
		_hilo.wait_to_finish()
	_hilo = Thread.new()
	_hilo.start(_trabajo.bind(plataforma, nombre, nivel_json))


func _exit_tree() -> void:
	if _hilo != null and _hilo.is_started():
		_hilo.wait_to_finish()


func _fin(ok: bool, msg: String, carpeta: String = "") -> void:
	terminado.emit.call_deferred(ok, msg, carpeta)


## Carpeta «motor» junto al programa: trae el motor propio ya compilado
## (plantilla.<plataforma> + juego.pck). Con ella NO hace falta Godot.
func motor_dir() -> String:
	return OS.get_executable_path().get_base_dir().path_join("motor")


func motor_propio(plataforma: String) -> String:
	var ext := {"windows": "plantilla.windows.exe", "linux": "plantilla.linux", "web": "plantilla.web.zip"}
	if not ext.has(plataforma):
		return ""
	var d := motor_dir()
	if FileAccess.file_exists(d.path_join(ext[plataforma])) and FileAccess.file_exists(d.path_join("juego.pck")):
		return d.path_join(ext[plataforma])
	return ""


func _con_motor_propio(plataforma: String, nombre: String, nivel_json: String, plantilla: String) -> void:
	var seguro := _seguro(nombre)
	var salida := carpeta_salida(nombre).path_join(plataforma)
	DirAccess.make_dir_recursive_absolute(salida)
	if plataforma == "web":
		_web_propio(nombre, nivel_json, plantilla, salida)
		return
	var exe := seguro + (".exe" if plataforma == "windows" else "")
	_copiar_archivo(plantilla, salida.path_join(exe))
	_copiar_archivo(motor_dir().path_join("juego.pck"), salida.path_join(seguro + ".pck"))
	var f := FileAccess.open(salida.path_join("nivel.json"), FileAccess.WRITE)
	if f == null:
		_fin(false, "No pude guardar el nivel.")
		return
	f.store_string(nivel_json)
	f.close()
	_copiar_assets(nivel_json, salida)
	var nj = JSON.parse_string(nivel_json)
	if nj is Dictionary and nj.get("reglas") is Dictionary:
		var oc := FileAccess.open(salida.path_join("override.cfg"), FileAccess.WRITE)
		if oc != null:
			oc.store_string(Rendimiento.override_cfg(nj["reglas"].get("rend", {})))
			oc.close()
	if plataforma != "windows":
		OS.execute("chmod", ["+x", salida.path_join(exe)])
	if FileAccess.file_exists(salida.path_join(exe)):
		_fin(true, "¡Listo! Tu juego está en la carpeta «Mis juegos».", salida)
	else:
		_fin(false, "No se pudo crear el juego.")


## Web sin Godot: toma la plantilla web (zip), la renombra a «index» y le agrega
## el juego base (.pck) y el nivel (que la página precarga en el motor).
func _web_propio(nombre: String, nivel_json: String, plantilla: String, salida: String) -> void:
	var z := ZIPReader.new()
	if z.open(plantilla) != OK:
		_fin(false, "No pude abrir la plantilla web.")
		return
	var tam := {}
	var pck := FileAccess.get_file_as_bytes(motor_dir().path_join("juego.pck"))
	tam["index.pck"] = pck.size()
	var html := ""
	for archivo in z.get_files():
		var datos := z.read_file(archivo)
		var destino := archivo.replace("godot.", "index.")
		if archivo == "godot.offline.html" or archivo == "godot.service.worker.js":
			continue
		if archivo == "godot.html":
			html = datos.get_string_from_utf8()
			continue
		if archivo.ends_with(".wasm"):
			tam["index.wasm"] = datos.size()
		var f := FileAccess.open(salida.path_join(destino), FileAccess.WRITE)
		if f:
			f.store_buffer(datos)
	z.close()
	var f2 := FileAccess.open(salida.path_join("index.pck"), FileAccess.WRITE)
	if f2 == null:
		_fin(false, "No pude escribir los archivos del juego. Revisa que la carpeta no esté protegida.")
		return
	f2.store_buffer(pck)
	f2.close()
	var config := {"args": [], "canvasResizePolicy": 2, "ensureCrossOriginIsolationHeaders": false, "executable": "index", "experimentalVK": false, "fileSizes": tam, "focusCanvas": true, "gdextensionLibs": []}
	html = html.replace("$GODOT_PROJECT_NAME", nombre.xml_escape()).replace("$GODOT_SPLASH_COLOR", "#3a2a8a").replace("$GODOT_HEAD_INCLUDE", "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1,user-scalable=no\">").replace("$GODOT_SPLASH_CLASSES", "").replace("$GODOT_SPLASH", "").replace("$GODOT_URL", "index.js").replace("$GODOT_CONFIG", JSON.stringify(config)).replace("$GODOT_THREADS_ENABLED", "false")
	var precarga := "engine.preloadFile('nivel.json', '/nivel.json');\n"
	for n in _copiar_assets(nivel_json, salida):
		precarga += "\t\tengine.preloadFile('assets/%s', '/assets/%s');\n" % [n.uri_encode(), n]
	html = html.replace("engine.startGame({", precarga + "\t\tengine.startGame({")
	var fh := FileAccess.open(salida.path_join("index.html"), FileAccess.WRITE)
	if fh == null:
		_fin(false, "No pude escribir index.html. Revisa que la carpeta no esté protegida.")
		return
	fh.store_string(html)
	fh.close()
	var fn := FileAccess.open(salida.path_join("nivel.json"), FileAccess.WRITE)
	fn.store_string(nivel_json)
	fn.close()
	_fin(true, "¡Listo! Tu juego está en la carpeta «Mis juegos». Súbelo a un sitio web (no se abre con doble clic).", salida)


## Dibujos y modelos propios que usa el nivel: se copian a «assets» junto al juego.
## Devuelve los nombres de archivo copiados.
func _copiar_assets(nivel_json: String, salida: String) -> Array:
	var nv = JSON.parse_string(nivel_json)
	var usados := {}
	var niveles: Array = []
	if nv is Dictionary:
		if nv.has("niveles") and nv["niveles"] is Array:
			niveles = nv["niveles"]
			var rg: Dictionary = nv["reglas"] if nv.get("reglas") is Dictionary else {}
			var por: Dictionary = Datos.portada_normal(rg.get("portada", {}))
			usados[str(por["fondo"])] = true
			for b in por["botones"]:
				usados[str(b["img"])] = true
			for clave in ["musica", "heroe2", "mascota"]:
				if str(rg.get(clave, "")) != "":
					usados[str(rg[clave])] = true
			for lista in ["catalogo", "jugables"]:
				for ci in (rg.get(lista, []) if rg.get(lista, []) is Array else []):
					if ci is Dictionary:
						usados[str(ci.get("id", ""))] = true
		else:
			niveles = [nv]
	for n in niveles:
		if not n is Dictionary:
			continue
		var ids: Array = [str(n.get("hero", "")), str(n.get("fondo", ""))]
		for it in n.get("items", []):
			ids.append(str(it.get("e", "")))
		for id in ids:
			if id.begins_with("u:") or id.begins_with("g:") or id.begins_with("m:"):
				usados[id] = true
	var nombres: Array = []
	for id in usados:
		var origen := Importar.ruta_archivo(id)
		if FileAccess.file_exists(origen):
			DirAccess.make_dir_recursive_absolute(salida.path_join("assets"))
			_copiar_archivo(origen, salida.path_join("assets").path_join(Importar.nombre_de(id)))
			nombres.append(Importar.nombre_de(id))
		if id.begins_with("g:"):  # la miniatura del modelo (tienda, selección de personaje)
			var mini := Importar.ruta_dibujo(id)
			if FileAccess.file_exists(mini):
				DirAccess.make_dir_recursive_absolute(salida.path_join("assets"))
				var nombre_mini := Importar.nombre_de(id) + ".png"
				_copiar_archivo(mini, salida.path_join("assets").path_join(nombre_mini))
				nombres.append(nombre_mini)
	return nombres


func _copiar_archivo(de: String, a: String) -> void:
	var src := FileAccess.open(de, FileAccess.READ)
	if src == null:
		return
	var dst := FileAccess.open(a, FileAccess.WRITE)
	if dst == null:
		return
	while not src.eof_reached():
		dst.store_buffer(src.get_buffer(1048576))


func _trabajo(plataforma: String, nombre: String, nivel_json: String) -> void:
	var propio := motor_propio(plataforma)
	if propio != "":
		_con_motor_propio(plataforma, nombre, nivel_json, propio)
		return
	var origen := plantilla_dir()
	if not DirAccess.dir_exists_absolute(origen):
		_fin(false, "No encuentro la carpeta «plantilla_juego». Debe estar junto al programa del creador.")
		return
	if not tiene_godot():
		_fin(false, "Falta indicar dónde está Godot. Pulsa «Elegir Godot».")
		return
	var seguro := _seguro(nombre)
	var obra := ProjectSettings.globalize_path("user://construccion").path_join(seguro)
	_borrar(obra)
	_copiar(origen, obra)
	var f := FileAccess.open(obra.path_join("nivel.json"), FileAccess.WRITE)
	if f == null:
		_fin(false, "No pude preparar los archivos del juego.")
		return
	f.store_string(nivel_json)
	f.close()
	_poner_nombre(obra.path_join("project.godot"), nombre)
	var salida := carpeta_salida(nombre).path_join(plataforma)
	DirAccess.make_dir_recursive_absolute(salida)
	var archivos := {"web": "index.html", "windows": seguro + ".exe", "android": seguro + ".apk"}
	var presets := {"web": "Web", "windows": "Windows", "android": "Android"}
	var destino: String = salida.path_join(archivos[plataforma])
	var out: Array = []
	OS.execute(godot_ruta, ["--headless", "--path", obra, "--import"], out, true)
	out.clear()
	OS.execute(godot_ruta, ["--headless", "--path", obra, "--export-release", presets[plataforma], destino], out, true)
	var texto := "\n".join(PackedStringArray(out.map(func(x): return str(x))))
	var registro := FileAccess.open("user://ultima_exportacion.log", FileAccess.WRITE)
	if registro:
		registro.store_string(texto)
	if FileAccess.file_exists(destino):
		_copiar_assets(nivel_json, salida)
		_fin(true, "¡Listo! Tu juego está en la carpeta «Mis juegos».", salida)
	elif "no export template" in texto.to_lower() or "missing export template" in texto.to_lower() or "export templates" in texto.to_lower() and "not found" in texto.to_lower():
		_fin(false, "Faltan las plantillas de exportación de Godot.\nEn Godot: Editor → Administrar plantillas de exportación → Descargar e instalar.")
	elif plataforma == "android":
		_fin(false, "Android necesita configurarse una vez en Godot (SDK de Android y llave). Mira la guía LEEME.")
	else:
		_fin(false, "No se pudo exportar. Revisa que Godot y sus plantillas sean de la misma versión.\n" + texto.right(260))


func _poner_nombre(ruta: String, nombre: String) -> void:
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var lineas := txt.split("\n")
	for i in lineas.size():
		if lineas[i].begins_with("config/name="):
			lineas[i] = 'config/name="%s"' % nombre.replace('"', "").replace("\\", "")
	var g := FileAccess.open(ruta, FileAccess.WRITE)
	g.store_string("\n".join(lineas))


func _copiar(de: String, a: String) -> void:
	DirAccess.make_dir_recursive_absolute(a)
	for d in DirAccess.get_directories_at(de):
		if d == ".godot":
			continue
		_copiar(de.path_join(d), a.path_join(d))
	for archivo in DirAccess.get_files_at(de):
		DirAccess.copy_absolute(de.path_join(archivo), a.path_join(archivo))


func _borrar(ruta: String) -> void:
	if not DirAccess.dir_exists_absolute(ruta):
		return
	for d in DirAccess.get_directories_at(ruta):
		_borrar(ruta.path_join(d))
	for f in DirAccess.get_files_at(ruta):
		DirAccess.remove_absolute(ruta.path_join(f))
	DirAccess.remove_absolute(ruta)
