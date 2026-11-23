extends Control
## Motor del juego de plataformas. Se usa tanto para "Probar" dentro del
## creador como en el juego exportado (Windows, Android, web).

signal salir
signal nivel_terminado(gano: bool, icono: String, titulo: String, sub: String)

const Dibujo := preload("res://scripts/dibujo.gd")
const Capa := preload("res://scripts/capa.gd")
const Sonido := preload("res://scripts/sonido.gd")
const Estilo := preload("res://scripts/estilo.gd")

const T := 48
const PW := 0.62
const PH := 0.88
const MOVER := 300.0
const GRAV := 2300.0
const SALTO := 860.0
const RESORTE := 1300.0

var nivel: Dictionary = {}
var tema: Dictionary = {}
var escala := 1.0
var camy := 0.0
var con_salir := false
var tactil := false

var _mundo: Node2D
var _hud: Node2D
var _sonido: Node
var _fin: Control
var _btn_sonido: Button

# estado de la partida
var t := 0.0
var puntos := 0
var recogidos := 0
var total := 0
var vidas := 3
var estado := "jugar"      # jugar | gano | perdio
var inv := 0.0
var cam := 0.0
var inicio := Vector2.ZERO
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var cara := 1.0
var suelo := false
var coyote := 0.0
var buffer := 0.0
var salto_pulsado := false
var plats: Array[Rect2] = []
var items_plat: Array = []
var pinchos: Array = []
var resortes: Array = []
var recogibles: Array = []
var meta: Variant = null
var enemigos: Array = []
var decos: Array = []
var dedos := {}            # índice de dedo -> "izq" | "der" | "salto"
# reglas del juego y campaña (varios niveles)
var reglas: Dictionary = {}
var campana := false          # si es true, el fin de nivel lo maneja Partida
var puntos_base := 0          # puntos que traes de niveles anteriores
var etiqueta_nivel := ""      # «Nivel 2 de 3»
var tiempo_rest := -1.0       # segundos que quedan (-1 = sin límite)
var _msg := ""
var _msg_t := 0.0


func iniciar(n: Dictionary, forzar_tactil: bool = false, mostrar_salir: bool = false) -> void:
	nivel = n.duplicate(true)
	reglas = Datos.reglas_completas(nivel.get("reglas", {}) if nivel.get("reglas", {}) is Dictionary else {})
	tema = Datos.tema_de(nivel)
	tactil = forzar_tactil or DisplayServer.is_touchscreen_available()
	con_salir = mostrar_salir
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sonido = Sonido.new()
	add_child(_sonido)
	_mundo = Capa.new()
	_mundo.al_dibujar = _dibujar_mundo
	add_child(_mundo)
	var fl: int = ["", "bn", "sepia", "retro", "vineta", "frio", "calido", "ondas", "crt", "dibujo", "neon", "agua"].find(str(nivel.get("filtro", "")))
	if fl > 0:
		_filtro = ColorRect.new()
		_filtro.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sh := Shader.new()
		sh.code = FILTRO_SHADER
		var mt := ShaderMaterial.new()
		mt.shader = sh
		mt.set_shader_parameter("modo", fl)
		_filtro.material = mt
		add_child(_filtro)
		_filtro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if bool(reglas.get("paleta_todo", false)) and Datos.pal_efectiva("") != "":
		var pf := ColorRect.new()
		pf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var psh := Shader.new()
		psh.code = PALETA_SHADER
		var pm := ShaderMaterial.new()
		pm.shader = psh
		var lut := Datos.pal_lut(Datos.pal_efectiva(""))
		var li := Image.create_from_data(256, 1, false, Image.FORMAT_RGB8, lut)
		pm.set_shader_parameter("lut", ImageTexture.create_from_image(li))
		pm.set_shader_parameter("fuerza", Datos.pal_fuerza())
		pf.material = pm
		add_child(pf)
		pf.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud = Capa.new()
	_hud.al_dibujar = _dibujar_hud
	add_child(_hud)
	_btn_sonido = Button.new()
	_btn_sonido.icon = Datos.textura("🔊")
	_btn_sonido.custom_minimum_size = Vector2(52, 44)
	_btn_sonido.expand_icon = true
	_btn_sonido.add_theme_constant_override("icon_max_width", 28)
	_btn_sonido.position = Vector2(12, 58)
	_btn_sonido.focus_mode = Control.FOCUS_NONE
	_btn_sonido.pressed.connect(_alternar_sonido)
	add_child(_btn_sonido)
	_btn_pausa = Button.new()
	_btn_pausa.icon = Datos.textura("⏸")
	_btn_pausa.custom_minimum_size = Vector2(52, 44)
	_btn_pausa.expand_icon = true
	_btn_pausa.add_theme_constant_override("icon_max_width", 28)
	_btn_pausa.position = Vector2(70, 58)
	_btn_pausa.focus_mode = Control.FOCUS_NONE
	_btn_pausa.pressed.connect(_pausar)
	add_child(_btn_pausa)
	if mostrar_salir:
		var b := Button.new()
		b.text = "  Editar"
		b.icon = Datos.textura("↩")
		b.focus_mode = Control.FOCUS_NONE
		b.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		b.offset_left = -140.0
		b.offset_right = -15.0
		b.offset_top = 10.0
		b.offset_bottom = 56.0
		b.pressed.connect(func(): salir.emit())
		add_child(b)
	resetear()


## Menú de pausa: continuar, sonido, volumen, créditos y salir.
func _pausar() -> void:
	if _menu_pausa != null:
		_menu_pausa.queue_free()
		_menu_pausa = null
		return
	if estado != "jugar":
		return
	var idi := str(reglas.get("idioma", "es"))
	var fondo := ColorRect.new()
	fondo.color = Color(0.08, 0.06, 0.23, 0.72)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_pausa = fondo
	var centro := CenterContainer.new()
	fondo.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	centro.add_child(v)
	var l := Label.new()
	l.text = "Pausa"
	l.add_theme_font_size_override("font_size", 44)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var mk := func(txt: String, ico: String, fn: Callable, amarillo: bool = false) -> Button:
		var b := Button.new()
		b.text = "  " + txt
		b.icon = Datos.textura(ico)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 30)
		b.custom_minimum_size = Vector2(280, 56)
		b.add_theme_font_size_override("font_size", 24)
		Estilo.pintar(b, Estilo.AMARILLO if amarillo else Color(1, 1, 1, 0.28), Color("4a3300") if amarillo else Color.WHITE)
		b.pressed.connect(fn)
		v.add_child(b)
		return b
	var cont: Button = mk.call("Continuar", "▶", _pausar, true)
	var vol := Label.new()
	vol.add_theme_font_size_override("font_size", 22)
	vol.add_theme_color_override("font_color", Color.WHITE)
	vol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var pv := func():
		vol.text = "Volumen: %d%%" % roundi(clampf(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.0, 1.0) * 100.0)
	var cambiar_vol := func(d: float):
		var lin := clampf(db_to_linear(AudioServer.get_bus_volume_db(0)) + d, 0.0, 1.0)
		AudioServer.set_bus_volume_db(0, linear_to_db(maxf(lin, 0.001)))
		pv.call()
	pv.call()
	v.add_child(vol)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 10)
	v.add_child(hb)
	for par in [["➖", -0.1], ["➕", 0.1]]:
		var b2 := Button.new()
		b2.icon = Datos.textura(par[0])
		b2.expand_icon = true
		b2.custom_minimum_size = Vector2(80, 50)
		b2.pressed.connect(func(): cambiar_vol.call(par[1]))
		hb.add_child(b2)
	mk.call("Sonido", "🔊", _alternar_sonido)
	if str(reglas.get("creditos", "")) != "":
		var cr := Label.new()
		cr.text = "Créditos: " + str(reglas["creditos"])
		cr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cr.custom_minimum_size = Vector2(300, 0)
		cr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cr.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		v.add_child(cr)
	mk.call("Salir", "🚪", func():
		if con_salir or campana:
			salir.emit()
		elif not OS.has_feature("web") and not OS.has_feature("android"):
			get_tree().quit())
	Datos.traducir_arbol(fondo, idi)
	cont.grab_focus()


func _alternar_sonido() -> void:
	_sonido.silencio = not _sonido.silencio
	_btn_sonido.icon = Datos.textura("🔇" if _sonido.silencio else "🔊")


## Aplica vidas, tiempo y puntos de arranque según las reglas.
func _aplicar_reglas() -> void:
	vidas = int(reglas["vidas"])
	_poner_poder()
	_poner_fisica()
	puntos = puntos_base
	tiempo_rest = float(reglas["tiempo"]) if int(reglas["tiempo"]) > 0 else -1.0
	_msg = ""
	_msg_t = 0.0


