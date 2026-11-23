extends ColorRect
## Panel «Exportar»: un solo lugar, tres pasos claros.
##  1) Mira qué vas a crear (tu juego y su plataforma).  2) Pulsa el botón grande.  3) Abre la carpeta.
## Aquí también se guarda y se abre el juego como archivo (.atrapa.json) y se abren APK.

signal cerrar

const Estilo := preload("res://scripts/estilo.gd")
const Paquete := preload("res://scripts/paquete.gd")

var exp: Node            # el Exportador
var _estado: Label
var _carpeta := ""
var _abrir_carpeta: Button
var _botones: Array[Button] = []
var _avanzado: VBoxContainer

const PLATAFORMAS := [
	["windows", "🖥", "Computadora con Windows", "Crea una carpeta con tu juego como programa (.exe). Haz doble clic en el .exe para jugar."],
	["web", "🌐", "Navegador (internet)", "Crea una carpeta con index.html. Súbela a un hosting, o ábrela con un servidor local (no con doble clic)."],
	["android", "📱", "Android (celular)", "Crea un archivo .apk para instalar en el celular. Necesita Godot configurado una vez."],
]


func _ready() -> void:
	color = Color(0.08, 0.06, 0.23, 0.62)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(660.0, maxf(340.0, size.x - 30.0)), 0)
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 26, 0, Color.TRANSPARENT, 22))
	centro.add_child(panel)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, minf(620.0, maxf(280.0, size.y - 60.0)))
	panel.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	sc.add_child(v)

	_texto(v, "Crear .exe y exportar tu juego", 30, Estilo.TINTA)
	var n_mundos: int = Datos.niveles.size()
	var nombre := str(Datos.reglas.get("titulo_juego", "")) if str(Datos.reglas.get("titulo_juego", "")) != "" else str(Datos.nivel.get("name", "Mi juego"))
	_texto(v, "«%s» · %d mundo%s. Se exportan TODOS los mundos, con sus personajes, sonidos y dibujos." % [nombre, n_mundos, "" if n_mundos == 1 else "s"], 16, Estilo.SUAVE)

	# ---------- paso 1
	_texto(v, "① Elige dónde quieres jugarlo", 20, Estilo.MORADO)
	if not exp.disponible():
		_texto(v, "Desde este dispositivo no se puede crear el programa. Usa «Guardar como archivo» (abajo) y ábrelo en la computadora con el creador.", 16, Estilo.ROJO)
	var elegida := str(Datos.reglas.get("plataforma", "windows"))
	if elegida == "linux":
		elegida = "windows"
	for d in PLATAFORMAS:
		var lista: bool = exp.disponible() and (exp.motor_propio(d[0]) != "" or exp.tiene_godot())
		var b := Button.new()
		b.text = "  %s%s" % [d[2], "   ← tu elección" if d[0] == elegida else ""]
		b.icon = Datos.textura(d[1])
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 32)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 54)
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = not lista
		Estilo.pintar(b, Estilo.MORADO if d[0] == elegida else Estilo.TURQUESA)
		b.pressed.connect(_lanzar.bind(d[0]))
		v.add_child(b)
		_botones.append(b)
		_texto(v, "      " + d[3], 14, Estilo.SUAVE)
	if exp.disponible() and not exp.tiene_godot() and exp.motor_propio("windows") == "":
		_texto(v, "Falta una cosa (la hace un adulto una sola vez): indicar dónde está el programa Godot.", 16, Estilo.ROJO)
		var bg := _boton("  Elegir Godot…", "📁", Estilo.MORADO)
		bg.pressed.connect(func(): exp.elegir_godot(func(): cerrar.emit()))
		v.add_child(bg)

	# ---------- paso 2 / 3
	_texto(v, "② Espera un ratito  ·  ③ Abre la carpeta", 20, Estilo.MORADO)
	_estado = _texto(v, "Los archivos se guardan en Documentos → «Mis juegos» → el nombre de tu juego.", 16, Estilo.SUAVE)
	_abrir_carpeta = _boton("  Abrir la carpeta de mi juego", "📂", Estilo.VERDE)
	_abrir_carpeta.visible = false
	_abrir_carpeta.pressed.connect(func(): OS.shell_open(_carpeta))
	v.add_child(_abrir_carpeta)
	v.add_child(HSeparator.new())

	# ---------- guardar / abrir
	_texto(v, "Guardar y abrir como archivo", 20, Estilo.MORADO)
	_texto(v, "Un archivo «.atrapa.json» es tu juego completo (con una carpeta «assets» al lado). Sirve para copiarlo, enviarlo o abrirlo en otra computadora.", 14, Estilo.SUAVE)
	var f1 := HBoxContainer.new()
	f1.add_theme_constant_override("separation", 8)
	v.add_child(f1)
	var guardar := _boton("  Guardar como archivo", "💾", Estilo.TURQUESA)
	guardar.pressed.connect(_guardar_archivo)
	f1.add_child(guardar)
	var abrir := _boton("  Abrir un archivo…", "📁", Estilo.TURQUESA)
	abrir.pressed.connect(_abrir_archivo)
	f1.add_child(abrir)
	var apk := _boton("  Abrir un APK…", "📱", Estilo.TURQUESA)
	apk.pressed.connect(_abrir_apk)
	f1.add_child(apk)

	# ---------- avanzado
	var adv := _boton("  Opciones avanzadas ▾", "⚙️")
	v.add_child(adv)
	_avanzado = VBoxContainer.new()
	_avanzado.visible = false
	_avanzado.add_theme_constant_override("separation", 8)
	v.add_child(_avanzado)
	adv.pressed.connect(func(): _avanzado.visible = not _avanzado.visible)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	_avanzado.add_child(h)
	var copiar := _boton("  Copiar el código del juego", "📋")
	copiar.pressed.connect(func():
		DisplayServer.clipboard_set(Datos.a_json())
		_decir("¡Código copiado!"))
	h.add_child(copiar)
	var pegar := _boton("  Pegar un código", "📁")
	pegar.pressed.connect(func():
		if Datos.desde_json(DisplayServer.clipboard_get()):
			_decir("¡Juego pegado! Cierra esta ventana para verlo.")
		else:
			_decir("No encontré un código copiado."))
	h.add_child(pegar)
	var reg := _boton("  Ver el registro de la última exportación", "📄")
	reg.pressed.connect(func(): OS.shell_open(ProjectSettings.globalize_path("user://ultima_exportacion.log")))
	_avanzado.add_child(reg)

	var fin := HBoxContainer.new()
	v.add_child(fin)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fin.add_child(sp)
	var c := _boton("Cerrar")
	c.pressed.connect(func(): cerrar.emit())
	fin.add_child(c)
	exp.terminado.connect(_al_terminar)


