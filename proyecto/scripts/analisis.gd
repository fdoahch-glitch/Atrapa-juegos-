extends RefCounted
## «Analizar mi juego»: mide cómo corre de verdad (cuadros por segundo, dibujos por cuadro, memoria de imágenes)
## y propone mejoras de rendimiento y de apariencia. Cada una trae un botón que la aplica.

const Rend := preload("res://scripts/rendimiento.gd")
const Partida := preload("res://scripts/partida.gd")

## Cuántas veces más lento suele ir un celular o un navegador respecto de un PC (cálculo aproximado y honesto).
const FACTOR := {"windows": 1.0, "linux": 1.0, "android": 4.0, "web": 2.5}


## Corre cada mundo de verdad durante unos segundos y devuelve una medición por mundo.
## host: nodo dentro del árbol donde se monta la prueba (invisible).
static func medir(host: Node, proy: Dictionary, seg: float = 1.5, al_avanzar: Callable = Callable()) -> Array:
	var salida: Array = []
	var cant: int = mini(proy["niveles"].size(), 8)
	AudioServer.set_bus_mute(0, true)
	for i in cant:
		if al_avanzar.is_valid():
			al_avanzar.call(i, cant)
		var n: Dictionary = (proy["niveles"][i] as Dictionary).duplicate(true)
		n["reglas"] = proy["reglas"]
		var sv := SubViewport.new()
		sv.size = Vector2i(960, 540)
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		host.add_child(sv)
		var j: Control = Partida.clase_para(n).new()
		sv.add_child(j)
		j.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		j.iniciar(n, false, false)
		var t_fin := Time.get_ticks_msec() + int(seg * 1000.0)
		var cuadros := 0
		var peor := 0.0
		var t0 := Time.get_ticks_msec()
		var ult := t0
		var dib := 0
		var objs := 0
		await host.get_tree().process_frame   # el primer cuadro carga imágenes: no cuenta
		while Time.get_ticks_msec() < t_fin and cuadros < 400:
			await host.get_tree().process_frame
			var ahora := Time.get_ticks_msec()
			peor = maxf(peor, float(ahora - ult))
			ult = ahora
			cuadros += 1
			dib = maxi(dib, int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)))
			objs = maxi(objs, int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)))
		var dur := maxf(0.001, float(Time.get_ticks_msec() - t0) / 1000.0)
		salida.append({
			"nivel": i, "fps": float(cuadros) / dur, "peor_ms": peor, "dibujos": dib, "objetos": objs,
			"tex_mb": float(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)) / 1048576.0,
		})
		sv.queue_free()
		await host.get_tree().process_frame
	AudioServer.set_bus_mute(0, false)
	return salida


static func _p(nivel: int, sev: String, cat: String, txt: String, sol: String, fix: Dictionary) -> Dictionary:
	return {"nivel": nivel, "sev": sev, "cat": cat, "txt": txt, "sol": sol, "fix": fix}


