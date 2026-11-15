extends RefCounted
## Biblioteca de modelos genéricos hechos con formas 3D (cajas, esferas, conos…).
## Los mismos modelos se ven en 3D, en 2.5D (modelo real de lado) y en 2D
## (imagen "horneada" del modelo: assets/modelos2d/<id>.png).

# id, nombre
const PERSONAJES := [
	["explorador", "Explorador"], ["caballero", "Caballero"], ["mago", "Mago"], ["robot", "Robot"],
	["astronauta", "Astronauta"], ["pirata", "Pirata"], ["ninja", "Ninja"], ["bichito", "Bichito"], ["animalito", "Animalito"],
]
# mascotas dinosaurio hechas con formas (las otras mascotas de Dino Run son modelos GLB)
const MASCOTAS := [
	["d_velociraptor", "Velociraptor"], ["d_dilofosaurio", "Dilofosaurio"], ["d_iguanodon", "Iguanodón"],
	["d_parasaurolophus", "Parasaurolophus"], ["d_apatosaurio", "Apatosaurio"],
]
const ENEMIGOS := [
	["slime", "Slime", false, 40], ["murcielago", "Murciélago", true, 80], ["esqueleto", "Esqueleto", false, 60],
	["arana", "Araña", false, 90], ["fantasma", "Fantasma", true, 60], ["robot_malo", "Robot malo", false, 70],
]
# categoría -> [id, nombre, alto en celdas (metros) por defecto]
const OBJETOS := {
	"Naturaleza": [["arbol", "Árbol", 2.6], ["pino", "Pino", 2.8], ["palmera", "Palmera", 2.8], ["arbusto", "Arbusto", 0.9], ["flor", "Flor", 0.6], ["hongo", "Hongo", 0.7], ["cactus", "Cactus", 1.6], ["troncos", "Troncos", 0.8], ["nube", "Nube", 1.2]],
	"Rocas": [["roca", "Roca grande", 1.6], ["piedra", "Piedra", 0.6], ["rocas", "Rocas", 1.0], ["cristal", "Cristal", 1.3]],
	"Construcciones": [["casa", "Casa", 2.6], ["torre", "Torre", 4.0], ["castillo", "Castillo", 3.4], ["edificio", "Edificio", 4.5], ["tienda", "Tienda", 1.8], ["cerca", "Cerca", 0.9], ["farol", "Farol", 2.4], ["cartel", "Cartel", 1.3], ["arco", "Arco", 2.6]],
	"Cosas": [["caja", "Caja", 0.9], ["barril", "Barril", 1.0], ["cofre", "Cofre", 0.8], ["fogata", "Fogata", 0.7], ["bandera", "Bandera", 2.2]],
}


static func todos_los_ids() -> Array:
	var r: Array = []
	for p in PERSONAJES:
		r.append(p[0])
	for e in ENEMIGOS:
		r.append(e[0])
	for m in MASCOTAS:
		r.append(m[0])
	for cat in OBJETOS:
		for o in OBJETOS[cat]:
			r.append(o[0])
	return r


static var _dims := {}


## Tamaño natural (ancho, alto) del objeto en celdas, medido en su modelo.
static func dims(id: String) -> Vector2:
	if _dims.has(id):
		return _dims[id]
	var m := construir(id)
	var d := Vector2(float(m.get_meta("ancho", 1.0)), float(m.get_meta("alto", 1.0)))
	m.free()
	_dims[id] = d
	return d


## Tamaño del cuadro (en píxeles de la grilla de 48) para dibujar el objeto sin deformarlo.
static func cuadro_px(id: String) -> int:
	var d := dims(id)
	return int(round(maxf(d.x, d.y) * 48.0))


## Modelo cuyo tamaño corresponde a un cuadro de `s` píxeles (igual que el dibujo 2D).
static func construir_para_cuadro(id: String, s: float) -> Node3D:
	var d := dims(id)
	return construir(id, d.y * (s / 48.0) / maxf(d.x, d.y))


static func alto_por_defecto(id: String) -> float:
	for cat in OBJETOS:
		for o in OBJETOS[cat]:
			if o[0] == id:
				return o[2]
	return 1.0


# ------------------------------------------------------------ formas básicas
static var _mats := {}


static func _mat(c: Color, brillo: float = 0.0) -> StandardMaterial3D:
	var k := "%s_%s" % [c.to_html(), brillo]
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	if brillo > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = brillo
	_mats[k] = m
	return m


