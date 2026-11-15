extends Control
## Tutorial interactivo: oscurece la pantalla menos lo que hay que tocar y
## avanza solo cuando el niño hace lo que se le pidió.

signal terminado

const Estilo := preload("res://scripts/estilo.gd")

const PASOS := [
	{"obj": "tab_fondos", "txt": "¡Hola! Vamos a crear tu primer juego. Primero abre la pestaña [b]Fondos[/b].", "ev": "tab:fondos"},
	{"obj": "biblioteca", "txt": "Toca un fondo para cambiar el mundo de tu juego. ¡Prueba uno!", "ev": "tema"},
	{"obj": "tab_objetos", "txt": "Ahora abre [b]Objetos[/b]: aquí están las plataformas, monedas y más.", "ev": "tab:objetos"},
	{"obj": "biblioteca", "txt": "Arrastra una [b]Plataforma[/b] hasta el escenario.\n(Con el dedo: tócala y luego toca el escenario. Si arrastras, la haces más larga.)", "ev": "add:plat"},
	{"obj": "biblioteca", "txt": "¡Muy bien! Ahora pon algunas [b]Monedas[/b]. Truco: elige la moneda y desliza por el escenario para poner muchas.", "ev": "add:coin"},
	{"obj": "tab_pers", "txt": "Ahora elige a tu héroe en [b]Personajes[/b].", "ev": "tab:pers"},
	{"obj": "biblioteca", "txt": "Toca un personaje: ¡será tu héroe!", "ev": "hero"},
	{"obj": "biblioteca", "txt": "Agrega un [b]enemigo[/b] al escenario. Se vence saltando encima de él.", "ev": "add:enemy"},
	{"obj": "escenario", "txt": "Toca cualquier cosa del escenario para [b]moverla[/b], estirarla o borrarla. Antes pulsa «Listo» si te aparece.", "ev": "select"},
	{"obj": "btn_jugar", "txt": "¡Hora de probar! Pulsa [b]Jugar[/b]. Muévete con las flechas y salta con la barra espaciadora.", "ev": "play"},
	{"obj": "btn_exportar", "txt": "¡Genial! Cuando termines, pulsa [b]Exportar[/b]: tu juego se convierte en una página web, un programa de Windows o una app.", "ev": "export"},
]

const PASOS_3D := [
	{"obj": "tab_fondos", "txt": "¡Hola! Vamos a crear tu corredor. Abre la pestaña [b]Fondos[/b].", "ev": "tab:fondos"},
	{"obj": "biblioteca", "txt": "Toca un fondo para cambiar el mundo por el que correrás.", "ev": "tema"},
	{"obj": "tab_objetos", "txt": "Abre [b]Objetos[/b]. Aquí está lo que aparece en la pista.", "ev": "tab:objetos"},
	{"obj": "biblioteca", "txt": "Pon una [b]Valla[/b] en la pista: tu corredor tendrá que SALTARLA.\n(Verás la pista desde arriba, con 3 carriles. El corredor avanza hacia la derecha.)", "ev": "add:valla"},
	{"obj": "biblioteca", "txt": "Ahora pon una [b]Pared[/b]: hay que ESQUIVARLA cambiando de carril.", "ev": "add:pared"},
	{"obj": "biblioteca", "txt": "Pon algunas [b]Monedas[/b]. Elige la moneda y desliza por un carril para poner muchas.", "ev": "add:coin"},
	{"obj": "tab_pers", "txt": "Elige a tu corredor en [b]Personajes[/b].", "ev": "tab:pers"},
	{"obj": "biblioteca", "txt": "Toca un personaje: ¡será tu corredor!", "ev": "hero"},
	{"obj": "btn_jugar", "txt": "¡A correr! Pulsa [b]Jugar[/b]. Flechas ← → para cambiar de carril, ↑ salta y ↓ te agacha. En tablet: desliza el dedo.", "ev": "play"},
	{"obj": "btn_exportar", "txt": "Cuando termines, pulsa [b]Exportar[/b]: tu juego se convierte en una página web o un programa.", "ev": "export"},
]