## Lista de mejoras. med viene de medir() (puede ir vacío: entonces sólo se revisa lo que se ve en los datos).
static func mejoras(p: Dictionary, med: Array) -> Array:
	var res: Array = []
	var reglas: Dictionary = p["reglas"]
	var plat := str(reglas.get("plataforma", "windows"))
	var nom_plat: String = Rend.PERFILES.get(plat, Rend.PERFILES["windows"])["nombre"]
	var movil := plat in ["android", "web"]
	var rend: Dictionary = Rend.normal(reglas.get("rend", {}))
	var ya_rec: bool = rend == Rend.normal(Rend.recomendado(plat))
	# ---------- rendimiento medido
	for m in med:
		var i: int = m["nivel"]
		var n: Dictionary = p["niveles"][i]
		var nom := str(n.get("name", "Mundo %d" % (i + 1)))
		var est: float = float(m["fps"]) / float(FACTOR.get(plat, 1.0))
		if ya_rec and (est < 45.0 or int(m["dibujos"]) > (400 if movil else 1500)):
			res.append(_p(i, "consejo", "rendimiento", "%s: ya usas la calidad recomendada para %s y aun así va justo (~%.0f FPS estimados)." % [nom, nom_plat, est], "Quita objetos repetidos o decoración muy grande de este mundo.", {"op": "info"}))
		elif est < 30.0:
			res.append(_p(i, "aviso", "rendimiento", "%s: en este computador va a %.0f FPS; en %s se estima ~%.0f FPS (se sentiría lento)." % [nom, m["fps"], nom_plat, est], "Poner la calidad recomendada para %s (imagen más liviana, sin bordes suaves)." % nom_plat, {"op": "calidad", "perfil": plat}))
		elif est < 45.0 and movil:
			res.append(_p(i, "consejo", "rendimiento", "%s: en %s se estima ~%.0f FPS: funciona, pero justo." % [nom, nom_plat, est], "Aplicar la calidad recomendada para %s." % nom_plat, {"op": "calidad", "perfil": plat}))
		if not ya_rec and int(m["dibujos"]) > (400 if movil else 1500):
			res.append(_p(i, "aviso", "rendimiento", "%s: dibuja %d cosas por cuadro, es mucho para %s." % [nom, m["dibujos"], nom_plat], "Bajar la calidad; si sigue pesado, reduce objetos repetidos del mundo.", {"op": "calidad", "perfil": plat}))
		if float(m["peor_ms"]) > 120.0:
			res.append(_p(i, "consejo", "rendimiento", "%s: hubo un tirón de %.0f ms (el juego se queda pegado un instante)." % [nom, m["peor_ms"]], "Suele ser cargar imágenes pesadas. Prueba convertir imágenes a WebP con «Testear ahora».", {"op": "info"}))
		if movil and float(m["tex_mb"]) > 300.0:
			res.append(_p(i, "aviso", "rendimiento", "%s: las imágenes ocupan %.0f MB de memoria; un celular o navegador puede cerrarse." % [nom, m["tex_mb"]], "Usar imágenes más chicas o convertirlas a WebP.", {"op": "info"}))
	# ---------- rendimiento por configuración
	if movil and bool(reglas.get("paleta_todo", false)):
		res.append(_p(-1, "aviso", "rendimiento", "«Pintar toda la pantalla con la paleta» cuesta mucho en %s (repinta cada punto en cada cuadro)." % nom_plat, "Apagarlo: los objetos conservan su paleta igual.", {"op": "paleta_todo_off"}))
	if movil and int(rend["msaa"]) > 0:
		res.append(_p(-1, "aviso", "rendimiento", "Los bordes suaves (MSAA) gastan batería en %s y casi no se notan." % nom_plat, "Apagarlos.", {"op": "msaa_off"}))
	if movil and float(rend["escala"]) > 0.85 and plat == "android":
		res.append(_p(-1, "consejo", "rendimiento", "La imagen está al %d %%. En celular al 75 %% se ve casi igual y va más fluido." % int(float(rend["escala"]) * 100.0), "Poner la imagen al 75 %.", {"op": "escala", "v": 0.75}))
	if plat == "web" and int(rend.get("fps", 60)) == 0:
		res.append(_p(-1, "consejo", "rendimiento", "Sin límite de FPS en el navegador calienta el equipo.", "Limitar a 60.", {"op": "fps", "v": 60}))
	var rigidos := 0
	for n2 in p["niveles"]:
		for it in n2.get("items", []):
			if str(it.get("t", "")) in ["rueda", "pelota", "cuerda"]:
				rigidos += 1
	if rigidos > 25 and movil:
		res.append(_p(-1, "consejo", "rendimiento", "Hay %d objetos con física real (ruedas, pelotas, cuerdas). Muchos a la vez cuestan en %s." % [rigidos, nom_plat], "Deja los que se vean y borra los repetidos.", {"op": "info"}))
	# ---------- apariencia
	for i in p["niveles"].size():
		var n3: Dictionary = p["niveles"][i]
		var nom3 := str(n3.get("name", "Mundo %d" % (i + 1)))
		var items: Array = n3.get("items", [])
		var decos := 0
		var premios := 0
		var plats := 0
		for it in items:
			match str(it.get("t", "")):
				"deco": decos += 1
				"coin", "star", "gem": premios += 1
				"plat": plats += 1
		var tipo := Datos.tipo_de(n3)
		if tipo == "plataformas" and str(n3.get("estilo", "")) == "" and plats >= 3 and decos == 0:
			res.append(_p(i, "consejo", "visual", "%s: no tiene decoración (árboles, flores, rocas). Se ve vacío." % nom3, "Poner decoración automática sobre algunas plataformas.", {"op": "deco_auto"}))
		if tipo == "plataformas" and str(n3.get("estilo", "")) == "" and premios == 0:
			res.append(_p(i, "consejo", "visual", "%s: no hay monedas ni estrellas: nada guía la mirada ni invita a avanzar." % nom3, "Poner monedas sobre las plataformas.", {"op": "monedas_auto"}))
		if str(n3.get("fondo", "")) == "" and str(n3.get("theme", "dia")) == "dia" and p["niveles"].size() > 1 and i > 0:
			var otros := 0
			for k in i:
				if str(p["niveles"][k].get("theme", "dia")) == "dia":
					otros += 1
			if otros == i:
				res.append(_p(i, "consejo", "visual", "%s: usa el mismo cielo «Día soleado» que los mundos anteriores. Cambiar de ambiente hace el juego más variado." % nom3, "Elige otro ambiente en la pestaña Fondos.", {"op": "info"}))
	if str(reglas.get("musica", "")) == "":
		res.append(_p(-1, "consejo", "visual", "Tu juego no tiene música. Con música se siente mucho más vivo.", "Elige una melodía en «Reglas».", {"op": "info"}))
	if str(reglas.get("paleta", "")) == "" and p["niveles"].size() >= 1:
		var raros := 0
		for n4 in p["niveles"]:
			for it in n4.get("items", []):
				if str(it.get("e", "")).begins_with("g:"):
					raros += 1
		if raros > 25:
			res.append(_p(-1, "consejo", "visual", "Usas muchos objetos de la biblioteca de colores distintos. Una paleta global los une y el juego se ve más armonioso.", "Elige una paleta en Efectos (por ejemplo la de tu ambiente).", {"op": "info"}))
	return res


