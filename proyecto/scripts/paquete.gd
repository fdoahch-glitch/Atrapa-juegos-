extends RefCounted
## Guardar y abrir juegos como archivos, y «decompilar» APK de Android.
## - guardar_proyecto: <nombre>.atrapa.json + carpeta assets (modelos, dibujos y sonidos usados).
## - abrir_proyecto: lo contrario; los assets pasan a «Mis cosas».
## - abrir_apk: un APK es un ZIP; se extrae todo, se detecta de qué tipo es (juego web empaquetado con
##   Capacitor/Cordova, Godot, Unity…) y se deja el contenido editable (HTML, imágenes, sonidos) en una carpeta.

const Importar := preload("res://scripts/importar.gd")


# ------------------------------------------------------------------ proyecto
static func ids_usados(proyecto: Dictionary) -> Dictionary:
	var usados := {}
	var rg: Dictionary = proyecto["reglas"] if proyecto.get("reglas") is Dictionary else {}
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
	var niveles: Array = proyecto["niveles"] if proyecto.get("niveles") is Array else []
	for n in niveles:
		if not n is Dictionary:
			continue
		var ids: Array = [str(n.get("hero", "")), str(n.get("fondo", ""))]
		for it in n.get("items", []):
			ids.append(str(it.get("e", "")))
		for id in ids:
			if id.begins_with("u:") or id.begins_with("g:") or id.begins_with("m:"):
				usados[id] = true
	return usados


## Copia a «salida/assets» todo lo que usa el juego. Devuelve los nombres copiados.
static func copiar_assets(proyecto: Dictionary, salida: String) -> Array:
	var nombres: Array = []
	var usados := ids_usados(proyecto)
	for id in usados:
		var origen := Importar.ruta_archivo(id)
		if FileAccess.file_exists(origen):
			DirAccess.make_dir_recursive_absolute(salida.path_join("assets"))
			copiar_archivo(origen, salida.path_join("assets").path_join(Importar.nombre_de(id)))
			nombres.append(Importar.nombre_de(id))
		if id.begins_with("g:"):
			var mini := Importar.ruta_dibujo(id)
			if FileAccess.file_exists(mini):
				DirAccess.make_dir_recursive_absolute(salida.path_join("assets"))
				var nm := Importar.nombre_de(id) + ".png"
				copiar_archivo(mini, salida.path_join("assets").path_join(nm))
				nombres.append(nm)
	return nombres


static func copiar_archivo(de: String, a: String) -> void:
	var src := FileAccess.open(de, FileAccess.READ)
	if src == null:
		return
	var dst := FileAccess.open(a, FileAccess.WRITE)
	if dst == null:
		return
	while not src.eof_reached():
		dst.store_buffer(src.get_buffer(1048576))


static func _seguro(n: String) -> String:
	var r := ""
	for ch in n.strip_edges().to_lower():
		if ch.is_valid_identifier() or ch.is_valid_int() or ch in ["-", " "]:
			r += ch
	r = r.strip_edges().replace(" ", "-")
	return r if r != "" else "mi-juego"


static func guardar_proyecto(carpeta: String, nombre: String) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(carpeta)
	var archivo := carpeta.path_join(_seguro(nombre) + ".atrapa.json")
	var f := FileAccess.open(archivo, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "error": "no puedo escribir en " + carpeta}
	f.store_string(JSON.stringify(Datos.proyecto(), "\t"))
	f.close()
	var n := copiar_assets(Datos.proyecto(), carpeta).size()
	return {"ok": true, "archivo": archivo, "assets": n}