var pasos: Array = PASOS
var activo := false
var paso := 0
var objetivos: Dictionary = {}     # nombre -> Control
var _tarjeta: PanelContainer
var _texto: RichTextLabel
var _num: Label
var _puntos: HBoxContainer
var _siguiente: Button
var _bloqueado := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_tarjeta = PanelContainer.new()
	_tarjeta.custom_minimum_size = Vector2(330, 0)
	_tarjeta.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 20, 3, Estilo.AMARILLO, 14))
	add_child(_tarjeta)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_tarjeta.add_child(v)
	_num = Label.new()
	_num.add_theme_color_override("font_color", Estilo.MORADO)
	_num.add_theme_font_size_override("font_size", 15)
	v.add_child(_num)
	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = true
	_texto.fit_content = true
	_texto.scroll_active = false
	_texto.custom_minimum_size = Vector2(300, 0)
	v.add_child(_texto)
	_puntos = HBoxContainer.new()
	_puntos.add_theme_constant_override("separation", 5)
	v.add_child(_puntos)
	var h := HBoxContainer.new()
	v.add_child(h)
	# La tarjeta no debe estorbar al arrastrar y soltar: solo sus botones reciben clics.
	for n in [_tarjeta, v, _num, _texto, _puntos, h]:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.pressed.connect(detener)
	h.add_child(cerrar)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(sp)
	_siguiente = Button.new()
	_siguiente.pressed.connect(avanzar)
	Estilo.pintar(_siguiente, Estilo.MORADO)
	h.add_child(_siguiente)


func iniciar() -> void:
	activo = true
	paso = 0
	visible = true
	_mostrar()


func detener() -> void:
	activo = false
	visible = false
	terminado.emit()


func avanzar() -> void:
	paso += 1
	if paso >= pasos.size():
		detener()
		return
	_mostrar()


func avisar(ev: String) -> void:
	if activo and not _bloqueado and pasos[paso]["ev"] == ev:
		_bloqueado = true
		await get_tree().create_timer(0.35).timeout
		_bloqueado = false
		if activo and paso < pasos.size() and pasos[paso]["ev"] == ev:
			avanzar()


func _mostrar() -> void:
	var p: Dictionary = pasos[paso]
	_num.text = "Paso %d de %d" % [paso + 1, pasos.size()]
	_texto.text = p["txt"]
	_siguiente.text = "Terminar" if paso == pasos.size() - 1 else "Saltar paso  ›"
	for c in _puntos.get_children():
		c.queue_free()
	for i in pasos.size():
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(8, 8)
		d.color = Estilo.MORADO if i <= paso else Color("ddd8ff")
		_puntos.add_child(d)
	_tarjeta.reset_size()


func _rect_objetivo() -> Rect2:
	var c: Control = objetivos.get(pasos[paso]["obj"])
	if c == null or not c.is_visible_in_tree():
		return Rect2()
	return c.get_global_rect()


func _process(_d: float) -> void:
	if not activo:
		return
	queue_redraw()
	var r := _rect_objetivo()
	var tam := _tarjeta.size
	var pos := Vector2(size.x - tam.x - 20, size.y - tam.y - 20)
	if r.size != Vector2.ZERO:
		if r.end.x + tam.x + 30 < size.x:
			pos = Vector2(r.end.x + 20, clampf(r.position.y + 10, 70, size.y - tam.y - 10))
		else:
			pos = Vector2(clampf(r.position.x, 10, size.x - tam.x - 10), minf(r.end.y + 16, size.y - tam.y - 10))
	_tarjeta.position = pos


func _draw() -> void:
	if not activo:
		return
	var r := _rect_objetivo().grow(8)
	var sombra := Color(0.08, 0.06, 0.23, 0.6)
	if r.size == Vector2.ZERO:
		return
	draw_rect(Rect2(0, 0, size.x, maxf(0, r.position.y)), sombra)
	draw_rect(Rect2(0, r.end.y, size.x, maxf(0, size.y - r.end.y)), sombra)
	draw_rect(Rect2(0, r.position.y, maxf(0, r.position.x), r.size.y), sombra)
	draw_rect(Rect2(r.end.x, r.position.y, maxf(0, size.x - r.end.x), r.size.y), sombra)
	draw_rect(r, Estilo.AMARILLO, false, 4.0)