# ------------------------------------------------------------------ mascota y personaje con poder
const Tienda_ := preload("res://scripts/tienda.gd")
const PODERES := [["", "Ninguno"], ["salto", "Salto alto"], ["escudo", "Escudo"], ["escudo2", "Doble escudo"], ["vida", "Vida extra"], ["iman", "Imán"], ["bono", "Más puntos"]]
var _escudos := 0
var _iman := false
var _iman_s := 0.0
var _doble_s := 0.0
var _bono := 1.0
var _k_salto := 1.0
var _fis: Dictionary = {}
var _mec: Dictionary = {}
var _aire := 0
var _dash := 0.0
var _dash_cd := 0.0
var _disp_cd := 0.0
var _esp_cd := 0.0
var _esp_t := 0.0
var _conj_cd := 0.0
var _bloques: Array = []          # bloques creados por el mago: {"r": Rect2, "it": Dictionary}
var bolas: Array = []             # bolitas del jugador
var bolas_e: Array = []           # bolitas de enemigos
var _planeo := false
# trío de héroes (juegos con nivel["trio"])
const TRIO := [["a:caballero", "Caballero", {"espada": true}, 0.9, 0.9], ["a:mago", "Mago", {"conjurar": true}, 1.0, 1.0], ["a:ninja", "Ladrón", {"doble_salto": true, "disparar": true, "correr": true}, 1.0, 1.15]]
var _trio := false
var _hero_i := 0
var _k_vel := 1.0
const Imp := preload("res://scripts/importar.gd")
var _sfx_map: Dictionary = {}
var _fx_map: Dictionary = {}
var _parts: Array = []
var _part_t := 0.0
var llaves: Array = []
var puertas: Array = []
var botones: Array = []
var moviles: Array = []
var puentes: Array = []
var zonas: Array = []     # zonas especiales: agua, hielo, viento, corriente, lava
var rutas: Array = []     # plataformas que siguen un camino (Curve2D)
var _z_agua := false
var _z_fric := 1.0
var pendulos: Array = []
var cajas: Array = []
# Física real de Godot: el terreno fijo, el héroe y los objetos que ruedan viven en su propio mundo.
var _pw: SubViewport = null
var _pw_h: CharacterBody2D = null
var _pw_ok := false          # el mundo ya dio su primer paso (antes de eso se usa el cálculo propio)
var _pw_espera := false
var _pw_gen := 0
var _pw_rig: Array = []      # ruedas y pelotas: {"it", "body"}
var _pw_cuerdas: Array = []  # cuerdas: {"it", "segs": [RigidBody2D]}
var _n_llaves := 0
var _llaves_disp := 0
var _n_mon := 0
var _n_ene := 0
var _eventos: Array = []
var _meta_oculta := false
var _temblor := 0.0
var _boton_hecho := false
var _luz_tex: GradientTexture2D
var _filtro: ColorRect
var _menu_pausa: Control
var _btn_pausa: Button
const PART := {
	"chispas": {"col": [Color("ffe066"), Color("fff4b0")], "v": 170.0, "vida": 0.55, "g": 420.0, "t": 4.0},
	"estrellas": {"col": [Color("ffd23f"), Color("ff9ff3")], "v": 150.0, "vida": 0.7, "g": 200.0, "t": 5.0},
	"polvo": {"col": [Color(0.82, 0.76, 0.66, 0.8)], "v": 70.0, "vida": 0.5, "g": -30.0, "t": 6.0},
	"humo": {"col": [Color(0.62, 0.62, 0.68, 0.55)], "v": 25.0, "vida": 1.4, "g": -60.0, "t": 8.0},
	"fuego": {"col": [Color("ff7a1a"), Color("ffd23f")], "v": 35.0, "vida": 0.8, "g": -120.0, "t": 6.0},
	"nieve": {"col": [Color.WHITE], "v": 20.0, "vida": 2.0, "g": 60.0, "t": 3.0},
	"explosion": {"col": [Color("ff5a36"), Color("ffd23f"), Color.WHITE], "v": 260.0, "vida": 0.6, "g": 200.0, "t": 6.0}}
const PALETA_SHADER := """shader_type canvas_item;
uniform sampler2D tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D lut : filter_nearest;
uniform float fuerza = 0.8;
void fragment() {
	vec4 c = texture(tex, SCREEN_UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 p = texture(lut, vec2(g, 0.5)).rgb;
	COLOR = vec4(mix(c.rgb, p, fuerza), c.a);
}
"""
const FILTRO_SHADER := """shader_type canvas_item;
uniform int modo = 0;
uniform sampler2D tex : hint_screen_texture, filter_linear_mipmap;
void fragment() {
	vec2 uv = SCREEN_UV;
	if (modo == 7) { uv += vec2(sin(uv.y * 24.0 + TIME * 3.0), cos(uv.x * 20.0 + TIME * 2.4)) * 0.006; }
	if (modo == 11) { uv += vec2(sin(uv.y * 30.0 + TIME * 2.0) * 0.004, cos(uv.x * 26.0 + TIME * 1.7) * 0.003); }
	vec4 c = texture(tex, uv);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	if (modo == 1) { c.rgb = vec3(g); }
	else if (modo == 2) { c.rgb = vec3(g * 1.1, g * 0.95, g * 0.75); }
	else if (modo == 3) { vec2 px = vec2(200.0, 112.0); c = texture(tex, floor(uv * px) / px); c.rgb = floor(c.rgb * 6.0) / 6.0; }
	else if (modo == 4) { float d = distance(uv, vec2(0.5)); c.rgb *= 1.0 - smoothstep(0.3, 0.85, d) * 0.8; }
	else if (modo == 5) { c.rgb *= vec3(0.85, 0.95, 1.15); }
	else if (modo == 6) { c.rgb *= vec3(1.15, 1.0, 0.82); }
	else if (modo == 8) { float l = 0.85 + 0.15 * sin(uv.y * 540.0); c.rgb *= l; c.rgb *= 1.0 - smoothstep(0.35, 0.9, distance(uv, vec2(0.5))) * 0.6; c.r += 0.03 * sin(uv.y * 90.0 + TIME * 6.0); }
	else if (modo == 9) { c.rgb = floor(c.rgb * 4.0 + 0.5) / 4.0; c.rgb = mix(c.rgb, vec3(dot(c.rgb, vec3(0.33))), -0.35); }
	else if (modo == 10) { c.rgb = c.rgb * 1.25 + pow(max(c.rgb - 0.55, 0.0), vec3(1.5)) * 1.2; c.rgb *= vec3(0.9, 1.0, 1.15); }
	else if (modo == 11) { c.rgb *= vec3(0.6, 0.9, 1.15); c.rgb += vec3(0.0, 0.04, 0.09); }
	COLOR = c;
}
"""
var _lento := 1.0
var _inv_golpe := 1.6
var _mult := {}
var _m3: Node3D


func _tiene_mascota() -> bool:
	return str(reglas.get("mascota", "")) != ""


## Activa los poderes del personaje jugable y de la mascota al empezar el nivel.
func _poner_poder() -> void:
	_escudos = 0
	_iman = false
	_iman_s = 0.0
	_doble_s = 0.0
	_bono = 1.0
	_k_salto = 1.0
	_lento = 1.0
	_inv_golpe = 1.6
	_mult = {}
	var ids: Array = []
	if _tiene_mascota():
		ids.append(str(reglas.get("poder", "")))
	var ph := str(reglas.get("poder_heroe", ""))
	if ph != "":
		ids.append(ph)
	for id in ids:
		var e: Dictionary = Tienda_.EFECTOS.get(id, {})
		_escudos += int(e.get("esc", 0))
		vidas = mini(12, vidas + int(e.get("vida", 0)))
		_iman = _iman or bool(e.get("iman", false))
		_iman_s = maxf(_iman_s, float(e.get("iman_s", 0.0)))
		_doble_s = maxf(_doble_s, float(e.get("doble", 0.0)))
		_bono *= float(e.get("todo", 1.0))
		_k_salto *= float(e.get("salto", 1.0))
		_lento *= float(e.get("lento", 1.0))
		_inv_golpe = maxf(_inv_golpe, float(e.get("inv", 0.0)))
		for k in ["coin", "gem", "star", "enemy"]:
			if e.has(k):
				_mult[k] = float(_mult.get(k, 1.0)) * float(e[k])


## Física y mecánicas que eligió el creador (paneles «Física» y «Mecánicas»).
func _poner_fisica() -> void:
	_fis = Datos.fis_normal(reglas.get("fis", {}))
	_mec = Datos.mec_normal(reglas.get("mec", {}))
	_k_salto *= float(_fis["salto"])
	_sfx_map = Datos.sfx_normal(reglas.get("sonidos", {}))
	_fx_map = Datos.fx_normal(reglas.get("fx", {}))
	_k_vel = 1.0
	_trio = bool(nivel.get("trio", false))
	if _trio:
		_cambiar_heroe(_hero_i)
	bolas = []
	bolas_e = []
	_bloques = []
	_aire = 0


func _mecanica(k: String) -> bool:
	return bool(_mec.get(k, false))


## Trío: cambia de héroe (teclas 1, 2, 3). Cada uno tiene sus propias habilidades.
func _cambiar_heroe(i: int) -> void:
	_hero_i = clampi(i, 0, TRIO.size() - 1)
	var h: Array = TRIO[_hero_i]
	nivel["hero"] = h[0]
	_mec = Datos.mec_normal(reglas.get("mec", {}))
	for k in (h[2] as Dictionary).keys():
		_mec[k] = true
	_k_vel = float(h[4])
	_k_salto = _k_salto_base() * float(h[3])


func _k_salto_base() -> float:
	return float(_fis.get("salto", 1.0))


func _iman_act() -> bool:
	return _iman or t < _iman_s


func _vale(tipo: String) -> int:
	var m := _bono * float(_mult.get(tipo, 1.0))
	if t < _doble_s:
		m *= 2.0
	return int(round(int(reglas.get("pts_" + tipo, 1)) * m))


## El escudo de la mascota se come un golpe. Devuelve true si el golpe se absorbió.
func _absorber() -> bool:
	if _escudos <= 0:
		return false
	_escudos -= 1
	inv = 1.0
	_sonido.tocar(520.0, 0.2, "triangulo")
	_decir("¡Tu mascota te protegió!")
	return true


## Ayuda del imán: cuánto se agranda el alcance para recoger (en píxeles).
func _alcance() -> float:
	return 70.0 if _iman_act() else 0.0


## Pone a la mascota 3D junto al héroe.
func _mascota_3d(mundo: Node3D, p: Vector3, desf: Vector3) -> void:
	if not _tiene_mascota():
		return
	if _m3 == null or not is_instance_valid(_m3):
		_m3 = preload("res://scripts/mundo3d.gd").objeto(str(reglas["mascota"]), 0.75)
		if _m3 is Sprite3D:
			(_m3 as Sprite3D).billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		else:
			_m3.rotation_degrees.y = 180.0
		mundo.add_child(_m3)
	var vuelo := 0.8 if str(reglas["mascota"]).contains("pterodactylus") else 0.0
	_m3.position = p + desf + Vector3(0, vuelo + sin(t * 5.0) * 0.07, 0)
	_m3.visible = not (inv > 0.0 and int(t * 14.0) % 2 == 1) or _escudos > 0


