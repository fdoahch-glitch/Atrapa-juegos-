extends Node3D
## Ambiente de un mundo 3D: clima (lluvia, tormenta, nieve, ventisca, erupción, variable), hora del día
## (día, atardecer, noche o ciclo que va pasando), el perseguidor que te alcanza si chocas,
## y la ropa (skin y accesorios) del personaje.

const Mundo3D := preload("res://scripts/mundo3d.gd")
const Importar := preload("res://scripts/importar.gd")
const Progreso := preload("res://scripts/progreso.gd")
const CICLO_S := 360.0    # un día completo dura 6 minutos

var nivel: Dictionary = {}
var reglas: Dictionary = {}
var _we: WorldEnvironment
var _sol: DirectionalLight3D
var _cam: Camera3D
var _part: CPUParticles3D
var _clima := ""            # clima que se ve ahora
var _clima_t := 0.0
var _destello := 0.0
var _sig_rayo := 4.0
var _t := 0.0
var _cielo0: Array = []
var _lejos0 := Color.WHITE
var persigue := false
var acercamiento := 0.0     # 0 = lejos, 1 = te atrapó
var _hubo := false          # ya te persiguió
var sobrevivio := false     # superaste una persecución
var _rex: Node3D


func config(n: Dictionary, r: Dictionary, we: WorldEnvironment, sol: DirectionalLight3D, cam: Camera3D) -> void:
	nivel = n
	reglas = r
	_we = we
	_sol = sol
	_cam = cam
	var env: Environment = _we.environment
	var sky: ProceduralSkyMaterial = env.sky.sky_material
	_cielo0 = [sky.sky_top_color, sky.sky_horizon_color]
	_lejos0 = sky.ground_bottom_color
	var rend: Dictionary = r.get("rend", {})
	env.glow_enabled = bool(rend.get("bloom", false))
	if env.glow_enabled:
		env.glow_intensity = 0.7
		env.glow_bloom = 0.1
	_sol.shadow_enabled = bool(rend.get("sombras", false))
	persigue = bool(n.get("perseguidor", false))
	if persigue:
		_crear_perseguidor()
	reiniciar()


func reiniciar() -> void:
	_t = 0.0
	acercamiento = 0.0
	_hubo = false
	sobrevivio = false
	_clima_t = 0.0
	_poner_clima(_clima_base())
	_aplicar_hora()


# ------------------------------------------------------------------ clima
func _clima_base() -> String:
	var c := str(nivel.get("clima", ""))
	return "" if c == "variable" else c


func _poner_clima(c: String) -> void:
	if c == _clima and _part != null:
		return
	_clima = c
	if _part:
		_part.queue_free()
		_part = null
	if c in ["", "ninguno"]:
		_niebla(0.0, Color.WHITE)
		return
	var p := CPUParticles3D.new()
	p.emitting = true
	p.local_coords = false
	p.preprocess = 3.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	var mesh := BoxMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	match c:
		"lluvia", "tormenta":
			p.amount = 900 if c == "tormenta" else 600
			p.lifetime = 0.7
			p.emission_box_extents = Vector3(9, 0.5, 18)
			p.direction = Vector3(0.15, -1, 0.1)
			p.spread = 4.0
			p.initial_velocity_min = 26.0
			p.initial_velocity_max = 32.0
			mesh.size = Vector3(0.025, 0.9, 0.025)
			mat.albedo_color = Color(0.75, 0.85, 1.0, 0.7)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_niebla(0.012 if c == "lluvia" else 0.022, Color(0.55, 0.62, 0.7))
		"nieve", "ventisca":
			p.amount = 500 if c == "nieve" else 1100
			p.lifetime = 3.0 if c == "nieve" else 1.6
			p.emission_box_extents = Vector3(10, 0.5, 18)
			p.direction = Vector3(0.1 if c == "nieve" else 0.8, -1, 0.0)
			p.spread = 18.0
			p.initial_velocity_min = 2.5 if c == "nieve" else 9.0
			p.initial_velocity_max = 4.5 if c == "nieve" else 14.0
			mesh.size = Vector3(0.16, 0.16, 0.16)
			mat.albedo_color = Color(1, 1, 1, 0.95)
			_niebla(0.012 if c == "nieve" else 0.045, Color(0.85, 0.9, 0.95))
		"erupcion":
			p.amount = 160
			p.lifetime = 2.6
			p.emission_box_extents = Vector3(12, 0.5, 20)
			p.direction = Vector3(0, -1, 0)
			p.spread = 8.0
			p.initial_velocity_min = 3.0
			p.initial_velocity_max = 8.0
			mesh.size = Vector3(0.16, 0.16, 0.16)
			mat.albedo_color = Color(1.0, 0.45, 0.1)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.4, 0.05)
			_niebla(0.014, Color(0.45, 0.2, 0.12))
	mesh.material = mat
	p.mesh = mesh
	add_child(p)
	_part = p


func _niebla(dens: float, col: Color) -> void:
	var env: Environment = _we.environment
	env.fog_enabled = dens > 0.0
	env.fog_density = dens
	env.fog_sky_affect = 0.25
	env.fog_light_color = col


