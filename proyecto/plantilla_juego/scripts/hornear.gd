extends RefCounted
## "Horneado": saca una foto de un modelo 3D y la convierte en un dibujo 2D.
## Se usa para fabricar las imágenes 2D de la biblioteca y las miniaturas de los
## modelos .glb que importa el usuario.

const Assets3D := preload("res://scripts/assets3d.gd")


## Devuelve una Image RGBA (lado x lado) con el modelo visto desde el frente,
## girado `yaw` grados y con la cámara un poco desde arriba.
static func foto(arbol: SceneTree, modelo: Node3D, lado: int = 256, yaw: float = 25.0) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(lado, lado)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var raiz := Node3D.new()
	vp.add_child(raiz)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	raiz.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, -35, 0)
	sol.light_energy = 1.05
	raiz.add_child(sol)
	# luz de relleno suave por el otro lado y luz de contorno por detrás: da volumen y brillo
	var relleno := DirectionalLight3D.new()
	relleno.rotation_degrees = Vector3(-20, 140, 0)
	relleno.light_energy = 0.35
	relleno.light_color = Color(0.85, 0.9, 1.0)
	raiz.add_child(relleno)
	var borde := DirectionalLight3D.new()
	borde.rotation_degrees = Vector3(-30, 200, 0)
	borde.light_energy = 0.3
	borde.light_color = Color(1.0, 0.95, 0.85)
	raiz.add_child(borde)
	var pivote := Node3D.new()
	pivote.rotation_degrees.y = yaw
	pivote.add_child(modelo)
	raiz.add_child(pivote)
	var acc: Array = [null]
	Assets3D._aabb(raiz, Transform3D.IDENTITY, acc)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var centro := Vector3(0, 0.5, 0)
	var tam := 2.0
	if acc[0] != null:
		var bb: AABB = acc[0]
		centro = bb.position + bb.size / 2.0
		tam = maxf(bb.size.y, maxf(bb.size.x, bb.size.z)) * 1.15
	cam.size = tam
	raiz.add_child(cam)
	cam.look_at_from_position(centro + Vector3(0, tam * 0.22, 20.0), centro, Vector3.UP)
	arbol.root.add_child.call_deferred(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	img.convert(Image.FORMAT_RGBA8)
	return img


## Recorta los bordes vacíos y lo deja en un cuadrado (lado x lado), apoyado abajo.
static func a_sprite(img: Image, lado: int = 128) -> Image:
	var r := img.get_used_rect()
	if r.size.x <= 0 or r.size.y <= 0:
		return Image.create_empty(lado, lado, false, Image.FORMAT_RGBA8)
	var rec := img.get_region(r)
	var margen := 4
	var disp := lado - margen * 2
	var esc := minf(float(disp) / rec.get_width(), float(disp) / rec.get_height())
	rec.resize(maxi(1, roundi(rec.get_width() * esc)), maxi(1, roundi(rec.get_height() * esc)), Image.INTERPOLATE_LANCZOS)
	var lienzo := Image.create_empty(lado, lado, false, Image.FORMAT_RGBA8)
	lienzo.fill(Color(0, 0, 0, 0))
	lienzo.blend_rect(rec, Rect2i(Vector2i.ZERO, rec.get_size()), Vector2i((lado - rec.get_width()) / 2, lado - margen - rec.get_height()))
	return lienzo
