extends RefCounted
## Importar cosas propias: dibujos (.png, .jpg, .webp) para 2D y modelos .glb / .gltf para 3D.
## Los archivos se copian a user://mis_assets. Un juego exportado los lleva en la
## carpeta «assets» junto al programa.
## Identificadores: "u:nombre.png" (dibujo) y "g:nombre.glb" (modelo 3D).

const Hornear := preload("res://scripts/hornear.gd")
const Assets3D := preload("res://scripts/assets3d.gd")
const CARPETA := "user://mis_assets"
const INDICE := "user://mis_assets/indice.json"
## Biblioteca que viene con el programa (modelos, sonidos y letras de licencia libre; ver docs/CREDITOS.md).
const BIBLIOTECA := "res://assets/biblioteca"
const INDICE_BIB := "res://assets/biblioteca/indice.json"


static func es_modelo(id: String) -> bool:
	return id.begins_with("g:")


static func es_audio(id: String) -> bool:
	return id.begins_with("m:")


static func nombre_de(id: String) -> String:
	return id.substr(2)


## Imagen que representa al asset (el propio dibujo, o la miniatura del modelo).
static func ruta_dibujo(id: String) -> String:
	if id.begins_with("g:"):
		var png := nombre_de(id) + ".png"
		var junto := OS.get_executable_path().get_base_dir().path_join("assets").path_join(png)
		for c in [junto, "/assets/" + png, BIBLIOTECA.path_join(png + ".bib")]:
			if FileAccess.file_exists(c):
				return c
		return CARPETA.path_join(png)
	return ruta_archivo(id)


## Busca el archivo del asset: junto al programa (juego exportado) o en la carpeta del creador.
static func ruta_archivo(id: String) -> String:
	var n := nombre_de(id)
	var junto := OS.get_executable_path().get_base_dir().path_join("assets").path_join(n)
	# en la biblioteca los archivos llevan «.bib» para que el exportador los guarde tal cual
	var bib := BIBLIOTECA.path_join("audio").path_join(n + ".bib") if n.get_extension() in ["ogg", "wav", "mp3"] else BIBLIOTECA.path_join(n + ".bib")
	for c in [junto, "/assets/" + n, CARPETA.path_join(n), bib]:
		if FileAccess.file_exists(c):
			return c
	return CARPETA.path_join(n)


## Lo que el creador importó (solo lo suyo).
static func listar_propios() -> Array:
	var f := FileAccess.open(INDICE, FileAccess.READ)
	if f == null:
		return []
	var r = JSON.parse_string(f.get_as_text())
	return r if r is Array else []


## Lo del creador y, después, la biblioteca incluida. Cada entrada: {id, n, cat?}.
static func listar() -> Array:
	return listar_propios() + biblioteca()


## Cosas que sirven de mascota o de personaje en la tienda: lo propio y los animales de la biblioteca.
static func mascotas() -> Array:
	var r: Array = listar_propios().filter(func(a): return not es_audio(a["id"]))
	for a in biblioteca():
		if str(a.get("cat", "")) in ["Animales", "Dinosaurios"]:
			r.append(a)
	return r


static func biblioteca() -> Array:
	var f := FileAccess.open(INDICE_BIB, FileAccess.READ)
	if f == null:
		return []
	var r = JSON.parse_string(f.get_as_text())
	return r if r is Array else []


static func _guardar_indice(lista: Array) -> void:
	DirAccess.make_dir_recursive_absolute(CARPETA)
	var f := FileAccess.open(INDICE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(lista))


static func _nombre_libre(base: String) -> String:
	var limpio := base.get_file().replace(" ", "_")
	var stem := limpio.get_basename()
	var ext := limpio.get_extension()
	var n := limpio
	var k := 2
	while FileAccess.file_exists(CARPETA.path_join(n)):
		n = "%s_%d.%s" % [stem, k, ext]
		k += 1
	return n


## Guarda una imagen hecha dentro del programa (por ejemplo, un personaje creado) como dibujo propio.
static func guardar_imagen(img: Image, nombre: String) -> String:
	DirAccess.make_dir_recursive_absolute(CARPETA)
	var base := nombre.strip_edges()
	if base == "":
		base = "personaje"
	var archivo := _nombre_libre(base.replace("/", "_") + ".png")
	if img.save_png(CARPETA.path_join(archivo)) != OK:
		return ""
	var id := "u:" + archivo
	var lista := listar_propios()
	lista.append({"id": id, "n": archivo.get_basename().left(14)})
	_guardar_indice(lista)
	return id


## Copia un archivo al creador. Devuelve el id ("u:..." o "g:...") o "" si no se pudo.
static func importar_archivo(origen: String) -> String:
	var ext := origen.get_extension().to_lower()
	var tipo := ""
	if ext in ["png", "jpg", "jpeg", "webp"]:
		tipo = "u"
	elif ext in ["glb", "gltf"]:
		tipo = "g"
	elif ext in ["ogg", "mp3", "wav"]:
		tipo = "m"
	else:
		return ""
	DirAccess.make_dir_recursive_absolute(CARPETA)
	var datos := FileAccess.get_file_as_bytes(origen)
	if datos.is_empty():
		return ""
	var nombre := _nombre_libre(origen)
	var f := FileAccess.open(CARPETA.path_join(nombre), FileAccess.WRITE)
	if f == null:
		return ""
	f.store_buffer(datos)
	f.close()
	var id := tipo + ":" + nombre
	var lista := listar_propios()
	lista.append({"id": id, "n": nombre.get_basename().left(14)})
	_guardar_indice(lista)
	return id