func _exit_tree() -> void:
	if exp and exp.terminado.is_connected(_al_terminar):
		exp.terminado.disconnect(_al_terminar)


func _lanzar(plataforma: String) -> void:
	_decir("Preparando tu juego… puede tardar un ratito ⏳")
	_abrir_carpeta.visible = false
	for b in _botones:
		b.disabled = true
	var nombre := str(Datos.reglas.get("titulo_juego", "")) if str(Datos.reglas.get("titulo_juego", "")) != "" else str(Datos.nivel.get("name", "Mi juego"))
	exp.exportar(plataforma, nombre, Datos.a_json())


func _al_terminar(ok: bool, mensaje: String, carpeta: String) -> void:
	_decir(mensaje)
	for b in _botones:
		b.disabled = false
	if ok and carpeta != "":
		_carpeta = carpeta
		_abrir_carpeta.visible = true


func _decir(t: String) -> void:
	if _estado and is_instance_valid(_estado):
		_estado.text = t


func _guardar_archivo() -> void:
	var nombre := str(Datos.nivel.get("name", "mi-juego"))
	var destino: String = exp.carpeta_salida(nombre).path_join("proyecto")
	var r: Dictionary = Paquete.guardar_proyecto(destino, nombre)
	if r["ok"]:
		_carpeta = destino
		_abrir_carpeta.visible = true
		_decir("¡Guardado! %s\n(%d archivos en «assets»)" % [r["archivo"], r["assets"]])
	else:
		_decir("No pude guardar: " + str(r["error"]))


func _abrir_archivo() -> void:
	DisplayServer.file_dialog_show("Abrir un juego guardado", "", "", false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, PackedStringArray(["*.json;Juegos de Atrapa Juegos"]),
		func(ok: bool, rutas: PackedStringArray, _f: int) -> void:
			if ok and rutas.size() > 0:
				var r: Dictionary = Paquete.abrir_proyecto(rutas[0])
				_decir("¡Juego abierto! Cierra esta ventana para verlo." if r["ok"] else "No pude abrirlo: " + str(r["error"])))


func _abrir_apk() -> void:
	DisplayServer.file_dialog_show("Elige un APK", "", "", false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, PackedStringArray(["*.apk;Apps de Android"]),
		func(ok: bool, rutas: PackedStringArray, _f: int) -> void:
			if ok and rutas.size() > 0:
				var r: Dictionary = Paquete.abrir_apk(rutas[0])
				if r["ok"]:
					_carpeta = r["carpeta"]
					_abrir_carpeta.visible = true
					_decir(Paquete.resumen_apk(r))
				else:
					_decir("No pude abrir el APK: " + str(r["error"])))


# ---------------------------------------------------------------- piezas
func _texto(padre: Control, t: String, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	l.custom_minimum_size = Vector2(300, 0)
	padre.add_child(l)
	return l


func _boton(t: String, icono: String = "", col: Color = Estilo.FONDO) -> Button:
	var b := Button.new()
	b.text = t
	if icono != "":
		b.icon = Datos.textura(icono)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 24)
	b.custom_minimum_size = Vector2(0, 44)
	b.focus_mode = Control.FOCUS_NONE
	if col != Estilo.FONDO:
		Estilo.pintar(b, col)
	return b