# ------------------------------------------------------------------ hora
func _factor_noche() -> float:
	var h := str(nivel.get("hora", ""))
	match h:
		"dia", "":
			return 0.0
		"atardecer":
			return 0.35
		"noche":
			return 1.0
	# ciclo: de día 0-172 s, anochece 172-188, noche 188-346, amanece 346-360
	var c := fposmod(_t, CICLO_S)
	if c < 172.0:
		return 0.0
	if c < 188.0:
		return (c - 172.0) / 16.0
	if c < 346.0:
		return 1.0
	return 1.0 - (c - 346.0) / 14.0


func _aplicar_hora() -> void:
	var k := _factor_noche()
	var env: Environment = _we.environment
	var sky: ProceduralSkyMaterial = env.sky.sky_material
	var noche_a := Color(0.03, 0.05, 0.16)
	var noche_b := Color(0.1, 0.12, 0.3)
	var atard := Color(1.0, 0.55, 0.35)
	var arriba: Color = (_cielo0[0] as Color).lerp(noche_a, k)
	var horiz: Color = (_cielo0[1] as Color).lerp(noche_b, k)
	if str(nivel.get("hora", "")) == "atardecer":
		horiz = (_cielo0[1] as Color).lerp(atard, 0.6)
	elif str(nivel.get("hora", "")) == "ciclo" and k > 0.0 and k < 1.0:
		horiz = horiz.lerp(atard, sin(k * PI) * 0.55)
	sky.sky_top_color = arriba
	sky.sky_horizon_color = horiz
	sky.ground_horizon_color = horiz
	sky.ground_bottom_color = _lejos0.lerp(noche_a, k * 0.8)
	env.ambient_light_energy = lerpf(0.75, 0.28, k)
	_sol.light_energy = lerpf(1.0, 0.12, k)
	if str(nivel.get("hora", "")) != "":
		_sol.rotation_degrees.x = lerpf(-55.0, -15.0, k)


# ------------------------------------------------------------------ perseguidor
func _crear_perseguidor() -> void:
	var id := str(nivel.get("perseguidor_modelo", ""))
	if id == "":
		id = "g:Dino_Trex.glb"
	if Importar.cargar_glb(id) != null:
		_rex = Importar.modelo(id, 3.4)
		_rex.rotation_degrees.y = 180.0
	else:
		_rex = Mundo3D.sprite("🦖", 3.4)
		(_rex as Sprite3D).billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_rex.visible = false
	add_child(_rex)


## Un golpe: el perseguidor se acerca. Devuelve true si ya te atrapó.
func golpe() -> bool:
	if not persigue:
		return false
	acercamiento = minf(1.0, acercamiento + 0.4)
	_hubo = true
	return acercamiento >= 1.0


func tick(dt: float, dist: float, px: float) -> void:
	_t += dt
	_aplicar_hora()
	# clima variable: despejado → lluvia → tormenta → …
	if str(nivel.get("clima", "")) == "variable":
		_clima_t += dt
		var fase := int(_clima_t / 40.0) % 3
		_poner_clima(["", "lluvia", "tormenta"][fase])
	if _part and _cam:
		_part.global_position = Vector3(_cam.global_position.x, _cam.global_position.y + 9.0, _cam.global_position.z - 8.0)
	# rayos de la tormenta
	if _clima == "tormenta":
		_sig_rayo -= dt
		if _sig_rayo <= 0.0:
			_destello = 0.18
			_sig_rayo = randf_range(3.0, 8.0)
	if _destello > 0.0:
		_destello -= dt
		(_we.environment as Environment).ambient_light_energy = 2.2
	# el perseguidor se aleja si no chocas
	if persigue and acercamiento > 0.0:
		acercamiento = maxf(0.0, acercamiento - dt * 0.05)
		if acercamiento <= 0.0 and _hubo:
			sobrevivio = true
	if _rex:
		_rex.visible = persigue and acercamiento > 0.03
		var atras := lerpf(16.0, 3.0, acercamiento)
		_rex.position = Vector3(px * 0.5 + sin(_t * 1.4) * 0.6, 0.0, -dist + atras)


# ------------------------------------------------------------------ ropa
func vestir(heroe: Node3D) -> void:
	var d := Progreso.leer()
	# skin: tiñe el modelo
	for s in reglas.get("skins", []):
		if str(s["id"]) == str(d["skin"]) and (d["skins"] as Array).has(s["id"]):
			_teñir(heroe, Color(str(s["color"])))
	# accesorios: dibujos pegados al personaje (solo en modelos 3D)
	if heroe is Sprite3D:
		return
	var puestos: Array = d["puestos"]
	for a in reglas.get("accesorios", []):
		if not puestos.has(a["id"]):
			continue
		var pos := Vector3(0, 1.78, 0.0)
		var tam := 0.8
		match str(a["lugar"]):
			"ojos":
				pos = Vector3(0, 1.45, -0.28)
				tam = 0.6
			"pies":
				pos = Vector3(0, 0.12, 0.0)
				tam = 0.9
			"cuerpo":
				pos = Vector3(0, 0.9, -0.3)
				tam = 1.0
		var sp := Mundo3D.sprite(str(a["emoji"]), tam)
		sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sp.position = pos
		heroe.add_child(sp)


func _teñir(n: Node, c: Color) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for i in m.get_surface_override_material_count():
			var mat := m.get_active_material(i)
			if mat is BaseMaterial3D:
				var copia: BaseMaterial3D = (mat as BaseMaterial3D).duplicate()
				copia.albedo_color = copia.albedo_color.lerp(c, 0.55)
				m.set_surface_override_material(i, copia)