static func quitar(id: String) -> void:
	var lista := listar_propios().filter(func(a): return a["id"] != id)
	_guardar_indice(lista)
	DirAccess.remove_absolute(ruta_archivo(id))
	if id.begins_with("g:"):
		DirAccess.remove_absolute(ruta_dibujo(id))
	Datos.olvidar_textura(id)


# ------------------------------------------------------------ audio
## Música o sonido propio (.ogg, .mp3, .wav), listo para repetirse sin parar.
static func cargar_audio(id: String) -> AudioStream:
	var ruta := ruta_archivo(id)
	if not FileAccess.file_exists(ruta):
		return null
	var ext := ruta.get_basename().get_extension().to_lower() if ruta.ends_with(".bib") else ruta.get_extension().to_lower()
	if ruta.ends_with(".bib") and ext == "ogg":
		var ob := AudioStreamOggVorbis.load_from_buffer(FileAccess.get_file_as_bytes(ruta))
		if ob:
			ob.loop = true
		return ob
	match ext:
		"ogg":
			var o := AudioStreamOggVorbis.load_from_file(ruta)
			if o:
				o.loop = true
			return o
		"mp3":
			var m := AudioStreamMP3.load_from_file(ruta)
			if m:
				m.loop = true
			return m
		"wav":
			var w := AudioStreamWAV.load_from_file(ruta)
			if w and w.format != AudioStreamWAV.FORMAT_IMA_ADPCM:
				var bytes := 2 if w.format == AudioStreamWAV.FORMAT_16_BITS else 1
				w.loop_mode = AudioStreamWAV.LOOP_FORWARD
				w.loop_begin = 0
				w.loop_end = w.data.size() / (bytes * (2 if w.stereo else 1))
			return w
	return null


# ------------------------------------------------------------ modelos .glb
static func cargar_glb(id: String) -> Node3D:
	var ruta := ruta_archivo(id)
	if not FileAccess.file_exists(ruta):
		return null
	if not ClassDB.class_exists("GLTFDocument"):
		return null
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if ruta.ends_with(".bib"):
		if doc.append_from_buffer(FileAccess.get_file_as_bytes(ruta), "", st) != OK:
			return null
	elif doc.append_from_file(ruta, st) != OK:
		return null
	var escena := doc.generate_scene(st)
	return escena as Node3D


## Modelo listo para poner en un mundo 3D: de la altura pedida y apoyado en el suelo.
static func modelo(id: String, alto: float) -> Node3D:
	var m := cargar_glb(id)
	if m == null:
		var raiz := Node3D.new()
		Assets3D.f(raiz, "caja", Vector3(0.8, 0.8, 0.8), Color("c084fc"), Vector3(0, 0.4, 0))
		return raiz
	# gira el modelo para que mire hacia +Z (como los demás); el juego lo da vuelta al correr
	var piv := Node3D.new()
	piv.add_child(m)
	m.rotation.y = _giro_frente(m)
	var n := Assets3D._normalizar(piv, alto)
	animar(n)
	return n


## Ángulo (radianes, eje Y) que hay que girar un modelo con esqueleto para que su cabeza mire a +Z.
## Si no se encuentra la cabeza, no se gira (0).
static func _giro_frente(raiz: Node) -> float:
	var sks := raiz.find_children("*", "Skeleton3D", true, false)
	if sks.is_empty():
		return 0.0
	var sk := sks[0] as Skeleton3D
	var cabeza := -1
	var centro := Vector3.ZERO
	for i in sk.get_bone_count():
		centro += sk.get_bone_global_rest(i).origin
		if cabeza < 0 and sk.get_bone_name(i).to_lower().contains("head"):
			cabeza = i
	if cabeza < 0:
		return 0.0
	centro /= float(sk.get_bone_count())
	var d := sk.get_bone_global_rest(cabeza).origin - centro
	d.y = 0.0
	if d.length() < 0.02:
		return 0.0
	return -atan2(d.x, d.z)


## Pone en marcha (en bucle) la animación que traiga el modelo, si trae alguna.
static func animar(raiz: Node) -> void:
	for h in raiz.find_children("*", "AnimationPlayer", true, false):
		var ap := h as AnimationPlayer
		var lista := ap.get_animation_list()
		if lista.is_empty():
			continue
		var elegida := String(lista[0])
		for nombre in lista:
			var q := String(nombre).to_lower()
			if q.contains("run") or q.contains("corr") or q.contains("walk") or q.contains("dino"):
				elegida = String(nombre)
				break
		var a := ap.get_animation(elegida)
		if a:
			a.loop_mode = Animation.LOOP_LINEAR
		ap.play(elegida)


## Fabrica la miniatura de un modelo .glb (se guarda junto al archivo).
static func hacer_miniatura(arbol: SceneTree, id: String) -> void:
	var m := cargar_glb(id)
	if m == null:
		return
	var n := Assets3D._normalizar(m, 1.7)
	var img: Image = await Hornear.foto(arbol, n, 384, 30.0)
	Hornear.a_sprite(img, 128).save_png(ruta_dibujo(id))
	Datos.olvidar_textura(id)