## Dibuja a la mascota 2D junto al héroe (c2 = celda del héroe).
func _mascota_2d(ci: CanvasItem, c2: Vector2) -> void:
	if not _tiene_mascota():
		return
	var tx: Texture2D = Datos.textura(str(reglas["mascota"]))
	if tx == null:
		return
	var o := Vector2((c2.x - 0.85 * cara) * T, (c2.y + 0.35) * T + sin(t * 5.0) * 3.0)
	ci.draw_texture_rect(tx, Rect2(o, Vector2(T * 0.6, T * 0.6)), false)
	if _escudos > 0:
		ci.draw_arc(o + Vector2(T * 0.3, T * 0.3), T * 0.42, 0, TAU, 24, Color(0.4, 0.8, 1.0, 0.9), 3.0)


## Cuántos premios faltan para poder ganar (0 = ya puedes llegar a la meta).
func _faltan() -> int:
	var need := 0
	match str(reglas.get("meta", "meta")):
		"mitad":
			need = ceili(total * 0.5)
		"todo":
			need = total
	return maxi(0, need - recogidos)


func _decir(txt: String) -> void:
	_msg = Datos.traducir(txt, str(reglas.get("idioma", "es")))
	_msg_t = 2.5


## Se llama en cada cuadro: reloj de cuenta regresiva y mensajes.
func _reglas_tick(dt: float) -> void:
	_msg_t = maxf(0.0, _msg_t - dt)
	if estado != "jugar" or tiempo_rest < 0.0:
		return
	tiempo_rest -= dt
	if tiempo_rest <= 0.0:
		tiempo_rest = 0.0
		estado = "perdio"
		_sfx("perder")
		_mostrar_fin("⏰", "¡Se acabó el tiempo!", "Recogiste %d de %d premios" % [recogidos, total])


## Reloj, mensaje y nivel, dibujados sobre la pantalla del juego.
func _hud_extra(ci: CanvasItem) -> void:
	var f := ThemeDB.fallback_font
	if tiempo_rest >= 0.0:
		var seg := int(ceil(tiempo_rest))
		var txt := "%d:%02d" % [seg / 60, seg % 60]
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		var rojo := tiempo_rest < 10.0 and int(t * 3.0) % 2 == 0
		ci.draw_style_box(Estilo.caja(Color(0.7, 0.1, 0.1, 0.75) if rojo else Color(0, 0, 0, 0.45), 20), Rect2(size.x / 2.0 - w / 2.0 - 40, 10, w + 62, 40))
		Dibujo.emoji(ci, "⏰", Vector2(size.x / 2.0 - w / 2.0 - 18, 30), 24.0)
		ci.draw_string(f, Vector2(size.x / 2.0 - w / 2.0 + 4, 38), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
	if etiqueta_nivel != "":
		var w2 := f.get_string_size(etiqueta_nivel, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		ci.draw_string(f, Vector2(size.x - w2 - 16, size.y - 14) if tactil else Vector2(size.x - w2 - 16, 100), etiqueta_nivel, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.9))
	if _msg_t > 0.0:
		var w3 := f.get_string_size(_msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.6), 20), Rect2((size.x - w3) / 2.0 - 18, size.y * 0.25, w3 + 36, 46))
		ci.draw_string(f, Vector2((size.x - w3) / 2.0, size.y * 0.25 + 32), _msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)


func resetear() -> void:
	if _fin:
		_fin.queue_free()
		_fin = null
	t = 0.0
	recogidos = 0
	total = 0
	estado = "jugar"
	inv = 0.0
	plats = []
	items_plat = []
	pinchos = []
	resortes = []
	recogibles = []
	meta = null
	enemigos = []
	decos = []
	llaves = []
	puertas = []
	botones = []
	moviles = []
	puentes = []
	zonas = []
	rutas = []
	_z_agua = false
	_z_fric = 1.0
	pendulos = []
	cajas = []
	_pw_borrar()
	_n_llaves = 0
	_llaves_disp = 0
	_n_mon = 0
	_n_ene = 0
	_boton_hecho = false
	_parts = []
	_temblor = 0.0
	_eventos = []
	for ev in nivel.get("eventos", []):
		var e2: Dictionary = (ev as Dictionary).duplicate()
		e2["hecho"] = false
		_eventos.append(e2)
	_meta_oculta = _eventos.any(func(e): return e["haz"] == "meta")
	_aplicar_reglas()
	var pl: Dictionary = {"x": 1, "y": Datos.FILAS - 3}
	for it in nivel["items"]:
		var c: Dictionary = it.duplicate()
		match it["t"]:
			"plat":
				plats.append(Rect2(it["x"] * T, it["y"] * T, it["w"] * T, it["h"] * T))
				items_plat.append(c)
			"spike":
				pinchos.append(c)
			"spring":
				c["sq"] = 0.0
				resortes.append(c)
			"coin", "star", "gem":
				c["got"] = false
				recogibles.append(c)
				total += 1
			"goal":
				meta = c
			"enemy":
				enemigos.append({"it": c, "x": float(it["x"]), "x0": float(it["x"]), "dir": 1.0, "muerto": false, "sqt": 0.0,
					"r": float(it.get("r", 3)), "sp": float(it.get("sp", 60))})
			"deco":
				decos.append(c)
			"llave":
				c["got"] = false
				llaves.append(c)
			"puerta":
				c["abierta"] = false
				puertas.append(c)
			"boton":
				c["on"] = false
				botones.append(c)
			"platmov":
				var wm := int(it.get("w", 3))
				moviles.append({"it": c, "px": float(it["x"]) * T, "x0": float(it["x"]) * T, "dir": 1.0, "r": float(it.get("r", 3)) * T, "sp": float(it.get("sp", 60)),
					"rect": Rect2(float(it["x"]) * T, float(it["y"]) * T, wm * T, T * 0.4), "dx": 0.0})
			"puente":
				var wp := int(it.get("w", 4))
				puentes.append({"it": c, "rect": Rect2(float(it["x"]) * T, float(it["y"]) * T, wp * T, T * 0.4), "r0": Rect2(float(it["x"]) * T, float(it["y"]) * T, wp * T, T * 0.4), "est": 0, "t": 0.0, "vy": 0.0})
			"pendulo":
				pendulos.append({"it": c, "ax": (float(it["x"]) + 0.5) * T, "ay": float(it["y"]) * T, "largo": float(it.get("r", 3)) * T, "sp": float(it.get("sp", 60)) / 60.0, "ang": 0.0, "bx": 0.0, "by": 0.0})
			"caja":
				cajas.append({"it": c, "r": Rect2(float(it["x"]) * T, float(it["y"]) * T, T, T), "vy": 0.0})
			"zona":
				zonas.append({"it": c, "rect": Rect2(float(it["x"]) * T, float(it["y"]) * T, float(it.get("w", 4)) * T, float(it.get("h", 3)) * T), "z": str(it.get("z", "agua")), "area": null})
			"ruta":
				var cvr: Curve2D = Dibujo.ruta_curva(c)
				var wr := float(it.get("w", 3))
				var forma := str(it.get("forma", "vaiven"))
				rutas.append({"it": c, "curve": cvr, "len": maxf(1.0, cvr.get_baked_length()), "off": 0.0, "dir": 1.0, "sp": float(it.get("sp", 60)), "cerrada": forma in ["circulo", "cuadro"],
					"o": Vector2(float(it["x"]) * T, float(it["y"]) * T), "rect": Rect2(float(it["x"]) * T, float(it["y"]) * T, wr * T, T * 0.4), "dx": 0.0, "dy": 0.0})
			"rueda", "pelota", "cuerda":
				_pw_rig.append({"it": c, "t": str(it["t"])})
			"player":
				pl = it
	var pw := PW * T
	var ph := PH * T
	inicio = Vector2(float(pl["x"]) * T + (T - pw) / 2.0, float(pl["y"] + 1) * T - ph)
	pos = inicio
	vel = Vector2.ZERO
	cara = 1.0
	suelo = false
	coyote = 0.0
	buffer = 0.0
	escala = _escala()
	cam = maxf(0.0, inicio.x - size.x / escala / 2.0)
	camy = 0.0
	_pw_construir()


# ------------------------------------------------------------------ física real de Godot
func _pw_borrar() -> void:
	_pw_gen += 1
	_pw_ok = false
	_pw_espera = false
	if _pw != null:
		_pw.queue_free()
		_pw = null
	_pw_h = null
	_pw_rig = []
	_pw_cuerdas = []


func _pw_cuerpo(forma: Shape2D, tipo: int, capa: int, masc: int, p: Vector2) -> PhysicsBody2D:
	var b: PhysicsBody2D
	if tipo == 0:
		b = StaticBody2D.new()
	elif tipo == 1:
		b = CharacterBody2D.new()
	else:
		b = RigidBody2D.new()
	var cs := CollisionShape2D.new()
	cs.shape = forma
	b.add_child(cs)
	b.collision_layer = capa
	b.collision_mask = masc
	b.position = p
	_pw.add_child(b)
	return b