## Los juegos guardados que hay a mano: junto al programa (carpeta «juegos»), en Documentos y en Descargas.
## Cada juego es una carpeta con su «.atrapa.json» y sus «assets».
static func buscar_proyectos() -> Array:
	var raices: Array = []
	var exe := OS.get_executable_path().get_base_dir()
	raices.append(exe.path_join("juegos"))
	raices.append(exe)
	raices.append(OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("Atrapa Juegos"))
	raices.append(OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS))
	raices.append(OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS))
	raices.append("user://juegos")
	var vistos := {}
	var r: Array = []
	for raiz in raices:
		var carpetas: Array = [raiz]
		var d := DirAccess.open(raiz)
		if d == null:
			continue
		for sub in d.get_directories():
			if not sub.begins_with("."):
				carpetas.append(raiz.path_join(sub))
				# un nivel más: «Descargas/Dino-Run-motor-/…» o «juegos/Dino Run/…»
				var d2 := DirAccess.open(raiz.path_join(sub))
				if d2 != null and raiz != OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS) and raiz != OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS):
					for sub2 in d2.get_directories():
						if not sub2.begins_with(".") and sub2 != "assets":
							carpetas.append(raiz.path_join(sub).path_join(sub2))
		for c in carpetas:
			var dc := DirAccess.open(c)
			if dc == null:
				continue
			for f in dc.get_files():
				if f.ends_with(".atrapa.json"):
					var ruta: String = c.path_join(f)
					var real := ProjectSettings.globalize_path(ruta) if ruta.begins_with("user://") else ruta
					if vistos.has(real):
						continue
					vistos[real] = true
					var nombre := f.trim_suffix(".atrapa.json").replace("-", " ").replace("_", " ").capitalize()
					var niv := 0
					var dat = JSON.parse_string(FileAccess.get_file_as_string(ruta))
					if dat is Dictionary:
						var rg = dat.get("reglas", {})
						if rg is Dictionary and str(rg.get("titulo_juego", "")) != "":
							nombre = str(rg["titulo_juego"])
						niv = (dat.get("niveles", []) as Array).size() if dat.get("niveles", []) is Array else 0
					r.append({"nombre": nombre, "ruta": ruta, "mundos": niv})
	return r


static func abrir_proyecto(ruta: String) -> Dictionary:
	var texto := FileAccess.get_file_as_string(ruta)
	if texto == "":
		return {"ok": false, "error": "el archivo está vacío o no se puede leer"}
	var datos = JSON.parse_string(texto)
	if datos == null:
		return {"ok": false, "error": "no es un archivo de juego válido"}
	var assets := ruta.get_base_dir().path_join("assets")
	var traidos := 0
	var da := DirAccess.open(assets)
	if da != null:
		DirAccess.make_dir_recursive_absolute(Importar.CARPETA)
		var indice := Importar.listar_propios()
		var conocidos := {}
		for e in indice:
			conocidos[str(e.get("id", ""))] = true
		for nombre in da.get_files():
			var ext := nombre.get_extension().to_lower()
			var destino := Importar.CARPETA.path_join(nombre)
			copiar_archivo(assets.path_join(nombre), destino)
			traidos += 1
			var tipo := ""
			if ext in ["glb", "gltf"]:
				tipo = "g"
			elif ext in ["ogg", "mp3", "wav"]:
				tipo = "m"
			elif ext in ["png", "jpg", "jpeg", "webp"] and not nombre.to_lower().ends_with(".glb.png"):
				tipo = "u"
			if tipo != "" and not conocidos.has(tipo + ":" + nombre):
				indice.append({"id": tipo + ":" + nombre, "n": nombre.get_basename().left(14)})
				conocidos[tipo + ":" + nombre] = true
		Importar._guardar_indice(indice)
	if not Datos.desde_json(texto):
		return {"ok": false, "error": "el juego tiene un formato que no entiendo"}
	return {"ok": true, "assets": traidos}


# ------------------------------------------------------------------ APK
const TIPOS_WEB := ["assets/public/index.html", "assets/www/index.html", "assets/index.html", "www/index.html"]