## Aplica una mejora. true si cambió algo.
static func aplicar(prob: Dictionary) -> bool:
	var op := str(prob["fix"].get("op", ""))
	var proy := Datos.proyecto()
	var r: Dictionary = proy["reglas"]
	var cambio := false
	match op:
		"paleta_todo_off":
			r["paleta_todo"] = false
			cambio = true
		"msaa_off":
			var d := Rend.normal(r.get("rend", {}))
			d["msaa"] = 0
			r["rend"] = d
			cambio = true
		"escala":
			var d2 := Rend.normal(r.get("rend", {}))
			d2["escala"] = float(prob["fix"]["v"])
			r["rend"] = Rend.normal(d2)
			cambio = true
		"fps":
			var d3 := Rend.normal(r.get("rend", {}))
			d3["fps"] = int(prob["fix"]["v"])
			r["rend"] = Rend.normal(d3)
			cambio = true
		"deco_auto", "monedas_auto":
			var i: int = prob["nivel"]
			if i >= 0 and i < proy["niveles"].size():
				var items: Array = proy["niveles"][i]["items"]
				var pl: Array = items.filter(func(it): return str(it.get("t", "")) == "plat" and int(it.get("w", 1)) >= 2)
				pl.sort_custom(func(a, b): return int(a["x"]) < int(b["x"]))
				var lista := ["🌳", "🌷", "🪨", "🌲", "🍄", "🌻"]
				var k := 0
				for it in pl:
					if k >= 8:
						break
					var y := int(it["y"]) - 1
					if y < 0:
						continue
					if op == "deco_auto":
						items.append({"id": Datos.nuevo_id(), "t": "deco", "e": lista[k % lista.size()], "x": int(it["x"]) + int(it.get("w", 1)) - 1, "y": y, "s": 60})
					else:
						for c in mini(3, int(it.get("w", 1))):
							items.append({"id": Datos.nuevo_id(), "t": "coin", "x": int(it["x"]) + c, "y": y - 1})
					k += 1
				cambio = k > 0
		_:
			if op == "calidad":
				cambio = Rend.corregir(prob)
				return cambio
	if cambio:
		var idx := Datos.idx
		Datos.establecer_proyecto(Datos.proyecto_desde(proy))
		Datos.ir_a_nivel(clampi(idx, 0, Datos.num_niveles() - 1))
	return cambio