## Crea el mundo físico del nivel: suelo fijo, héroe y objetos que ruedan, se mecen o rebotan.
func _pw_construir() -> void:
	var pend := _pw_rig
	_pw_rig = []
	_pw = SubViewport.new()
	_pw.world_2d = World2D.new()
	_pw.size = Vector2i(2, 2)
	_pw.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_pw)
	for p in plats:
		var r: Rect2 = p
		var f := RectangleShape2D.new()
		f.size = r.size
		_pw_cuerpo(f, 0, 1, 0, r.get_center())
	var hf := RectangleShape2D.new()
	hf.size = Vector2(PW * T, PH * T)
	_pw_h = _pw_cuerpo(hf, 1, 2, 1, pos + hf.size / 2.0) as CharacterBody2D
	for z in zonas:
		var ar := Area2D.new()
		ar.collision_layer = 0
		ar.collision_mask = 2
		var zf := RectangleShape2D.new()
		zf.size = (z["rect"] as Rect2).size
		var zc := CollisionShape2D.new()
		zc.shape = zf
		ar.add_child(zc)
		ar.position = (z["rect"] as Rect2).get_center()
		_pw.add_child(ar)
		z["area"] = ar
	var gesc := GRAV / 980.0
	for o in pend:
		var it: Dictionary = o["it"]
		var cx := (float(it["x"]) + 0.5) * T
		var cy := (float(it["y"]) + 0.5) * T
		match str(o["t"]):
			"rueda", "pelota":
				var d := maxf(0.5, float(it.get("r", 1 if o["t"] == "pelota" else 2))) * T
				var cf := CircleShape2D.new()
				cf.radius = d / 2.0
				var rb := _pw_cuerpo(cf, 2, 1, 1, Vector2(float(it["x"]) * T + d / 2.0, float(it["y"]) * T + d / 2.0)) as RigidBody2D
				var mat := PhysicsMaterial.new()
				mat.friction = 1.0
				mat.bounce = 0.75 if o["t"] == "pelota" else 0.1
				rb.physics_material_override = mat
				rb.mass = 0.6 if o["t"] == "pelota" else 3.0
				rb.gravity_scale = gesc
				rb.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
				_pw_rig.append({"it": it, "t": o["t"], "body": rb, "d": d})
			"cuerda":
				var n := maxi(3, int(it.get("r", 4)) * 2)
				var anc := _pw_cuerpo(CircleShape2D.new(), 0, 0, 0, Vector2(cx, float(it["y"]) * T))
				var prev: PhysicsBody2D = anc
				var segs: Array = []
				for k in range(1, n + 1):
					var sf := CircleShape2D.new()
					sf.radius = 6.0
					var sg := _pw_cuerpo(sf, 2, 4, 1, Vector2(cx, float(it["y"]) * T + k * T * 0.5)) as RigidBody2D
					sg.mass = 0.25
					sg.gravity_scale = gesc
					sg.linear_damp = 0.4
					sg.angular_damp = 1.0
					var j := PinJoint2D.new()
					j.position = Vector2(cx, float(it["y"]) * T + (k - 0.5) * T * 0.5)
					j.softness = 0.0
					_pw.add_child(j)
					j.node_a = j.get_path_to(prev)
					j.node_b = j.get_path_to(sg)
					segs.append(sg)
					prev = sg
				_pw_cuerdas.append({"it": it, "segs": segs})


func _pw_vigilar() -> void:
	if _pw == null or _pw_ok or _pw_espera or not is_inside_tree():
		return
	_pw_espera = true
	var gen := _pw_gen
	await get_tree().physics_frame
	await get_tree().physics_frame
	if gen == _pw_gen and is_inside_tree():
		_pw_ok = true
		_pw_espera = false


## Mueve al héroe con la física de Godot. Devuelve el choque (o null).
func _pw_mover(m: Vector2) -> KinematicCollision2D:
	var mitad := Vector2(PW * T, PH * T) / 2.0
	_pw_h.position = pos + mitad
	var c := _pw_h.move_and_collide(m, false, 0.04)
	pos = _pw_h.position - mitad
	return c


## Las ruedas, pelotas y cuerdas se actualizan solas con el motor; aquí solo se leen para dibujarlas y empujarlas.
func _pw_tick() -> void:
	_pw.process_mode = Node.PROCESS_MODE_DISABLED if (_menu_pausa != null or estado != "jugar") else Node.PROCESS_MODE_INHERIT
	for o in _pw_rig:
		var b: RigidBody2D = o["body"]
		o["it"]["px"] = b.position.x
		o["it"]["py"] = b.position.y
		o["it"]["rot"] = b.rotation
		if b.position.y > Datos.FILAS * T + T * 4:
			b.position = Vector2(float(o["it"]["x"]) * T + float(o["d"]) / 2.0, float(o["it"]["y"]) * T)
			b.linear_velocity = Vector2.ZERO
	var caja := _caja().grow(6.0)
	for cu in _pw_cuerdas:
		var pts: Array = []
		pts.append(Vector2((float(cu["it"]["x"]) + 0.5) * T, float(cu["it"]["y"]) * T))
		for sg in cu["segs"]:
			var rb: RigidBody2D = sg
			pts.append(rb.position)
			if caja.has_point(rb.position):
				rb.apply_central_impulse(Vector2(vel.x * 0.02, 0.0))
		cu["it"]["pts"] = pts


# ------------------------------------------------------------------ entrada
func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode in [KEY_UP, KEY_W, KEY_SPACE]:
			salto_pulsado = true
		elif ev.keycode == KEY_ESCAPE:
			_pausar()
		elif ev.keycode == KEY_P:
			_pausar()
	elif ev is InputEventJoypadButton and ev.pressed:
		if ev.button_index in [JOY_BUTTON_A, JOY_BUTTON_B]:
			salto_pulsado = true
		elif ev.button_index == JOY_BUTTON_START:
			_pausar()
	elif ev is InputEventScreenTouch:
		if ev.pressed:
			var z := _zona(ev.position - global_position)
			if _trio:
				for i in TRIO.size():
					if Rect2(12 + i * 62, 110, 56, 56).has_point(ev.position - global_position):
						_cambiar_heroe(i)
			if z != "":
				dedos[ev.index] = z
				if z == "salto":
					salto_pulsado = true
		else:
			dedos.erase(ev.index)
	elif ev is InputEventScreenDrag:
		var z2 := _zona(ev.position - global_position)
		if z2 == "":
			dedos.erase(ev.index)
		else:
			if z2 == "salto" and dedos.get(ev.index, "") != "salto":
				salto_pulsado = true
			dedos[ev.index] = z2


## Mando (palanca izquierda o cruceta) y, si está activado, inclinar el celular.
func _eje_mando() -> float:
	var e := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	if absf(e) < 0.25:
		e = 0.0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
		e = -1.0
	elif Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
		e = 1.0
	if e == 0.0 and bool(reglas.get("inclinar", false)):
		var gx := Input.get_gravity().x
		if absf(gx) > 1.5:
			e = clampf(gx / 5.0, -1.0, 1.0)
	return e


func _zona(p: Vector2) -> String:
	if not tactil:
		return ""
	var todas: Array = ["izq", "der", "salto"]
	for e in _zonas_extra():
		todas.append(e[0])
	for z in todas:
		if _rect_zona(z).grow(10.0).has_point(p):
			return z
	return ""


## Botones táctiles de las mecánicas que están encendidas.
func _zonas_extra() -> Array:
	var r: Array = []
	if _mecanica("dash"):
		r.append(["dash", "⚡"])
	if _mecanica("disparar"):
		r.append(["disp", "🔥"])
	if _mecanica("espada"):
		r.append(["esp", "🗡"])
	if _mecanica("conjurar"):
		r.append(["conj", "🧱"])
	return r


func _rect_zona(z: String) -> Rect2:
	var ex := _zonas_extra()
	for i in ex.size():
		if ex[i][0] == z:
			return Rect2(size.x - 160.0 - 86.0 * (i + 1), size.y - 118.0, 76, 76)
	match z:
		"izq":
			return Rect2(24, size.y - 130, 100, 100)
		"der":
			return Rect2(144, size.y - 130, 100, 100)
	return Rect2(size.x - 150, size.y - 150, 120, 120)


func _pulsado(z: String) -> bool:
	return dedos.values().has(z)


# ------------------------------------------------------------------ lógica
const PASO := 1.0 / 120.0   # la física avanza siempre en pasos iguales: así el salto mide lo mismo a 30 o a 144 fps
var _acum := 0.0


func _avanzar(delta: float) -> void:
	if _menu_pausa != null:
		return
	_pw_vigilar()
	if _pw != null and _pw_ok:
		_pw_tick()
	_acum += minf(delta, 0.1)
	var n := 0
	while _acum >= PASO and n < 12:
		_actualizar(PASO)
		_acum -= PASO
		n += 1
	if n >= 12:
		_acum = 0.0


func _process(delta: float) -> void:
	_avanzar(delta)
	escala = _escala()
	_mundo.scale = Vector2(escala, escala)
	var sac := Vector2.ZERO
	if _temblor > 0.0 and bool(reglas.get("cam_temblor", true)):
		sac = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _temblor * 22.0
	_mundo.position = Vector2(-cam * escala, -camy * escala) + sac
	queue_redraw()
	_mundo.queue_redraw()
	_hud.queue_redraw()


func _escala() -> float:
	return maxf(0.1, size.y / (Datos.FILAS * T)) * clampf(float(reglas.get("cam_zoom", 100)) / 100.0, 1.0, 2.0)


func _zona_activa(z: Dictionary) -> bool:
	if _pw_ok and z["area"] != null and _pw_h != null:
		return (z["area"] as Area2D).overlaps_body(_pw_h)
	return _caja().intersects(z["rect"])


## Efectos de las zonas (agua, hielo, viento, corriente de aire, lava) sobre el héroe.
func _zonas_tick(dt: float) -> void:
	_z_agua = false
	_z_fric = 1.0
	for z in zonas:
		if not _zona_activa(z):
			continue
		match str(z["z"]):
			"agua":
				_z_agua = true
			"hielo":
				_z_fric = 0.12
			"viento":
				vel.x += float(z["it"].get("d", 1)) * 900.0 * dt
			"corriente":
				vel.y = maxf(vel.y - 3400.0 * dt, -420.0)
			"lava":
				_herir()
	if _z_agua and salto_pulsado:
		vel.y = -430.0
		salto_pulsado = false
		_sonido.tocar(520.0, 0.06, "triangulo")