static func abrir_apk(ruta: String) -> Dictionary:
	var zip := ZIPReader.new()
	if zip.open(ruta) != OK:
		return {"ok": false, "error": "no es un APK válido (no se puede abrir como ZIP)"}
	var archivos := zip.get_files()
	var nombre := _seguro(ruta.get_file().get_basename())
	var base := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if base == "" or not DirAccess.dir_exists_absolute(base):
		base = ProjectSettings.globalize_path("user://")
	var carpeta := base.path_join("Mis juegos").path_join("APK-" + nombre)
	DirAccess.make_dir_recursive_absolute(carpeta)
	var tamano := 0
	var n_img := 0
	var n_audio := 0
	var n_modelos := 0
	var html := ""
	var tipo := "nativa"
	var tiene_dex := false
	for a in archivos:
		if a.ends_with("/"):
			continue
		var bytes := zip.read_file(a)
		tamano += bytes.size()
		var destino := carpeta.path_join(a)
		DirAccess.make_dir_recursive_absolute(destino.get_base_dir())
		var f := FileAccess.open(destino, FileAccess.WRITE)
		if f:
			f.store_buffer(bytes)
			f.close()
		var l := a.to_lower()
		if l.get_extension() in ["png", "jpg", "jpeg", "webp", "gif", "svg"] and not l.begins_with("res/"):
			n_img += 1
		elif l.get_extension() in ["ogg", "mp3", "wav", "m4a"]:
			n_audio += 1
		elif l.get_extension() in ["glb", "gltf", "obj", "fbx"]:
			n_modelos += 1
		if l.ends_with(".dex"):
			tiene_dex = true
		if html == "" and TIPOS_WEB.has(l):
			html = destino
	var manifiesto := zip.read_file("AndroidManifest.xml")
	var paquete := _paquete_de_manifiesto(manifiesto)
	if html == "":
		for a in archivos:
			if a.to_lower().ends_with("index.html"):
				html = carpeta.path_join(a)
				break
	var junto := " ".join(PackedStringArray(archivos)).to_lower()
	if ".pck" in junto or "libgodot" in junto:
		tipo = "Godot"
	elif "libunity.so" in junto:
		tipo = "Unity"
	elif html != "":
		tipo = "juego web empaquetado (Capacitor / Cordova / WebView)"
	elif "libcocos" in junto:
		tipo = "Cocos"
	zip.close()
	return {"ok": true, "carpeta": carpeta, "tipo": tipo, "html": html, "paquete": paquete,
		"archivos": archivos.size(), "mb": snappedf(tamano / 1048576.0, 0.1), "imagenes": n_img,
		"audios": n_audio, "modelos": n_modelos, "codigo": tiene_dex}


## El manifiesto está en un formato binario (AXML): se buscan los textos UTF-16 con forma de «com.algo.app».
static func _paquete_de_manifiesto(bytes: PackedByteArray) -> String:
	var re := RegEx.new()
	re.compile("^[a-z][a-z0-9_]*(\\.[a-zA-Z0-9_]+)+$")
	var texto := ""
	var i := 0
	while i + 1 < bytes.size():
		var c := bytes[i] | (bytes[i + 1] << 8)
		if c >= 32 and c < 127:
			texto += char(c)
		else:
			if texto.length() > 5 and re.search(texto) != null and not texto.begins_with("android.") and not texto.begins_with("androidx."):
				return texto
			texto = ""
		i += 2
	return ""


static func resumen_apk(r: Dictionary) -> String:
	var t := "APK abierto en: %s\nTipo: %s%s\n%d archivos (%s MB): %d imágenes, %d sonidos, %d modelos 3D." % [
		r["carpeta"], r["tipo"], (" · app " + str(r["paquete"])) if str(r["paquete"]) != "" else "",
		r["archivos"], str(r["mb"]), r["imagenes"], r["audios"], r["modelos"]]
	if str(r["html"]) != "":
		t += "\n¡Es un juego web! Su página está en: %s\nÁbrela con «Editar un juego HTML» en la pantalla de inicio, o cópiala a tu proyecto." % r["html"]
	elif r["codigo"]:
		t += "\nEs una app nativa (código compilado): se pueden sacar imágenes, sonidos y modelos, pero su lógica no se puede editar."
	return t