## Agrega una forma al padre. forma: caja | esfera | capsula | cilindro | cono | prisma
static func f(padre: Node3D, forma: String, tam: Vector3, color: Color, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, brillo: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	match forma:
		"caja":
			var m := BoxMesh.new()
			m.size = Vector3.ONE
			mi.mesh = m
			mi.scale = tam
		"esfera":
			var m2 := SphereMesh.new()
			m2.radius = 0.5
			m2.height = 1.0
			m2.radial_segments = 16
			m2.rings = 8
			mi.mesh = m2
			mi.scale = tam
		"capsula":
			var m3 := CapsuleMesh.new()
			m3.radius = 0.5
			m3.height = 2.0
			m3.radial_segments = 12
			m3.rings = 4
			mi.mesh = m3
			mi.scale = Vector3(tam.x, tam.y / 2.0, tam.z)
		"cilindro":
			var m4 := CylinderMesh.new()
			m4.top_radius = 0.5
			m4.bottom_radius = 0.5
			m4.height = 1.0
			m4.radial_segments = 14
			mi.mesh = m4
			mi.scale = tam
		"cono":
			var m5 := CylinderMesh.new()
			m5.top_radius = 0.0
			m5.bottom_radius = 0.5
			m5.height = 1.0
			m5.radial_segments = 14
			mi.mesh = m5
			mi.scale = tam
		"prisma":
			var m6 := PrismMesh.new()
			m6.size = Vector3.ONE
			mi.mesh = m6
			mi.scale = tam
	mi.material_override = _mat(color, brillo)
	mi.position = pos
	mi.rotation_degrees = rot
	padre.add_child(mi)
	return mi


static func _pivote(padre: Node3D, nombre: String, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = nombre
	n.position = pos
	padre.add_child(n)
	return n


## Cuerpo humanoide básico con piernas y brazos que se pueden animar.
static func _humanoide(r: Node3D, cuerpo: Color, piel: Color, pantalon: Color, alto_cuerpo: float = 0.62) -> void:
	for lado in [-1, 1]:
		var pv := _pivote(r, "pierna_i" if lado < 0 else "pierna_d", Vector3(lado * 0.14, 0.5, 0))
		f(pv, "capsula", Vector3(0.18, 0.5, 0.18), pantalon, Vector3(0, -0.22, 0))
		f(pv, "caja", Vector3(0.2, 0.1, 0.28), Color("3b2f2f"), Vector3(0, -0.46, 0.04))
	f(r, "capsula", Vector3(0.46, alto_cuerpo, 0.3), cuerpo, Vector3(0, 0.5 + alto_cuerpo / 2.0 - 0.05, 0))
	for lado in [-1, 1]:
		var av := _pivote(r, "brazo_i" if lado < 0 else "brazo_d", Vector3(lado * 0.31, 0.5 + alto_cuerpo - 0.12, 0))
		f(av, "capsula", Vector3(0.14, 0.46, 0.14), cuerpo, Vector3(0, -0.2, 0))
		f(av, "esfera", Vector3(0.14, 0.14, 0.14), piel, Vector3(0, -0.45, 0))
	f(r, "esfera", Vector3(0.42, 0.42, 0.42), piel, Vector3(0, 0.5 + alto_cuerpo + 0.28, 0))
	for lado in [-1, 1]:
		f(r, "esfera", Vector3(0.07, 0.09, 0.05), Color("1f1b2e"), Vector3(lado * 0.1, 0.5 + alto_cuerpo + 0.3, 0.19))


# ------------------------------------------------------------ construcción
## Devuelve un Node3D con el modelo, de la altura pedida (en metros), apoyado en y=0
## y centrado en x/z. Sirve para personajes, enemigos y objetos.
static func construir(id: String, alto: float = 0.0) -> Node3D:
	var m := Node3D.new()
	_modelo(m, id)
	if alto <= 0.0:
		alto = alto_por_defecto(id) if not _es_personaje(id) else 1.7
	return _normalizar(m, alto)


static func _es_personaje(id: String) -> bool:
	for p in PERSONAJES:
		if p[0] == id:
			return true
	for e in ENEMIGOS:
		if e[0] == id:
			return true
	return false


static func _aabb(n: Node, xf: Transform3D, acc: Array) -> void:
	for c in n.get_children():
		if c is Node3D:
			var t: Transform3D = xf * (c as Node3D).transform
			if c is MeshInstance3D and (c as MeshInstance3D).mesh:
				var mi := c as MeshInstance3D
				var bb: AABB = t * mi.mesh.get_aabb()
				var sk := n as Skeleton3D
				if mi.skin != null and sk != null and mi.skin.get_bind_count() > 0:
					# malla con huesos: se dibuja en el espacio del esqueleto (pose de reposo * enlace)
					var hueso := mi.skin.get_bind_bone(0)
					if hueso < 0:
						hueso = sk.find_bone(mi.skin.get_bind_name(0))
					var rep := sk.get_bone_global_rest(hueso) if hueso >= 0 else Transform3D.IDENTITY
					bb = (xf * rep * mi.skin.get_bind_pose(0)) * mi.mesh.get_aabb()
				acc[0] = bb if acc[0] == null else (acc[0] as AABB).merge(bb)
			_aabb(c, t, acc)


## Escala el modelo a `alto` metros y lo apoya en el suelo (base en y=0, centrado).
static func _normalizar(modelo: Node3D, alto: float) -> Node3D:
	var acc: Array = [null]
	_aabb(modelo, Transform3D.IDENTITY, acc)
	var raiz := Node3D.new()
	raiz.add_child(modelo)
	if acc[0] == null:
		return raiz
	var bb: AABB = acc[0]
	var k := alto / maxf(0.001, bb.size.y)
	modelo.scale = Vector3.ONE * k
	modelo.position = Vector3(-(bb.position.x + bb.size.x / 2.0) * k, -bb.position.y * k, -(bb.position.z + bb.size.z / 2.0) * k)
	raiz.set_meta("ancho", bb.size.x * k)
	raiz.set_meta("fondo", bb.size.z * k)
	raiz.set_meta("alto", alto)
	return raiz


## Dinosaurio de dos patas (mira hacia +Z).
static func _dino_bipedo(r: Node3D, cuerpo: Color, panza: Color, cresta: Color = Color(0, 0, 0, 0), tipo: String = "") -> void:
	f(r, "esfera", Vector3(0.5, 0.5, 0.95), cuerpo, Vector3(0, 0.62, 0))
	f(r, "esfera", Vector3(0.4, 0.3, 0.75), panza, Vector3(0, 0.5, 0.06))
	f(r, "esfera", Vector3(0.34, 0.32, 0.46), cuerpo, Vector3(0, 0.98, 0.5))
	f(r, "esfera", Vector3(0.22, 0.2, 0.32), cuerpo, Vector3(0, 0.92, 0.74))
	f(r, "cono", Vector3(0.3, 0.3, 0.95), cuerpo, Vector3(0, 0.6, -0.7), Vector3(90, 0, 0))
	for lado in [-1, 1]:
		f(r, "esfera", Vector3(0.09, 0.09, 0.09), Color("1b1b1b"), Vector3(lado * 0.13, 1.03, 0.62))
		f(r, "caja", Vector3(0.07, 0.2, 0.07), cuerpo, Vector3(lado * 0.22, 0.68, 0.36))
		var pv := _pivote(r, "pierna_i" if lado < 0 else "pierna_d", Vector3(lado * 0.15, 0.45, 0.0))
		f(pv, "cilindro", Vector3(0.15, 0.45, 0.15), cuerpo, Vector3(0, -0.22, 0))
		f(pv, "caja", Vector3(0.15, 0.06, 0.24), panza, Vector3(0, -0.45, 0.07))
	match tipo:
		"cresta":
			for lado in [-1, 1]:
				f(r, "caja", Vector3(0.04, 0.26, 0.34), cresta, Vector3(lado * 0.07, 1.2, 0.46))
		"parasaurolophus":
			f(r, "cilindro", Vector3(0.09, 0.62, 0.09), cresta, Vector3(0, 1.2, 0.2), Vector3(-70, 0, 0))
		"garra":
			f(r, "cono", Vector3(0.08, 0.2, 0.08), Color("f4efe0"), Vector3(0, 0.1, 0.18), Vector3(90, 0, 0))


## Dinosaurio de cuatro patas (mira hacia +Z); cuello largo si `cuello` es verdadero.
static func _dino_cuadrupedo(r: Node3D, cuerpo: Color, panza: Color, cuello: bool = false, pua: Color = Color(0, 0, 0, 0)) -> void:
	f(r, "esfera", Vector3(0.65, 0.6, 1.15), cuerpo, Vector3(0, 0.62, 0))
	f(r, "esfera", Vector3(0.5, 0.3, 0.9), panza, Vector3(0, 0.46, 0.05))
	f(r, "cono", Vector3(0.36, 0.36, 1.1 if cuello else 0.8), cuerpo, Vector3(0, 0.6, -0.9), Vector3(90, 0, 0))
	if cuello:
		f(r, "cilindro", Vector3(0.2, 1.0, 0.2), cuerpo, Vector3(0, 1.05, 0.5), Vector3(32, 0, 0))
		f(r, "esfera", Vector3(0.24, 0.22, 0.32), cuerpo, Vector3(0, 1.52, 0.78))
		for lado in [-1, 1]:
			f(r, "esfera", Vector3(0.07, 0.07, 0.07), Color("1b1b1b"), Vector3(lado * 0.1, 1.56, 0.86))
	else:
		f(r, "esfera", Vector3(0.38, 0.36, 0.5), cuerpo, Vector3(0, 0.72, 0.72))
		f(r, "esfera", Vector3(0.24, 0.22, 0.32), cuerpo, Vector3(0, 0.66, 0.98))
		for lado in [-1, 1]:
			f(r, "esfera", Vector3(0.08, 0.08, 0.08), Color("1b1b1b"), Vector3(lado * 0.14, 0.78, 0.86))
		if pua.a > 0.0:
			f(r, "cono", Vector3(0.08, 0.22, 0.08), pua, Vector3(0.3, 0.64, 0.5), Vector3(0, 0, -80))
	for lado in [-1, 1]:
		for z in [0.4, -0.35]:
			var nombre := ("brazo_" if z > 0.0 else "pierna_") + ("i" if lado < 0 else "d")
			var pv := _pivote(r, nombre, Vector3(lado * 0.24, 0.4, z))
			f(pv, "cilindro", Vector3(0.19, 0.42, 0.19), cuerpo, Vector3(0, -0.2, 0))
			f(pv, "caja", Vector3(0.2, 0.06, 0.24), panza, Vector3(0, -0.42, 0.04))


static func _modelo(r: Node3D, id: String) -> void:
	match id:
		"d_velociraptor":
			_dino_bipedo(r, Color("d9792a"), Color("f2c27a"), Color("c0392b"), "garra")
		"d_dilofosaurio":
			_dino_bipedo(r, Color("2f9e4a"), Color("e9d27a"), Color("e8501e"), "cresta")
		"d_iguanodon":
			_dino_cuadrupedo(r, Color("6cc23a"), Color("e6dca0"), false, Color("f4efe0"))
		"d_parasaurolophus":
			_dino_bipedo(r, Color("f2b22e"), Color("f6e3a0"), Color("c0284e"), "parasaurolophus")
		"d_apatosaurio":
			_dino_cuadrupedo(r, Color("47b3e6"), Color("dfe8ea"), true)
		# ---------------- personajes
		"explorador":
			_humanoide(r, Color("1fa3a8"), Color("f1c9a1"), Color("3a4a7a"))
			f(r, "esfera", Vector3(0.46, 0.3, 0.46), Color("7a4a2a"), Vector3(0, 1.62, -0.01))
			f(r, "cilindro", Vector3(0.62, 0.04, 0.62), Color("7a4a2a"), Vector3(0, 1.5, 0))
		"caballero":
			_humanoide(r, Color("9aa3b2"), Color("9aa3b2"), Color("6b7280"))
			f(r, "esfera", Vector3(0.5, 0.5, 0.5), Color("b6bfce"), Vector3(0, 1.5, 0))
			f(r, "caja", Vector3(0.3, 0.06, 0.1), Color("1f1b2e"), Vector3(0, 1.5, 0.23))
			f(r, "cono", Vector3(0.1, 0.3, 0.3), Color("e5484d"), Vector3(0, 1.82, -0.08), Vector3(-20, 0, 0))
			f(r, "caja", Vector3(0.1, 0.4, 0.3), Color("c0c6d4"), Vector3(0.44, 0.9, 0.1))
		"mago":
			_humanoide(r, Color("6d4aff"), Color("f1c9a1"), Color("4b2fb5"))
			f(r, "cono", Vector3(0.66, 0.7, 0.66), Color("6d4aff"), Vector3(0, 0.62, 0))
			f(r, "cono", Vector3(0.5, 0.7, 0.5), Color("4b2fb5"), Vector3(0, 2.0, 0))
			f(r, "cilindro", Vector3(0.7, 0.05, 0.7), Color("4b2fb5"), Vector3(0, 1.67, 0))
			f(r, "cono", Vector3(0.3, 0.3, 0.2), Color("f5f5f5"), Vector3(0, 1.28, 0.16), Vector3(180, 0, 0))
		"robot":
			for lado in [-1, 1]:
				var pv := _pivote(r, "pierna_i" if lado < 0 else "pierna_d", Vector3(lado * 0.16, 0.5, 0))
				f(pv, "caja", Vector3(0.18, 0.5, 0.2), Color("9aa3b2"), Vector3(0, -0.25, 0))
				var av := _pivote(r, "brazo_i" if lado < 0 else "brazo_d", Vector3(lado * 0.36, 1.05, 0))
				f(av, "caja", Vector3(0.14, 0.5, 0.14), Color("c0c6d4"), Vector3(0, -0.2, 0))
			f(r, "caja", Vector3(0.5, 0.6, 0.34), Color("e5e7eb"), Vector3(0, 0.85, 0))
			f(r, "caja", Vector3(0.14, 0.14, 0.04), Color("22d3ee"), Vector3(0, 0.9, 0.18), Vector3.ZERO, 1.2)
			f(r, "caja", Vector3(0.44, 0.34, 0.34), Color("c0c6d4"), Vector3(0, 1.42, 0))
			for lado in [-1, 1]:
				f(r, "esfera", Vector3(0.1, 0.1, 0.05), Color("22d3ee"), Vector3(lado * 0.1, 1.45, 0.17), Vector3.ZERO, 1.5)
			f(r, "cilindro", Vector3(0.03, 0.2, 0.03), Color("6b7280"), Vector3(0, 1.69, 0))
			f(r, "esfera", Vector3(0.08, 0.08, 0.08), Color("ef4444"), Vector3(0, 1.82, 0), Vector3.ZERO, 1.0)
		"astronauta":
			_humanoide(r, Color("f5f5f5"), Color("f5f5f5"), Color("e5e7eb"))
			f(r, "esfera", Vector3(0.62, 0.62, 0.62), Color("e5e7eb"), Vector3(0, 1.5, 0))
			f(r, "esfera", Vector3(0.46, 0.4, 0.3), Color("38bdf8"), Vector3(0, 1.5, 0.15), Vector3.ZERO, 0.4)
			f(r, "caja", Vector3(0.36, 0.5, 0.18), Color("9aa3b2"), Vector3(0, 0.95, -0.24))
		"pirata":
			_humanoide(r, Color("e5484d"), Color("e6b48a"), Color("1f2937"))
			f(r, "cono", Vector3(0.62, 0.3, 0.62), Color("111827"), Vector3(0, 1.7, 0))
			f(r, "cilindro", Vector3(0.8, 0.04, 0.5), Color("111827"), Vector3(0, 1.55, 0))
			f(r, "esfera", Vector3(0.12, 0.12, 0.05), Color("111827"), Vector3(0.1, 1.38, 0.19))
		"ninja":
			_humanoide(r, Color("1f2937"), Color("f1c9a1"), Color("111827"))
			f(r, "esfera", Vector3(0.45, 0.45, 0.45), Color("1f2937"), Vector3(0, 1.4, 0))
			f(r, "caja", Vector3(0.36, 0.1, 0.1), Color("f1c9a1"), Vector3(0, 1.4, 0.18))
			f(r, "cilindro", Vector3(0.47, 0.07, 0.47), Color("ef4444"), Vector3(0, 1.5, 0))
		"bichito":
			f(r, "esfera", Vector3(1.0, 0.95, 0.9), Color("5fd16f"), Vector3(0, 0.5, 0))
			for lado in [-1, 1]:
				f(r, "esfera", Vector3(0.28, 0.32, 0.2), Color.WHITE, Vector3(lado * 0.2, 0.7, 0.4))
				f(r, "esfera", Vector3(0.12, 0.14, 0.1), Color("1f1b2e"), Vector3(lado * 0.2, 0.7, 0.5))
				f(r, "cono", Vector3(0.14, 0.28, 0.14), Color("f59e0b"), Vector3(lado * 0.3, 1.05, 0))
				var pv2 := _pivote(r, "pierna_i" if lado < 0 else "pierna_d", Vector3(lado * 0.25, 0.1, 0.05))
				f(pv2, "esfera", Vector3(0.24, 0.16, 0.34), Color("3d9a4b"), Vector3(0, -0.04, 0.05))
			f(r, "caja", Vector3(0.3, 0.05, 0.05), Color("1f1b2e"), Vector3(0, 0.42, 0.44))
		"animalito":
			f(r, "esfera", Vector3(0.9, 0.8, 0.9), Color("f59e0b"), Vector3(0, 0.45, 0))
			f(r, "esfera", Vector3(0.7, 0.6, 0.55), Color("fde68a"), Vector3(0, 0.38, 0.22))
			for lado in [-1, 1]:
				f(r, "cono", Vector3(0.25, 0.4, 0.2), Color("f59e0b"), Vector3(lado * 0.28, 1.0, 0))
				f(r, "esfera", Vector3(0.12, 0.16, 0.08), Color("1f1b2e"), Vector3(lado * 0.2, 0.62, 0.38))
				var pv3 := _pivote(r, "pierna_i" if lado < 0 else "pierna_d", Vector3(lado * 0.22, 0.1, 0.05))
				f(pv3, "esfera", Vector3(0.22, 0.16, 0.3), Color("d97706"), Vector3(0, -0.02, 0.05))
			f(r, "esfera", Vector3(0.12, 0.09, 0.08), Color("ec4899"), Vector3(0, 0.5, 0.5))
			f(r, "capsula", Vector3(0.14, 0.6, 0.14), Color("f59e0b"), Vector3(0, 0.45, -0.5), Vector3(60, 0, 0))
		# ---------------- enemigos
		"slime":
			f(r, "esfera", Vector3(1.0, 0.8, 1.0), Color("7bd34f"), Vector3(0, 0.35, 0))
			f(r, "esfera", Vector3(1.1, 0.25, 1.1), Color("6abf40"), Vector3(0, 0.12, 0))
			for lado in [-1, 1]:
				f(r, "esfera", Vector3(0.2, 0.26, 0.12), Color.WHITE, Vector3(lado * 0.2, 0.5, 0.4))
				f(r, "esfera", Vector3(0.1, 0.12, 0.08), Color("1f1b2e"), Vector3(lado * 0.2, 0.5, 0.47))
			f(r, "caja", Vector3(0.24, 0.04, 0.05), Color("1f1b2e"), Vector3(0, 0.3, 0.48))
		"murcielago":
			f(r, "esfera", Vector3(0.55, 0.5, 0.5), Color("3b2f4a"), Vector3(0, 0.5, 0))
			for lado in [-1, 1]:
				var ala := _pivote(r, "brazo_i" if lado < 0 else "brazo_d", Vector3(lado * 0.2, 0.55, 0))
				f(ala, "prisma", Vector3(0.7, 0.45, 0.05), Color("5b4570"), Vector3(lado * 0.35, 0.0, 0), Vector3(0, 0, lado * -80))
				f(r, "cono", Vector3(0.12, 0.22, 0.1), Color("3b2f4a"), Vector3(lado * 0.14, 0.82, 0))
				f(r, "esfera", Vector3(0.12, 0.12, 0.05), Color("fde047"), Vector3(lado * 0.1, 0.56, 0.24), Vector3.ZERO, 1.0)
		"esqueleto":
			_humanoide(r, Color("e5e7eb"), Color("f3f4f6"), Color("d1d5db"), 0.5)
			for k in 3:
				f(r, "caja", Vector3(0.44, 0.04, 0.3), Color("9ca3af"), Vector3(0, 0.78 + k * 0.1, 0))
		"arana":
			f(r, "esfera", Vector3(0.8, 0.6, 0.8), Color("4b2c20"), Vector3(0, 0.45, -0.1))
			f(r, "esfera", Vector3(0.45, 0.4, 0.4), Color("6b3f2a"), Vector3(0, 0.45, 0.38))
			for k in 4:
				for lado in [-1, 1]:
					f(r, "cilindro", Vector3(0.06, 0.7, 0.06), Color("1f1b2e"), Vector3(lado * 0.5, 0.3, -0.25 + k * 0.2), Vector3(0, 0, lado * -60))
			for lado in [-1, 1]:
				f(r, "esfera", Vector3(0.12, 0.12, 0.08), Color("ef4444"), Vector3(lado * 0.1, 0.55, 0.55), Vector3.ZERO, 1.0)
		"fantasma":
			f(r, "capsula", Vector3(0.7, 1.1, 0.6), Color("f5f5ff"), Vector3(0, 0.6, 0))
			for k in 3:
				f(r, "cono", Vector3(0.24, 0.3, 0.24), Color("f5f5ff"), Vector3(-0.22 + k * 0.22, 0.1, 0), Vector3(180, 0, 0))
			for lado in [-1, 1]:
				f(r, "esfera", Vector3(0.12, 0.18, 0.08), Color("1f1b2e"), Vector3(lado * 0.14, 0.85, 0.28))
			f(r, "esfera", Vector3(0.16, 0.12, 0.06), Color("1f1b2e"), Vector3(0, 0.62, 0.3))
		"robot_malo":
			f(r, "caja", Vector3(0.7, 0.6, 0.6), Color("b91c1c"), Vector3(0, 0.55, 0))
			f(r, "caja", Vector3(0.5, 0.3, 0.5), Color("7f1d1d"), Vector3(0, 1.0, 0))
			for lado in [-1, 1]:
				f(r, "esfera", Vector3(0.12, 0.12, 0.06), Color("fde047"), Vector3(lado * 0.12, 1.02, 0.26), Vector3.ZERO, 1.5)
				var pv4 := _pivote(r, "pierna_i" if lado < 0 else "pierna_d", Vector3(lado * 0.22, 0.28, 0))
				f(pv4, "caja", Vector3(0.2, 0.3, 0.3), Color("450a0a"), Vector3(0, -0.1, 0))
			f(r, "cono", Vector3(0.1, 0.25, 0.1), Color("fde047"), Vector3(0, 1.28, 0))
		# ---------------- naturaleza
		"arbol":
			f(r, "cilindro", Vector3(0.3, 1.0, 0.3), Color("7a4a2a"), Vector3(0, 0.5, 0))
			f(r, "esfera", Vector3(1.5, 1.3, 1.5), Color("3e9a3e"), Vector3(0, 1.5, 0))
			f(r, "esfera", Vector3(1.0, 0.9, 1.0), Color("57b552"), Vector3(0.35, 1.9, 0.2))
		"pino":
			f(r, "cilindro", Vector3(0.26, 0.6, 0.26), Color("6b3f2a"), Vector3(0, 0.3, 0))
			for k in 4:
				f(r, "cono", Vector3(1.5 - k * 0.3, 0.9, 1.5 - k * 0.3), Color("2f7a47").lerp(Color("4fae6a"), k / 3.0), Vector3(0, 0.9 + k * 0.6, 0))
		"palmera":
			f(r, "cilindro", Vector3(0.22, 2.0, 0.22), Color("a9764a"), Vector3(0.12, 1.0, 0), Vector3(0, 0, -6))
			for k in 6:
				f(r, "prisma", Vector3(1.3, 0.1, 0.4), Color("3fa04a"), Vector3(0.12 + cos(k * 1.047) * 0.55, 2.0, sin(k * 1.047) * 0.55), Vector3(0, -k * 60, -14))
			f(r, "esfera", Vector3(0.2, 0.2, 0.2), Color("7a4a2a"), Vector3(0.12, 1.9, 0.1))
		"arbusto":
			f(r, "esfera", Vector3(1.0, 0.7, 0.9), Color("3e9a3e"), Vector3(0, 0.35, 0))
			f(r, "esfera", Vector3(0.7, 0.6, 0.7), Color("57b552"), Vector3(0.4, 0.3, 0.1))
			f(r, "esfera", Vector3(0.14, 0.14, 0.14), Color("ef4444"), Vector3(-0.2, 0.55, 0.3))
		"flor":
			f(r, "cilindro", Vector3(0.05, 0.4, 0.05), Color("3e9a3e"), Vector3(0, 0.2, 0))
			for k in 5:
				f(r, "esfera", Vector3(0.18, 0.1, 0.18), Color("ec4899"), Vector3(cos(k * 1.257) * 0.14, 0.45, sin(k * 1.257) * 0.14))
			f(r, "esfera", Vector3(0.14, 0.12, 0.14), Color("fde047"), Vector3(0, 0.46, 0))
		"hongo":
			f(r, "cilindro", Vector3(0.22, 0.4, 0.22), Color("f5e6d3"), Vector3(0, 0.2, 0))
			f(r, "esfera", Vector3(0.7, 0.4, 0.7), Color("e5484d"), Vector3(0, 0.45, 0))
			for k in 3:
				f(r, "esfera", Vector3(0.12, 0.05, 0.12), Color.WHITE, Vector3(cos(k * 2.1) * 0.2, 0.62, sin(k * 2.1) * 0.2))
		"cactus":
			f(r, "capsula", Vector3(0.4, 1.5, 0.4), Color("3f9a55"), Vector3(0, 0.75, 0))
			f(r, "capsula", Vector3(0.22, 0.6, 0.22), Color("3f9a55"), Vector3(0.38, 0.95, 0))
			f(r, "capsula", Vector3(0.22, 0.45, 0.22), Color("3f9a55"), Vector3(-0.35, 0.75, 0))
			f(r, "esfera", Vector3(0.16, 0.12, 0.16), Color("f472b6"), Vector3(0, 1.55, 0))
		"troncos":
			for k in 3:
				f(r, "cilindro", Vector3(0.35, 1.2, 0.35), Color("8a5a33"), Vector3(-0.3 + k * 0.32, 0.18 + (0.28 if k == 1 else 0.0), 0), Vector3(0, 0, 90))
		"nube":
			for d in [[0, 0.3, 1.0], [0.55, 0.2, 0.7], [-0.55, 0.2, 0.75], [0.15, 0.55, 0.7]]:
				f(r, "esfera", Vector3(d[2], d[2] * 0.8, d[2] * 0.8), Color.WHITE, Vector3(d[0], d[1], 0))
		# ---------------- rocas
		"roca":
			f(r, "esfera", Vector3(1.3, 0.95, 1.1), Color("8b8f9c"), Vector3(0, 0.45, 0))
			f(r, "esfera", Vector3(0.8, 0.7, 0.7), Color("a3a7b3"), Vector3(0.4, 0.5, 0.1))
			f(r, "esfera", Vector3(0.5, 0.4, 0.5), Color("757a87"), Vector3(-0.45, 0.3, 0.2))
		"piedra":
			f(r, "esfera", Vector3(0.6, 0.38, 0.5), Color("9a9eaa"), Vector3(0, 0.19, 0))
		"rocas":
			f(r, "esfera", Vector3(0.8, 0.55, 0.7), Color("8b8f9c"), Vector3(-0.3, 0.27, 0))
			f(r, "esfera", Vector3(0.55, 0.4, 0.5), Color("a3a7b3"), Vector3(0.35, 0.2, 0.15))
			f(r, "esfera", Vector3(0.35, 0.26, 0.3), Color("757a87"), Vector3(0.05, 0.13, 0.4))
		"cristal":
			for d in [[0, 1.3, 0.35, 0], [0.3, 0.9, 0.25, 20], [-0.3, 0.8, 0.25, -22]]:
				f(r, "cono", Vector3(d[2], d[1], d[2]), Color("5cd6ff"), Vector3(d[0], d[1] / 2.0, 0), Vector3(0, 0, d[3]), 0.5)
		# ---------------- construcciones
		"casa":
			f(r, "caja", Vector3(1.8, 1.2, 1.6), Color("f0d9b5"), Vector3(0, 0.6, 0))
			f(r, "prisma", Vector3(2.2, 0.9, 1.9), Color("c2543a"), Vector3(0, 1.65, 0))
			f(r, "caja", Vector3(0.4, 0.7, 0.05), Color("7a4a2a"), Vector3(0, 0.35, 0.82))
			f(r, "caja", Vector3(0.36, 0.36, 0.05), Color("7ec8f5"), Vector3(0.55, 0.75, 0.82))
			f(r, "caja", Vector3(0.28, 0.5, 0.28), Color("8b8f9c"), Vector3(-0.6, 2.0, 0))
		"torre":
			f(r, "cilindro", Vector3(1.2, 2.8, 1.2), Color("b6bac6"), Vector3(0, 1.4, 0))
			f(r, "cilindro", Vector3(1.5, 0.3, 1.5), Color("9a9eaa"), Vector3(0, 2.9, 0))
			f(r, "cono", Vector3(1.5, 1.1, 1.5), Color("c2543a"), Vector3(0, 3.55, 0))
			f(r, "caja", Vector3(0.2, 0.4, 0.05), Color("1f1b2e"), Vector3(0, 1.8, 0.6))
		"castillo":
			f(r, "caja", Vector3(3.0, 1.6, 1.2), Color("b6bac6"), Vector3(0, 0.8, 0))
			for lado in [-1, 1]:
				f(r, "cilindro", Vector3(0.9, 2.4, 0.9), Color("9a9eaa"), Vector3(lado * 1.5, 1.2, 0))
				f(r, "cono", Vector3(1.1, 0.8, 1.1), Color("6d4aff"), Vector3(lado * 1.5, 2.8, 0))
			for k in 5:
				f(r, "caja", Vector3(0.3, 0.3, 0.3), Color("b6bac6"), Vector3(-1.0 + k * 0.5, 1.75, 0.45))
			f(r, "caja", Vector3(0.6, 0.9, 0.05), Color("7a4a2a"), Vector3(0, 0.45, 0.62))
		"edificio":
			f(r, "caja", Vector3(1.8, 4.0, 1.8), Color("8fa3b8"), Vector3(0, 2.0, 0))
			for fila in 5:
				for col in 3:
					f(r, "caja", Vector3(0.3, 0.4, 0.04), Color("fde68a") if (fila + col) % 3 == 0 else Color("38546e"), Vector3(-0.5 + col * 0.5, 0.7 + fila * 0.65, 0.92))
			f(r, "caja", Vector3(1.9, 0.15, 1.9), Color("5b6b7d"), Vector3(0, 4.05, 0))
		"tienda":
			f(r, "cono", Vector3(1.8, 1.7, 1.8), Color("e5484d"), Vector3(0, 0.85, 0))
			f(r, "cono", Vector3(0.5, 0.9, 0.1), Color("fde68a"), Vector3(0, 0.45, 0.82))
		"cerca":
			for k in 4:
				f(r, "caja", Vector3(0.14, 0.8, 0.1), Color("b07a45"), Vector3(-0.75 + k * 0.5, 0.4, 0))
			f(r, "caja", Vector3(1.8, 0.1, 0.06), Color("c58b52"), Vector3(0, 0.6, 0.05))
			f(r, "caja", Vector3(1.8, 0.1, 0.06), Color("c58b52"), Vector3(0, 0.3, 0.05))
		"farol":
			f(r, "cilindro", Vector3(0.12, 2.0, 0.12), Color("374151"), Vector3(0, 1.0, 0))
			f(r, "caja", Vector3(0.35, 0.4, 0.35), Color("fde68a"), Vector3(0, 2.15, 0), Vector3.ZERO, 1.2)
			f(r, "cono", Vector3(0.5, 0.25, 0.5), Color("374151"), Vector3(0, 2.45, 0))
		"cartel":
			f(r, "cilindro", Vector3(0.1, 1.0, 0.1), Color("7a4a2a"), Vector3(0, 0.5, 0))
			f(r, "caja", Vector3(0.9, 0.5, 0.08), Color("c58b52"), Vector3(0, 1.1, 0))
			f(r, "caja", Vector3(0.5, 0.06, 0.1), Color("fef3c7"), Vector3(0, 1.1, 0.02))
		"arco":
			for lado in [-1, 1]:
				f(r, "cilindro", Vector3(0.4, 2.0, 0.4), Color("b6bac6"), Vector3(lado * 0.9, 1.0, 0))
			f(r, "caja", Vector3(2.4, 0.4, 0.5), Color("9a9eaa"), Vector3(0, 2.2, 0))
			f(r, "esfera", Vector3(0.3, 0.3, 0.3), Color("6d4aff"), Vector3(0, 2.55, 0), Vector3.ZERO, 0.6)
		# ---------------- cosas
		"caja":
			f(r, "caja", Vector3(0.9, 0.9, 0.9), Color("c58b52"), Vector3(0, 0.45, 0))
			f(r, "caja", Vector3(0.95, 0.1, 0.95), Color("8a5a33"), Vector3(0, 0.1, 0))
			f(r, "caja", Vector3(0.95, 0.1, 0.95), Color("8a5a33"), Vector3(0, 0.8, 0))
		"barril":
			f(r, "cilindro", Vector3(0.8, 1.0, 0.8), Color("a9764a"), Vector3(0, 0.5, 0))
			for y in [0.25, 0.75]:
				f(r, "cilindro", Vector3(0.85, 0.08, 0.85), Color("4b5563"), Vector3(0, y, 0))
		"cofre":
			f(r, "caja", Vector3(1.0, 0.5, 0.6), Color("a9764a"), Vector3(0, 0.25, 0))
			f(r, "cilindro", Vector3(0.6, 1.0, 0.5), Color("8a5a33"), Vector3(0, 0.55, 0), Vector3(0, 0, 90))
			f(r, "caja", Vector3(0.14, 0.2, 0.05), Color("fbbf24"), Vector3(0, 0.45, 0.32), Vector3.ZERO, 0.6)
		"fogata":
			for k in 3:
				f(r, "cilindro", Vector3(0.12, 0.7, 0.12), Color("6b3f2a"), Vector3(0, 0.1, 0), Vector3(80, k * 60, 0))
			f(r, "cono", Vector3(0.4, 0.6, 0.4), Color("f97316"), Vector3(0, 0.45, 0), Vector3.ZERO, 1.0)
			f(r, "cono", Vector3(0.22, 0.4, 0.22), Color("fde047"), Vector3(0, 0.4, 0), Vector3.ZERO, 1.2)
		"bandera":
			f(r, "cilindro", Vector3(0.08, 2.2, 0.08), Color("e5e7eb"), Vector3(0, 1.1, 0))
			f(r, "caja", Vector3(0.8, 0.5, 0.04), Color("e5484d"), Vector3(0.44, 1.9, 0))
			f(r, "esfera", Vector3(0.14, 0.14, 0.14), Color("fbbf24"), Vector3(0, 2.25, 0), Vector3.ZERO, 0.6)
		_:
			f(r, "caja", Vector3(0.8, 0.8, 0.8), Color("c084fc"), Vector3(0, 0.4, 0))


## Mueve brazos y piernas (caminar). t = tiempo; fuerza 0 = quieto.
static func animar(raiz: Node3D, t: float, fuerza: float) -> void:
	for par in [["pierna_i", 0.0], ["pierna_d", PI], ["brazo_i", PI], ["brazo_d", 0.0]]:
		var n := raiz.find_child(par[0], true, false)
		if n:
			(n as Node3D).rotation.x = sin(t * 11.0 + par[1]) * 0.7 * fuerza