## ¿Hay línea de visión libre entre dos puntos? Usa un rayo de la física de Godot contra el terreno.
func _linea_libre(a: Vector2, b: Vector2) -> bool:
	if not _pw_ok or _pw == null:
		return true
	var q := PhysicsRayQueryParameters2D.create(a, b, 1)
	return _pw.world_2d.direct_space_state.intersect_ray(q).is_empty()


func _caja() -> Rect2:
	return Rect2(pos, Vector2(PW * T, PH * T))


func _actualizar(dt: float) -> void:
	t += dt
	_reglas_tick(dt)
	var pw := PW * T
	var ph := PH * T
	var ancho := float(nivel["cols"]) * T
	var vista := size.x / escala
	var objetivo := (ancho - vista) / 2.0 if ancho <= vista else clampf(pos.x + pw / 2.0 - vista / 2.0, 0.0, ancho - vista)
	cam += (objetivo - cam) * minf(1.0, dt * 8.0 * float(reglas.get("cam_suave", 100)) / 100.0)
	var vista_y := size.y / escala
	var alto_m := float(Datos.FILAS) * T
	var objy := (alto_m - vista_y) / 2.0 if alto_m <= vista_y else clampf(pos.y + ph / 2.0 - vista_y / 2.0, 0.0, alto_m - vista_y)
	camy += (objy - camy) * minf(1.0, dt * 8.0)
	_temblor = maxf(0.0, _temblor - dt)
	_parts_tick(dt)
	for r in resortes:
		r["sq"] = maxf(0.0, float(r["sq"]) - dt * 4.0)
	if estado != "jugar":
		return
	inv = maxf(0.0, inv - dt)
	_objetos_vivos(dt)
	var ejex := _eje_mando()
	var izq := Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or _pulsado("izq") or ejex < -0.3
	var der := Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or _pulsado("der") or ejex > 0.3 or bool(nivel.get("autocorrer", false))
	var sost := Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_SPACE) or _pulsado("salto") or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	var dir := (1.0 if der else 0.0) - (1.0 if izq else 0.0)
	if absf(ejex) > 0.3 and not (_pulsado("izq") or _pulsado("der")):
		dir = clampf(ejex * 1.25, -1.0, 1.0)
	_zonas_tick(dt)
	var vmax := MOVER * float(_fis.get("vel", 1.0)) * _k_vel * (0.7 if _z_agua else 1.0)
	if _mecanica("correr") and Input.is_key_pressed(KEY_SHIFT):
		vmax *= 1.6
	_dash = maxf(0.0, _dash - dt)
	_dash_cd = maxf(0.0, _dash_cd - dt)
	if _mecanica("dash") and _dash_cd <= 0.0 and (Input.is_key_pressed(KEY_X) or Input.is_key_pressed(KEY_K) or _pulsado("dash")):
		_dash = 0.16
		_dash_cd = 0.8
		vel.x = cara * 720.0
		_sonido.tocar(260.0, 0.1, "triangulo")
	if _dash > 0.0:
		vel.y *= 0.3
	else:
		vel.x += (dir * vmax - vel.x) * minf(1.0, dt * (16.0 if suelo else 9.0) * float(_fis.get("friccion", 1.0)) * _z_fric)
	if dir != 0.0:
		cara = dir
	_acciones(dt)
	if salto_pulsado:
		buffer = 0.12
		salto_pulsado = false
	buffer -= dt
	coyote -= dt
	if suelo:
		coyote = 0.1
	if suelo:
		_aire = 0
	if buffer > 0.0 and coyote > 0.0:
		vel.y = -SALTO * _k_salto
		buffer = 0.0
		coyote = 0.0
		suelo = false
		_sfx("saltar")
		_emitir(str(_fx_map.get("saltar", "")), Vector2(pos.x + PW * T / 2.0, pos.y + PH * T), 6)
	elif buffer > 0.0 and _mecanica("doble_salto") and _aire < 1 and not suelo:
		vel.y = -SALTO * _k_salto * 0.92
		buffer = 0.0
		_aire += 1
		_sfx("saltar")
	var g := GRAV * float(_fis.get("grav", 1.0)) * (0.35 if _z_agua else 1.0)
	if not sost and vel.y < -280.0:
		vel.y += g * 1.2 * dt
	vel.y = minf(vel.y + g * dt, (260.0 if _z_agua else 1100.0) * float(_fis.get("caida", 1.0)))
	_planeo = _mecanica("planear") and sost and vel.y > 110.0 and not suelo
	if _planeo:
		vel.y = 110.0
	# --- movimiento horizontal
	if _pw_ok and _pw_h != null:
		var cx := _pw_mover(Vector2(vel.x * dt, 0.0))
		if cx != null:
			var ob := cx.get_collider()
			if ob is RigidBody2D:
				(ob as RigidBody2D).apply_central_impulse(Vector2(vel.x * (ob as RigidBody2D).mass * 0.4, 0.0))
				vel.x *= 0.55
			else:
				vel.x = 0.0
	else:
		pos.x += vel.x * dt
	_empujar_cajas()
	for p in _todas_plats():
		if _caja().intersects(p):
			if vel.x > 0.0:
				pos.x = p.position.x - pw
			elif vel.x < 0.0:
				pos.x = p.end.x
			else:
				pos.x = (p.position.x - pw) if pos.x + pw / 2.0 < p.position.x + p.size.x / 2.0 else p.end.x
			vel.x = 0.0
	pos.x = clampf(pos.x, 0.0, ancho - pw)
	# --- movimiento vertical
	suelo = false
	var rebote_v := 0.0
	if _pw_ok and _pw_h != null:
		var vy0 := vel.y
		var cy := _pw_mover(Vector2(0.0, vel.y * dt))
		if cy != null:
			if cy.get_normal().y < -0.5:
				suelo = true
				if vy0 > 260.0 and float(_fis.get("rebote", 0.0)) > 0.0:
					rebote_v = -vy0 * float(_fis["rebote"])
			vel.y = 0.0
	else:
		pos.y += vel.y * dt
	for p in _todas_plats():
		if _caja().intersects(p):
			if vel.y >= 0.0:
				pos.y = p.position.y - ph
				suelo = true
				if vel.y > 260.0 and float(_fis.get("rebote", 0.0)) > 0.0:
					rebote_v = -vel.y * float(_fis["rebote"])
			else:
				pos.y = p.end.y
			vel.y = 0.0
	if rebote_v != 0.0:
		vel.y = rebote_v
		suelo = false
		_sonido.tocar(420.0, 0.08, "triangulo")
	# --- resortes, pinchos, premios
	for r in resortes:
		if vel.y >= 0.0 and _caja().intersects(Rect2(r["x"] * T, r["y"] * T + T * 0.5, T, T * 0.5)):
			vel.y = -RESORTE
			r["sq"] = 1.0
			suelo = false
			_sonido.tocar(700.0, 0.2, "triangulo")
	for s in pinchos:
		if _caja().intersects(Rect2(s["x"] * T + 8, s["y"] * T + T * 0.5, T - 16, T * 0.5)):
			_herir()
	for c in recogibles:
		if not c["got"] and _caja().intersects(Rect2(c["x"] * T + 8, c["y"] * T + 8, T - 16, T - 16).grow(_alcance())):
			c["got"] = true
			recogidos += 1
			puntos += _vale(c["t"])
			if c["t"] == "coin":
				_n_mon += 1
			_sfx("recoger")
			_emitir(str(_fx_map.get("recoger", "")), Vector2(float(c["x"]) * T + T / 2.0, float(c["y"]) * T + T / 2.0), 8)
	# --- enemigos
	for e in enemigos:
		if e["muerto"]:
			e["sqt"] += dt
			continue
		var ia := str(e["it"].get("ia", "patrulla"))
		var cerca: bool = absf(pos.x / T - e["x"]) < 6.0 and absf(pos.y / T - float(e["it"]["y"])) < 3.0
		var alerta: float = maxf(0.0, float(e.get("alerta", 0.0)) - dt)
		if ia == "vigila" and absf(pos.y / T - float(e["it"]["y"])) < 2.0 and absf(pos.x / T - e["x"]) < 7.0 and (pos.x / T - e["x"]) * e["dir"] > 0.0 and _linea_libre(Vector2(e["x"] * T + T / 2.0, float(e["it"]["y"]) * T + T * 0.4), pos + Vector2(PW * T / 2.0, PH * T / 2.0)):
			alerta = 2.0
		e["alerta"] = alerta
		if (ia == "persigue" and cerca) or (ia == "vigila" and alerta > 0.0):
			e["dir"] = 1.0 if pos.x / T > e["x"] else -1.0
			e["x"] = clampf(e["x"] + e["dir"] * maxf(e["sp"], 40.0) * 1.3 * _lento / T * dt, 0.0, ancho / T - 1.0)
		elif ia == "quieto" or ia == "dispara":
			e["dir"] = 1.0 if pos.x / T > e["x"] else -1.0
		else:
			e["x"] += e["dir"] * e["sp"] * _lento / T * dt
			if e["x"] > e["x0"] + e["r"]:
				e["dir"] = -1.0
			if e["x"] < e["x0"] - e["r"]:
				e["dir"] = 1.0
		if ia == "dispara":
			e["ct"] = float(e.get("ct", 1.2)) - dt
			if e["ct"] <= 0.0 and absf(pos.x / T - e["x"]) < 10.0:
				e["ct"] = 2.2
				bolas_e.append({"x": e["x"] * T + T / 2.0, "y": float(e["it"]["y"]) * T + T * 0.45, "d": e["dir"]})
		e["dy"] = -absf(sin(t * 4.0 + e["x0"])) * T * 0.9 if ia == "salta" else 0.0
		var ey: float = float(e["it"]["y"]) * T + float(e["dy"])
		if e["it"].get("fly", false):
			ey += sin(t * 3.0 + e["x0"]) * 7.0
		if _caja().intersects(Rect2(e["x"] * T + 8, ey + 10, T - 16, T - 14)):
			if vel.y > 0.0 and pos.y + ph < ey + T * 0.55 and _mecanica("pisar"):
				e["muerto"] = true
				vel.y = -540.0
				puntos += _vale("enemy")
				_n_ene += 1
				_sfx("pisar")
				_temblor = 0.12
				_emitir(str(_fx_map.get("pisar", "")), Vector2(e["x"] * T + T / 2.0, float(e["it"]["y"]) * T + T / 2.0), 14)
			else:
				_herir()
	# --- meta y caída
	if meta != null and not _meta_oculta and estado == "jugar" and _caja().intersects(Rect2(meta["x"] * T + 4, meta["y"] * T, T - 8, T)):
		if _faltan() > 0:
			_decir("Te faltan %d premios para abrir la meta" % _faltan())
		else:
			estado = "gano"
			_sfx("ganar")
			_mostrar_fin("🎉", "¡Nivel completado!", "Puntos: %d · Recogiste %d de %d" % [puntos, recogidos, total])
	if pos.y > Datos.FILAS * T + T * 2:
		_caida()


