extends RefCounted
## Terrenos con autotile real de Godot: un TileMapLayer con TileSet de terreno
## (16 piezas según qué vecinos tiene cada celda). Los bordes y la hierba se
## ajustan solos al unir o separar bloques.

const BORDES := {1: Vector2i(0, -1), 2: Vector2i(1, 0), 4: Vector2i(0, 1), 8: Vector2i(-1, 0)}


static func _atlas(T: int, col_top: Color, col_cuerpo: Color) -> Image:
	var img := Image.create(T * 4, T * 4, false, Image.FORMAT_RGBA8)
	var borde := col_cuerpo.darkened(0.35)
	for m in 16:
		var ox := (m % 4) * T
		var oy := (m / 4) * T
		for y in T:
			for x in T:
				var c := col_cuerpo
				if (y + x / 3) % 11 == 0:
					c = col_cuerpo.lightened(0.06)
				var grosor := 4
				if (m & 1) == 0 and y < grosor + 5:
					c = col_top if y < grosor + 5 else c
				if (m & 1) == 0 and y < 2:
					c = col_top.lightened(0.25)
				if (m & 4) == 0 and y >= T - 3:
					c = borde
				if (m & 8) == 0 and x < 3:
					c = borde
				if (m & 2) == 0 and x >= T - 3:
					c = borde
				img.set_pixel(ox + x, oy + y, c)
	return img


static func conjunto(T: int, col_top: Color, col_cuerpo: Color) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_terrain_set()
	ts.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
	ts.add_terrain(0)
	ts.set_terrain_name(0, 0, "suelo")
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(_atlas(T, col_top, col_cuerpo))
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	var lados := {1: TileSet.CELL_NEIGHBOR_TOP_SIDE, 2: TileSet.CELL_NEIGHBOR_RIGHT_SIDE, 4: TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, 8: TileSet.CELL_NEIGHBOR_LEFT_SIDE}
	for m in 16:
		var ac := Vector2i(m % 4, m / 4)
		src.create_tile(ac)
		var td := src.get_tile_data(ac, 0)
		td.terrain_set = 0
		td.terrain = 0
		for b in lados:
			td.set_terrain_peering_bit(lados[b], 0 if (m & b) != 0 else -1)
	return ts


## Crea la capa con todas las plataformas (rectángulos en píxeles).
static func capa(rects: Array, T: int, tema: Dictionary) -> TileMapLayer:
	var cols: Array = tema.get("plat", [Color(0.4, 0.8, 0.3), Color(0.5, 0.35, 0.2)])
	var l := TileMapLayer.new()
	l.tile_set = conjunto(T, cols[0], cols[1])
	var celdas: Array[Vector2i] = []
	for r in rects:
		var rr: Rect2 = r
		for cy in int(round(rr.size.y / T)):
			for cx in int(round(rr.size.x / T)):
				celdas.append(Vector2i(int(round(rr.position.x / T)) + cx, int(round(rr.position.y / T)) + cy))
	l.set_cells_terrain_connect(celdas, 0, 0)
	l.collision_enabled = false
	return l
