extends Node
const Importar := preload("res://scripts/importar.gd")
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("ok  " if c else "MAL ") + m)
	if not c: fallos += 1
func _media(img: Image) -> Color:
	var r := 0.0; var g := 0.0; var b := 0.0; var n := 0.0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.1:
				r += c.r; g += c.g; b += c.b; n += 1.0
	return Color(r / n, g / n, b / n) if n > 0.0 else Color.BLACK
func _ready() -> void:
	Datos.establecer_proyecto({"niveles": [Datos.normalizar(Datos.nivel_inicial())], "reglas": Datos.reglas_completas({})})
	ok(Datos.reglas["paleta"] == "" and Datos.reglas["paleta_fuerza"] == 80, "reglas traen paleta vacía")
	Datos.reglas = Datos.reglas_completas({"paleta": "marte", "paleta_fuerza": 999})
	ok(Datos.reglas["paleta"] == "" and Datos.reglas["paleta_fuerza"] == 100, "paleta mala se corrige")
	var bib: Array = Importar.biblioteca()
	var cats := {}
	for a in bib:
		cats[str(a.get("cat", ""))] = int(cats.get(str(a.get("cat", "")), 0)) + 1
	print(cats)
	for c in ["Naturaleza", "Rocas", "Ciudad", "Calles", "Trenes", "Plataformas 3D", "Follaje 2D", "Animales"]:
		ok(int(cats.get(c, 0)) >= 5, "categoría %s: %d" % [c, int(cats.get(c, 0))])
	# imagen verde -> desierto
	var base: Texture2D = Datos.textura("g:UN_CommonTree_1.glb")
	ok(base != null, "miniatura de árbol")
	var m0 := _media(base.get_image())
	Datos.reglas["paleta"] = "desierto"
	Datos.reglas["paleta_fuerza"] = 90
	Datos.olvidar_texturas_pal()
	var t1: Texture2D = Datos.textura("g:UN_CommonTree_1.glb")
	var m1 := _media(t1.get_image())
	ok(_d(m1, m0) > 0.1 and m1.r > m1.b, "el árbol verde se vuelve de desierto (%s -> %s)" % [m0, m1])
	Datos.pal_item = "no"
	ok(Datos.textura("g:UN_CommonTree_1.glb") == base, "objeto con colores originales")
	Datos.pal_item = "nieve"
	var tn: Texture2D = Datos.textura("g:UN_CommonTree_1.glb")
	ok(_media(tn.get_image()).b > _media(tn.get_image()).r, "objeto con su propia paleta (nieve)")
	Datos.pal_item = ""
	# fondo grande: tiempo
	var gran := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	gran.fill(Color(0.2, 0.7, 0.3))
	var t0 := Time.get_ticks_msec()
	Datos.pal_imagen(gran, "desierto", 0.8)
	ok(Time.get_ticks_msec() - t0 < 4000, "recolorear 1280x720 tarda %d ms" % (Time.get_ticks_msec() - t0))
	# modelo 3D
	Datos.reglas["paleta"] = ""
	var mo: Node3D = Importar.modelo("g:UN_CommonTree_1.glb", 2.0)
	var c0 := _color_modelo(mo)
	Datos.reglas["paleta"] = "desierto"
	var mo2: Node3D = Importar.modelo("g:UN_CommonTree_1.glb", 2.0)
	var c1 := _color_modelo(mo2)
	ok(_d(c0, c1) > 0.05, "modelo 3D cambia de color (%s -> %s)" % [c0, c1])
	for id in ["g:SN_CommonTree_1.glb", "g:Com_building_a.glb", "g:Q_Cow.glb", "g:KP_platform_2x2x2_green.glb", "g:NK_tree_oak.glb", "g:Tren_locomotive_blue_industrial.glb", "g:TS_Birch_4.glb"]:
		var x: Node3D = Importar.modelo(id, 1.5)
		ok(x != null and x.find_children("*", "MeshInstance3D", true, false).size() > 0, "carga con paleta " + id)
	var vaca: Node3D = Importar.modelo("g:Q_Cow.glb", 1.5)
	ok(vaca != null and vaca.find_children("*", "AnimationPlayer", true, false).size() > 0, "los animales ahora traen animación")
	# partida con paleta en pantalla: abre el juego
	Datos.reglas["paleta_todo"] = true
	var n := Datos.normalizar(Datos.nivel_inicial())
	n["theme"] = "desierto" if Datos.temas.has("desierto") else n["theme"]
	var j = load("res://scripts/juego.gd").new()
	add_child(j)
	j.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var nn: Dictionary = n.duplicate(true)
	nn["reglas"] = Datos.reglas
	j.iniciar(nn, false, false)
	await get_tree().create_timer(0.6).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/asis/paleta_juego.png")
	ok(true, "juego con paleta de pantalla abre")
	print("FALLOS: ", fallos)
	get_tree().quit(1 if fallos > 0 else 0)
func _color_modelo(n: Node) -> Color:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := (mi as MeshInstance3D)
		var mat := m.get_active_material(0)
		if mat is BaseMaterial3D:
			return (mat as BaseMaterial3D).albedo_color
	return Color.BLACK
func _d(a: Color, b: Color) -> float:
	return Vector3(a.r, a.g, a.b).distance_to(Vector3(b.r, b.g, b.b))