## Caer al vacío: si hay protección (inmunidad o escudo) no se pierde vida, pero vuelve al inicio.
func _caida() -> void:
	if estado != "jugar":
		return
	if inv > 0.0 or _absorber():
		pos = inicio
		vel = Vector2.ZERO
		return
	_herir()


func _herir() -> void:
	if inv > 0.0 or estado != "jugar":
		return
	if _absorber():
		return
	vidas -= 1
	_sfx("golpe")
	_temblor = 0.35
	_emitir(str(_fx_map.get("golpe", "")), Vector2(pos.x + PW * T / 2.0, pos.y + PH * T / 2.0), 12)
	if vidas <= 0:
		estado = "perdio"
		_sfx("perder")
		_mostrar_fin("😵", "¡Ups! Se acabaron las vidas", "Recogiste %d de %d premios" % [recogidos, total])
	else:
		inv = _inv_golpe
		pos = inicio
		vel = Vector2.ZERO


func _mostrar_fin(icono: String, titulo: String, sub: String) -> void:
	if not campana:
		titulo = Datos.traducir(titulo, str(reglas.get("idioma", "es")))
		sub = Datos.traducir(sub, str(reglas.get("idioma", "es")))
	if campana:
		nivel_terminado.emit(estado == "gano", icono, titulo, sub)
		return
	_fin = ColorRect.new()
	_fin.color = Color(0.08, 0.06, 0.23, 0.62)
	add_child(_fin)
	_fin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	_fin.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	centro.add_child(caja)
	var tr := TextureRect.new()
	tr.texture = Datos.textura(icono)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(110, 110)
	caja.add_child(tr)
	var l1 := Label.new()
	l1.text = titulo
	l1.add_theme_font_size_override("font_size", 38)
	l1.add_theme_color_override("font_color", Color.WHITE)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(l1)
	var l2 := Label.new()
	l2.text = sub
	l2.add_theme_font_size_override("font_size", 22)
	l2.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(l2)
	var b := Button.new()
	b.text = "Jugar de nuevo"
	b.custom_minimum_size = Vector2(260, 58)
	b.add_theme_font_size_override("font_size", 24)
	Estilo.pintar(b, Estilo.AMARILLO, Color("4a3300"))
	b.pressed.connect(resetear)
	caja.add_child(b)


# ------------------------------------------------------------------ dibujo
func _draw() -> void:
	if tema.is_empty():
		return
	Dibujo.fondo_de(self, nivel, tema, size, cam * escala, t)


## Plataformas fijas y bloques creados por el mago.
func _todas_plats() -> Array:
	if _bloques.is_empty() and puertas.is_empty() and moviles.is_empty() and rutas.is_empty() and cajas.is_empty() and puentes.is_empty():
		return plats
	var r: Array = _estaticas(null)
	for cj in cajas:
		r.append(cj["r"])
	return r


## Suelo fijo: plataformas, bloques del mago, puertas cerradas y plataformas móviles (sin una caja dada).
func _estaticas(excepto: Variant) -> Array:
	var r: Array = plats.duplicate()
	for b in _bloques:
		r.append(b["r"])
	for d in puertas:
		if not d["abierta"]:
			r.append(Rect2(float(d["x"]) * T + 6, float(d["y"]) * T, T - 12, T * 2))
	for m in moviles:
		r.append(m["rect"])
	for ru in rutas:
		r.append(ru["rect"])
	for pu in puentes:
		if int(pu["est"]) != 2:
			r.append(pu["rect"])
	for cj in cajas:
		if cj != excepto:
			r.append(cj["r"])
	return r


# ------------------------------------------------------------------ sonido, partículas y eventos
func _sfx(ev: String) -> void:
	var id := str(_sfx_map.get(ev, ""))
	if id == "" or _sonido == null:
		return
	if id.begins_with("m:"):
		if _sonido.silencio:
			return
		var st := Imp.cargar_audio(id)
		if st != null:
			var p := AudioStreamPlayer.new()
			p.stream = st
			add_child(p)
			p.finished.connect(p.queue_free)
			p.play()
		return
	var d: Array = Datos.SFX_PRE.get(id, [])
	if d.size() == 3:
		_sonido.tocar(float(d[0]), float(d[1]), str(d[2]))


func _emitir(tipo: String, p: Vector2, n: int = 8) -> void:
	if tipo == "" or not PART.has(tipo) or _parts.size() > 500:
		return
	var cfg: Dictionary = PART[tipo]
	for i in n:
		var a := randf() * TAU
		var v := float(cfg["v"]) * randf_range(0.3, 1.0)
		var vy := sin(a) * v
		if float(cfg["g"]) < 0.0:
			vy = -absf(vy) - 10.0
		var cols: Array = cfg["col"]
		_parts.append({"x": p.x + randf_range(-6, 6), "y": p.y + randf_range(-6, 6), "vx": cos(a) * v, "vy": vy, "vida": float(cfg["vida"]) * randf_range(0.6, 1.0), "max": float(cfg["vida"]), "g": float(cfg["g"]), "t": float(cfg["t"]), "c": cols[randi() % cols.size()]})


func _parts_tick(dt: float) -> void:
	_part_t -= dt
	if _part_t <= 0.0:
		_part_t = 0.07
		for d in decos:
			if d.has("fx"):
				_emitir(str(d["fx"]), Vector2(float(d["x"]) * T + T / 2.0, float(d["y"]) * T + T / 2.0), 1)
	for q in _parts:
		q["vida"] -= dt
		q["vy"] += q["g"] * dt
		q["x"] += q["vx"] * dt
		q["y"] += q["vy"] * dt
	_parts = _parts.filter(func(q): return q["vida"] > 0.0)
	if estado == "jugar":
		_eventos_tick()


func _eventos_tick() -> void:
	for ev in _eventos:
		if ev["hecho"]:
			continue
		var ok := false
		match str(ev["si"]):
			"monedas": ok = _n_mon >= int(ev["n"])
			"enemigos": ok = _n_ene >= int(ev["n"])
			"puntos": ok = puntos >= int(ev["n"])
			"tiempo": ok = t >= float(ev["n"])
			"llave": ok = _n_llaves >= int(ev["n"])
			"boton": ok = _boton_hecho
		if ok:
			ev["hecho"] = true
			_hacer_evento(ev)


func _hacer_evento(ev: Dictionary) -> void:
	match str(ev["haz"]):
		"mensaje": _decir(str(ev["txt"]) if str(ev["txt"]) != "" else "¡Algo pasó!")
		"puertas": _abrir_puertas()
		"meta":
			_meta_oculta = false
			_decir("¡Apareció la meta!")
		"vida": vidas = mini(12, vidas + maxi(1, int(ev["v"])))
		"puntos": puntos += int(ev["v"])
		"efecto": _emitir("explosion", Vector2(pos.x + PW * T / 2.0, pos.y), 20)
		"ganar":
			estado = "gano"
			_sfx("ganar")
			_mostrar_fin("🎉", "¡Nivel completado!", "Puntos: %d" % puntos)
		"perder":
			estado = "perdio"
			_sfx("perder")
			_mostrar_fin("😵", "¡Perdiste!", "Puntos: %d" % puntos)
	_sfx("recoger")


func _abrir_puertas() -> void:
	var alguna := false
	for d in puertas:
		if not d["abierta"]:
			d["abierta"] = true
			alguna = true
	if alguna:
		_decir("¡Se abrieron las puertas!")
		_sonido.tocar(400.0, 0.25, "triangulo")


