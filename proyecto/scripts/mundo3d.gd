extends RefCounted
## Ayudantes 3D compartidos por los modos 2.5D y 3D (Godot 3D).


static func mat(c: Color, brillo: float = 0.0, sin_luz: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	if brillo > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = brillo
	if sin_luz:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


static func caja(tam: Vector3, c: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat(c)
	mi.position = pos
	return mi


## Imagen de emoji como personaje plano en el mundo 3D (tam_m = ancho en metros).
static func sprite(e: String, tam_m: float) -> Sprite3D:
	var s := Sprite3D.new()
	var tex: Texture2D = Datos.textura(e)
	s.texture = tex
	if tex:
		s.pixel_size = tam_m / float(tex.get_width())
	s.shaded = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	return s


## Cualquier cosa de la biblioteca en el mundo 3D:
##  "a:xxx" modelo genérico, "g:xxx.glb" modelo importado,
##  "u:xxx.png" o emoji -> dibujo plano.  `alto` en metros (para dibujos: ancho).
static func objeto(e: String, alto: float, cuadro_px: float = 0.0) -> Node3D:
	if e.begins_with("a:"):
		if cuadro_px > 0.0:
			return preload("res://scripts/assets3d.gd").construir_para_cuadro(e.substr(2), cuadro_px)
		return preload("res://scripts/assets3d.gd").construir(e.substr(2), alto)
	if e.begins_with("g:"):
		return preload("res://scripts/importar.gd").modelo(e, alto)
	return sprite(e, alto)


static func es_modelo(e: String) -> bool:
	return e.begins_with("a:") or e.begins_with("g:")


## Moneda 3D que gira.
static func moneda() -> Node3D:
	var pivote := Node3D.new()
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.3
	cm.bottom_radius = 0.3
	cm.height = 0.1
	mi.mesh = cm
	mi.rotation_degrees = Vector3(90, 0, 0)
	mi.material_override = mat(Color("ffc61a"), 0.45)
	pivote.add_child(mi)
	return pivote


static func cono(radio: float, alto: float, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = radio
	cm.height = alto
	cm.radial_segments = 12
	mi.mesh = cm
	mi.material_override = mat(c)
	return mi


## Cielo con degradado del tema + luz suave.
static func entorno(tema: Dictionary, fondo: String = "") -> WorldEnvironment:
	var sky := ProceduralSkyMaterial.new()
	sky.sky_top_color = tema["cielo"][0]
	sky.sky_horizon_color = tema["cielo"][1]
	sky.ground_horizon_color = tema["cielo"][1]
	sky.ground_bottom_color = tema["lejos"]
	sky.sky_curve = 0.25
	var cielo := Sky.new()
	cielo.sky_material = sky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = cielo
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	var tex: Texture2D = Datos.textura(fondo) if fondo != "" else null
	if tex:
		# imagen propia detrás de todo el mundo 3D
		env.background_mode = Environment.BG_CANVAS
		var capa := CanvasLayer.new()
		capa.layer = -100
		we.add_child(capa)
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		capa.add_child(tr)
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return we


static func sol() -> DirectionalLight3D:
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-55, -30, 0)
	l.light_energy = 1.0
	return l


## Suelo con cuadros (se nota el movimiento). Centrado en (cx, cz), y = 0.
static func suelo(color: Color, ancho: float, fondo: float, celda: float, cx: float, cz: float) -> MeshInstance3D:
	var img := Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.WHITE)
	img.set_pixel(1, 1, Color.WHITE)
	img.set_pixel(1, 0, Color(0.9, 0.9, 0.9))
	img.set_pixel(0, 1, Color(0.9, 0.9, 0.9))
	var tex := ImageTexture.create_from_image(img)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(ancho, fondo)
	mi.mesh = pm
	var m := mat(color)
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.uv1_scale = Vector3(ancho / (celda * 2.0), fondo / (celda * 2.0), 1.0)
	mi.material_override = m
	mi.position = Vector3(cx, 0, cz)
	return mi


## Colinas lejanas: una tira de triángulos con forma de ondas, en el plano z.
static func colinas(color: Color, z: float, base: float, amp: float, onda: float, x0: float, x1: float, desfase: float = 0.0) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x := x0
	while x < x1:
		var xa := x
		var xb := x + 2.0
		var ya := base + sin((xa + desfase) / onda) * amp + sin((xa + desfase) / (onda * 0.37) + 2.0) * amp * 0.35
		var yb := base + sin((xb + desfase) / onda) * amp + sin((xb + desfase) / (onda * 0.37) + 2.0) * amp * 0.35
		var suelo := -8.0
		st.add_vertex(Vector3(xa, suelo, z))
		st.add_vertex(Vector3(xb, yb, z))
		st.add_vertex(Vector3(xa, ya, z))
		st.add_vertex(Vector3(xa, suelo, z))
		st.add_vertex(Vector3(xb, suelo, z))
		st.add_vertex(Vector3(xb, yb, z))
		x = xb
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := mat(color, 0.0, true)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	return mi


## Un visor 3D que ocupa todo el control padre. Devuelve [contenedor, raíz 3D].
static func visor(padre: Control) -> Array:
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.gui_disable_input = true
	cont.add_child(vp)
	var raiz := Node3D.new()
	vp.add_child(raiz)
	padre.add_child(cont)
	padre.move_child(cont, 0)
	cont.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return [cont, raiz]