## Llaves, puertas, botones, plataformas móviles y cajas que se empujan.
func _objetos_vivos(dt: float) -> void:
	var g := GRAV * float(_fis.get("grav", 1.0))
	# plataformas móviles: se mueven y llevan al jugador
	for m in moviles:
		var antes: float = m["px"]
		m["px"] += m["dir"] * m["sp"] * dt
		if m["px"] > m["x0"] + m["r"]:
			m["dir"] = -1.0
		if m["px"] < m["x0"] - m["r"]:
			m["dir"] = 1.0
		m["dx"] = m["px"] - antes
		var rr: Rect2 = m["rect"]
		var encima: bool = suelo and absf(pos.y + PH * T - rr.position.y) < 6.0 and pos.x + PW * T > rr.position.x and pos.x < rr.end.x
		rr.position.x = m["px"]
		m["rect"] = rr
		m["it"]["x"] = m["px"] / T
		if encima:
			pos.x += m["dx"]
	# plataformas en ruta: siguen un camino (Curve2D) y llevan al jugador
	for ru in rutas:
		var antes_r: Rect2 = ru["rect"]
		ru["off"] = float(ru["off"]) + float(ru["dir"]) * float(ru["sp"]) * dt
		if ru["cerrada"]:
			ru["off"] = fposmod(float(ru["off"]), float(ru["len"]))
		elif float(ru["off"]) > float(ru["len"]):
			ru["off"] = ru["len"]
			ru["dir"] = -1.0
		elif float(ru["off"]) < 0.0:
			ru["off"] = 0.0
			ru["dir"] = 1.0
		var pr: Vector2 = (ru["o"] as Vector2) + (ru["curve"] as Curve2D).sample_baked(float(ru["off"]))
		var encima_r: bool = suelo and absf(pos.y + PH * T - antes_r.position.y) < 6.0 and pos.x + PW * T > antes_r.position.x and pos.x < antes_r.end.x
		var rr2: Rect2 = ru["rect"]
		rr2.position = pr
		ru["rect"] = rr2
		ru["dx"] = pr.x - antes_r.position.x
		ru["dy"] = pr.y - antes_r.position.y
		ru["it"]["x"] = pr.x / T
		ru["it"]["y"] = pr.y / T
		ru["it"]["live"] = true
		if encima_r:
			pos += Vector2(float(ru["dx"]), float(ru["dy"]))
	# puentes: se rompen poco después de pisarlos y vuelven a salir
	for pu in puentes:
		var rp: Rect2 = pu["rect"]
		if int(pu["est"]) == 0:
			var pisa: bool = suelo and absf(pos.y + PH * T - rp.position.y) < 6.0 and pos.x + PW * T > rp.position.x and pos.x < rp.end.x
			if pisa:
				pu["est"] = 1
				pu["t"] = 0.0
		elif int(pu["est"]) == 1:
			pu["t"] = float(pu["t"]) + dt
			if float(pu["t"]) > 0.6:
				pu["est"] = 2
				pu["t"] = 0.0
				pu["vy"] = 0.0
				_sfx("golpe")
		else:
			pu["t"] = float(pu["t"]) + dt
			pu["vy"] = float(pu["vy"]) + g * dt
			if float(pu["t"]) > 3.0:
				pu["est"] = 0
				pu["rect"] = pu["r0"]
		pu["it"]["fall"] = float(pu["vy"]) * 0.2 if int(pu["est"]) == 2 else 0.0
		pu["it"]["tiembla"] = int(pu["est"]) == 1
	# péndulos: bola con pinchos que balancea y hace daño
	for pe in pendulos:
		pe["ang"] = sin(t * float(pe["sp"]) * 1.6) * 1.15
		pe["bx"] = float(pe["ax"]) + sin(float(pe["ang"])) * float(pe["largo"])
		pe["by"] = float(pe["ay"]) + cos(float(pe["ang"])) * float(pe["largo"])
		pe["it"]["ang"] = pe["ang"]
		if Vector2(pe["bx"], pe["by"]).distance_to(Vector2(pos.x + PW * T / 2.0, pos.y + PH * T / 2.0)) < T * 0.55 + PW * T / 2.0:
			_herir()
	# cajas: caen y se empujan
	for cj in cajas:
		cj["vy"] = minf(cj["vy"] + g * dt, 900.0)
		var r: Rect2 = cj["r"]
		r.position.y += cj["vy"] * dt
		for p in _estaticas(cj):
			if r.intersects(p):
				r.position.y = p.position.y - r.size.y
				cj["vy"] = 0.0
		cj["r"] = r
		cj["it"]["x"] = r.position.x / T
		cj["it"]["y"] = r.position.y / T
	# llaves
	for l in llaves:
		if not l["got"] and _caja().intersects(Rect2(float(l["x"]) * T + 8, float(l["y"]) * T + 8, T - 16, T - 16)):
			l["got"] = true
			_n_llaves += 1
			_llaves_disp += 1
			_sfx("recoger")
			_decir("¡Tienes una llave!")
	# puertas
	for d in puertas:
		if not d["abierta"] and _caja().grow(3.0).intersects(Rect2(float(d["x"]) * T + 6, float(d["y"]) * T, T - 12, T * 2)):
			if _llaves_disp > 0:
				_llaves_disp -= 1
				d["abierta"] = true
				_decir("¡Puerta abierta!")
				_sonido.tocar(400.0, 0.25, "triangulo")
			elif _msg_t <= 0.0:
				_decir("Necesitas una llave")
	# botones
	for b in botones:
		var rb := Rect2(float(b["x"]) * T + 6, float(b["y"]) * T + T - 12, T - 12, 14)
		var pisado := _caja().intersects(rb)
		for cj in cajas:
			if (cj["r"] as Rect2).intersects(rb):
				pisado = true
		if pisado and not b["on"]:
			b["on"] = true
			_boton_hecho = true
			_abrir_puertas()
		elif not pisado and b["on"]:
			b["on"] = false


## Empuja las cajas con las que choca el jugador al caminar.
func _empujar_cajas() -> void:
	if absf(vel.x) < 1.0:
		return
	for cj in cajas:
		var r: Rect2 = cj["r"]
		if _caja().intersects(r) and pos.y + PH * T > r.position.y + 8.0:
			var sol := (pos.x + PW * T - r.position.x) if vel.x > 0.0 else -(r.end.x - pos.x)
			var nuevo := r
			nuevo.position.x += sol
			var libre := nuevo.position.x >= 0.0 and nuevo.end.x <= float(nivel["cols"]) * T
			for p in _estaticas(cj):
				if nuevo.intersects(p):
					libre = false
			if libre:
				cj["r"] = nuevo


## Disparar, espada, crear bloques, cambiar de héroe y mover las bolitas.
func _acciones(dt: float) -> void:
	_disp_cd = maxf(0.0, _disp_cd - dt)
	_esp_cd = maxf(0.0, _esp_cd - dt)
	_esp_t = maxf(0.0, _esp_t - dt)
	_conj_cd = maxf(0.0, _conj_cd - dt)
	if _trio:
		for k in 3:
			if Input.is_key_pressed(KEY_1 + k) and _hero_i != k:
				_cambiar_heroe(k)
				_sonido.tocar(600.0 + k * 150.0, 0.1, "triangulo")
	var centro := Vector2(pos.x + PW * T / 2.0, pos.y + PH * T / 2.0)
	if _mecanica("disparar") and _disp_cd <= 0.0 and (Input.is_key_pressed(KEY_F) or Input.is_key_pressed(KEY_J) or _pulsado("disp")):
		_disp_cd = 0.35
		bolas.append({"x": centro.x, "y": centro.y, "d": cara})
		_sfx("disparar")
	if _mecanica("espada") and _esp_cd <= 0.0 and (Input.is_key_pressed(KEY_H) or _pulsado("esp")):
		_esp_cd = 0.45
		_esp_t = 0.18
		var zona := Rect2(centro.x - (0.0 if cara > 0.0 else T * 1.5), centro.y - T * 0.6, T * 1.5, T * 1.2)
		for e in enemigos:
			if not e["muerto"] and zona.intersects(Rect2(e["x"] * T, float(e["it"]["y"]) * T, T, T)):
				e["muerto"] = true
				puntos += _vale("enemy")
				_n_ene += 1
				_emitir(str(_fx_map.get("pisar", "")), Vector2(e["x"] * T + T / 2.0, float(e["it"]["y"]) * T + T / 2.0), 10)
		_sonido.tocar(380.0, 0.1, "sierra")
	if _mecanica("conjurar") and _conj_cd <= 0.0 and (Input.is_key_pressed(KEY_G) or _pulsado("conj")):
		_conj_cd = 0.6
		var bx := floorf((centro.x + cara * T * 1.1) / T)
		var by := floorf((pos.y + PH * T - 2.0) / T)
		var r := Rect2(bx * T, by * T, T, T)
		if not _bloques.any(func(b): return (b["r"] as Rect2).position == r.position):
			_bloques.append({"r": r, "it": {"t": "plat", "x": bx, "y": by, "w": 1, "h": 1}})
			if _bloques.size() > 3:
				_bloques.pop_front()
			_sonido.tocar(900.0, 0.12, "triangulo")
	# bolitas del jugador
	for b in bolas:
		b["x"] += b["d"] * 640.0 * dt
		var rb := Rect2(b["x"] - 6, b["y"] - 6, 12, 12)
		for p in plats:
			if rb.intersects(p):
				b["x"] = -9999.0
		for e in enemigos:
			if not e["muerto"] and rb.intersects(Rect2(e["x"] * T, float(e["it"]["y"]) * T, T, T)):
				e["muerto"] = true
				b["x"] = -9999.0
				puntos += _vale("enemy")
				_n_ene += 1
				_sfx("pisar")
				_emitir(str(_fx_map.get("pisar", "")), Vector2(e["x"] * T + T / 2.0, float(e["it"]["y"]) * T + T / 2.0), 10)
	bolas = bolas.filter(func(b): return b["x"] > -500.0 and b["x"] < float(nivel["cols"]) * T + 500.0)
	# bolitas de enemigos
	for b in bolas_e:
		b["x"] += b["d"] * 300.0 * dt
		var rb2 := Rect2(b["x"] - 7, b["y"] - 7, 14, 14)
		if rb2.intersects(_caja()):
			b["x"] = -9999.0
			_herir()
		for p in plats:
			if rb2.intersects(p):
				b["x"] = -9999.0
	bolas_e = bolas_e.filter(func(b): return b["x"] > -500.0 and b["x"] < float(nivel["cols"]) * T + 500.0)


func _dibujar_mundo(ci: CanvasItem) -> void:
	for z in zonas:
		Dibujo.objeto(ci, z["it"], tema, t)
	for b in _bloques:
		Dibujo.objeto(ci, b["it"], tema, t)
	for b in bolas:
		ci.draw_circle(Vector2(b["x"], b["y"]), 7.0, Color("fff1a8"))
		ci.draw_circle(Vector2(b["x"], b["y"]), 4.0, Color("ffc61a"))
	for b in bolas_e:
		ci.draw_circle(Vector2(b["x"], b["y"]), 8.0, Color("7a1fff"))
		ci.draw_circle(Vector2(b["x"], b["y"]), 4.0, Color("d9b8ff"))
	for q in _parts:
		var k: float = clampf(q["vida"] / q["max"], 0.0, 1.0)
		var cc: Color = q["c"]
		cc.a *= k
		ci.draw_circle(Vector2(q["x"], q["y"]), float(q["t"]) * (0.5 + k * 0.5), cc)
	if _esp_t > 0.0:
		var cx := pos.x + PW * T / 2.0 + cara * T * 0.9
		ci.draw_arc(Vector2(cx, pos.y + PH * T / 2.0), T * 0.7, -1.2 if cara > 0.0 else 1.94, 1.2 if cara > 0.0 else 4.34, 14, Color(1, 1, 1, 0.9), 6.0)
	for d in decos:
		Dibujo.objeto(ci, d, tema, t)
	for p in items_plat:
		Dibujo.objeto(ci, p, tema, t)
	for s in pinchos:
		Dibujo.objeto(ci, s, tema, t)
	for r in resortes:
		Dibujo.objeto(ci, r, tema, t, {"sq": r["sq"]})
	for c in recogibles:
		if not c["got"]:
			Dibujo.objeto(ci, c, tema, t)
	for l in llaves:
		if not l["got"]:
			Dibujo.objeto(ci, l, tema, t)
	for b in botones:
		Dibujo.objeto(ci, b, tema, t)
	for m in moviles:
		Dibujo.objeto(ci, m["it"], tema, t)
	for ru in rutas:
		Dibujo.objeto(ci, ru["it"], tema, t)
	for pu in puentes:
		Dibujo.objeto(ci, pu["it"], tema, t)
	for pe in pendulos:
		Dibujo.objeto(ci, pe["it"], tema, t)
	for cj in cajas:
		Dibujo.objeto(ci, cj["it"], tema, t)
	for o in _pw_rig:
		Dibujo.objeto(ci, o["it"], tema, t)
	for cu in _pw_cuerdas:
		Dibujo.objeto(ci, cu["it"], tema, t)
	for d in puertas:
		Dibujo.objeto(ci, d, tema, t)
	if meta != null and not _meta_oculta:
		Dibujo.objeto(ci, meta, tema, t)
	for e in enemigos:
		if not e["muerto"] or e["sqt"] < 0.5:
			var cp: Dictionary = e["it"]
			if float(e.get("dy", 0.0)) != 0.0:
				cp = e["it"].duplicate()
				cp["y"] = float(cp["y"]) + float(e["dy"]) / T
			Dibujo.objeto(ci, cp, tema, t, {"dir": e["dir"], "x": e["x"], "sq": e["muerto"]})
	if not (inv > 0.0 and int(t * 14.0) % 2 == 1):
		var c2 := Vector2(pos.x + PW * T / 2.0 - T / 2.0, pos.y + PH * T / 2.0 - T / 2.0) / T
		_mascota_2d(ci, c2)
		Dibujo.objeto(ci, {"t": "player", "x": c2.x, "y": c2.y}, tema, t, {"e": nivel["hero"], "cara": cara})


## Cueva oscura: todo se oscurece menos un círculo de luz alrededor del héroe.
func _dibujar_oscuridad(ci: CanvasItem) -> void:
	var osc := float(nivel.get("oscuridad", 0.0))
	if osc <= 0.0:
		return
	if _luz_tex == null:
		var gr := Gradient.new()
		gr.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		gr.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.15), Color(0, 0, 0, 1)])
		_luz_tex = GradientTexture2D.new()
		_luz_tex.gradient = gr
		_luz_tex.fill = GradientTexture2D.FILL_RADIAL
		_luz_tex.fill_from = Vector2(0.5, 0.5)
		_luz_tex.fill_to = Vector2(1.0, 0.5)
		_luz_tex.width = 256
		_luz_tex.height = 256
	var c := Vector2((pos.x + PW * T / 2.0 - cam) * escala, (pos.y + PH * T / 2.0 - camy) * escala)
	var R := 4.5 * T * escala
	var col := Color(0, 0, 0, osc)
	ci.draw_texture_rect(_luz_tex, Rect2(c - Vector2(R, R), Vector2(R, R) * 2.0), false, col)
	ci.draw_rect(Rect2(0, 0, size.x, maxf(0.0, c.y - R)), col)
	ci.draw_rect(Rect2(0, c.y + R, size.x, maxf(0.0, size.y - c.y - R)), col)
	ci.draw_rect(Rect2(0, c.y - R, maxf(0.0, c.x - R), R * 2.0), col)
	ci.draw_rect(Rect2(c.x + R, c.y - R, maxf(0.0, size.x - c.x - R), R * 2.0), col)


## Mapa pequeño de todo el nivel (plataformas, premios, meta y tú).
func _minimapa(ci: CanvasItem) -> void:
	var cols := float(nivel["cols"])
	var w := minf(220.0, size.x * 0.28)
	var h := w * float(Datos.FILAS) / cols * 1.0
	h = clampf(h, 30.0, 90.0)
	var o := Vector2(size.x - w - 12.0, 56.0 if etiqueta_nivel == "" else 120.0)
	ci.draw_rect(Rect2(o - Vector2(4, 4), Vector2(w + 8, h + 8)), Color(0, 0, 0, 0.5))
	var ex := w / (cols * T)
	var ey := h / (float(Datos.FILAS) * T)
	for p in _todas_plats():
		var r: Rect2 = p
		ci.draw_rect(Rect2(o + Vector2(r.position.x * ex, r.position.y * ey), Vector2(maxf(1.5, r.size.x * ex), maxf(1.5, r.size.y * ey))), Color("c7d2fe"))
	for c in recogibles:
		if not c["got"]:
			ci.draw_rect(Rect2(o + Vector2(float(c["x"]) * T * ex, float(c["y"]) * T * ey), Vector2(2.5, 2.5)), Color("fde047"))
	if meta != null:
		ci.draw_rect(Rect2(o + Vector2(float(meta["x"]) * T * ex, float(meta["y"]) * T * ey), Vector2(4, 4)), Color("34d399"))
	for e in enemigos:
		if not e["muerto"]:
			ci.draw_rect(Rect2(o + Vector2(float(e["x"]) * T * ex, float(e["it"]["y"]) * T * ey), Vector2(3, 3)), Color("f87171"))
	ci.draw_circle(o + Vector2((pos.x + PW * T / 2.0) * ex, (pos.y + PH * T / 2.0) * ey), 3.5, Color.WHITE)
	var vx := cam * ex
	ci.draw_rect(Rect2(o + Vector2(vx, 0), Vector2(size.x / escala * ex, h)), Color(1, 1, 1, 0.6), false, 1.0)


func _dibujar_hud(ci: CanvasItem) -> void:
	_hud_extra(ci)
	if bool(reglas.get("minimapa", false)):
		_minimapa(ci)
	var fuente := ThemeDB.fallback_font
	ci.draw_style_box(Estilo.caja(Color(0, 0, 0, 0.45), 22), Rect2(12, 10, maxf(250.0, 126.0 + int(reglas["vidas"]) * 30.0), 40))
	Dibujo.emoji(ci, "⭐", Vector2(34, 30), 26.0)
	ci.draw_string(fuente, Vector2(52, 38), str(puntos), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	for i in maxi(0, vidas):
		Dibujo.emoji(ci, "❤", Vector2(130 + i * 30, 30), 26.0)
	if _escudos > 0:
		Dibujo.emoji(ci, "🛡", Vector2(130 + maxi(0, vidas) * 30 + 6, 30), 24.0)
	if _llaves_disp > 0:
		Dibujo.emoji(ci, "🔑", Vector2(size.x - 30, 80), 28.0)
		ci.draw_string(fuente, Vector2(size.x - 50, 108), "x%d" % _llaves_disp, HORIZONTAL_ALIGNMENT_RIGHT, -1, 18, Color.WHITE)
	_dibujar_oscuridad(ci)
	if _trio:
		for i in TRIO.size():
			var rc := Rect2(12 + i * 62, 110, 56, 56)
			ci.draw_style_box(Estilo.caja(Color(1, 0.85, 0.2, 0.9) if i == _hero_i else Color(0, 0, 0, 0.45), 14), rc)
			Dibujo.emoji(ci, str(TRIO[i][0]), rc.get_center() + Vector2(0, -2), 44.0)
			ci.draw_string(fuente, rc.position + Vector2(5, 14), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	if tactil:
		for z in ["izq", "der", "salto"]:
			var r := _rect_zona(z)
			var c := r.get_center()
			var activo := _pulsado(z)
			ci.draw_circle(c, r.size.x / 2.0, Color(1, 1, 1, 0.5 if activo else 0.28))
			ci.draw_arc(c, r.size.x / 2.0, 0.0, TAU, 32, Color(1, 1, 1, 0.8), 3.0)
			var k := r.size.x * 0.22
			var tri: PackedVector2Array
			match z:
				"izq":
					tri = PackedVector2Array([c + Vector2(-k, 0), c + Vector2(k * 0.7, -k), c + Vector2(k * 0.7, k)])
				"der":
					tri = PackedVector2Array([c + Vector2(k, 0), c + Vector2(-k * 0.7, -k), c + Vector2(-k * 0.7, k)])
				_:
					tri = PackedVector2Array([c + Vector2(0, -k), c + Vector2(-k, k * 0.7), c + Vector2(k, k * 0.7)])
			ci.draw_colored_polygon(tri, Color.WHITE)
		for e in _zonas_extra():
			var r2 := _rect_zona(e[0])
			ci.draw_circle(r2.get_center(), r2.size.x / 2.0, Color(1, 1, 1, 0.5 if _pulsado(e[0]) else 0.28))
			ci.draw_arc(r2.get_center(), r2.size.x / 2.0, 0.0, TAU, 28, Color(1, 1, 1, 0.8), 3.0)
			Dibujo.emoji(ci, str(e[1]), r2.get_center(), 40.0)
