# Atrapa Juegos Studio (Godot 4.4)

Creador visual de juegos de plataformas, hecho para que un niño lo entienda.
Hermano de "Estudio de Cuentos Animados". Todo en español.

## Abrir y probar
1. Instala Godot 4.4.x (gratis, https://godotengine.org).
2. Importa esta carpeta (archivo `project.godot`) y pulsa ▶.

## Cómo se usa
Elige Personajes, Fondos y Objetos y arrástralos al escenario (en tablet: toca la ficha y luego el escenario).
Pulsa ¡Jugar! para probar. El tutorial se abre solo la primera vez (botón Ayuda).

## Botón mágico: Exportar
Crea un juego listo para Web (.html), Windows (.exe) o Android (.apk).
Configuración única:
1. En Godot: Editor > Administrar plantillas de exportación > descarga las de TU misma versión.
2. En el creador: Exportar > "Elegir Godot…" y señala el ejecutable de Godot.
3. Android además necesita Android SDK + keystore configurados en Godot.
Los juegos salen en `Documentos/Mis juegos/<nombre>/<plataforma>`.
Si falla, mira `user://ultima_exportacion.log`.

## Distribuir el creador
Al exportar el creador a Windows/Android/Web, incluye junto al ejecutable la carpeta `plantilla_juego/`
(el botón mágico la usa). Tras cambiar scripts del motor ejecuta `python3 tools/sincronizar_plantilla.py`.

## Web
Sirve la carpeta exportada por HTTP (no con file://). Incluye PWA instalable.

## Niveles
"Copiar código del nivel" / "Pegar nivel" son compatibles con la versión web (artefacto).

## Mascotas con poder
En «Reglas» eliges una mascota (emoji, animalito, tus modelos o dibujos importados) y su poder:
Escudo (te protege de 1 golpe), Doble escudo (2 golpes), Vida extra, Imán (recoge premios desde más lejos)
o Más puntos (×1,5). Funciona en plataformas 2D, 2.5D, corredor, aventura y vista desde arriba;
la mascota te acompaña y se exporta con el juego.

## Cambiar el tipo de juego
Botón «Tipo de juego» (arriba): convierte el nivel a Plataformas 2D, 2.5D, Vista desde arriba, Aventura 3D
o Corredor 3D. Se crea como un nivel nuevo (el original no se toca) y se conservan héroe, tema, fondo,
monedas, estrellas, gemas, enemigos, pinchos, meta y decoración. Revisa el resultado y ajústalo a mano.

## Tienda y 2 jugadores
- Reglas → «Tienda de mascotas: Sí»: las monedas de cada partida se guardan y se compran mascotas con poder
  (pantalla de título → «Tienda de mascotas»).
- Reglas → «Jugadores: 2» (solo Corredor 3D): Jugador 1 con A D W S, Jugador 2 con las flechas; vidas y puntos compartidos.

## Mejorar los dibujos
Mira docs/MEJORAR_DIBUJOS.md (dónde conseguir modelos y dibujos gratis y cómo usarlos). El botón «Editar un juego HTML» de la portada abre un editor visual para archivos .html.

## Guía y ejemplos
En la carpeta docs/ hay una guía para niños y familias (GUIA.md) y 5 juegos de ejemplo (docs/ejemplos/*.json): se abren con «Pegar nivel».

## Asistente, portada y etapas
Al abrir aparece la portada «Atrapa Juegos Estudio». «Empezar» pregunta plataforma (Windows, Linux, Android, Navegador), orientación (sólo Android), categoría y tipo de juego. El editor trabaja por etapas: **Portada → Personajes → Mundo 1, 2, 3…**

- **Portada:** fondo (con conversión a WebP/PNG/JPG), título y botones propios con dibujo. Clic derecho en un botón: *Animación* (flotar, latir, balancear, rebotar, brillar) y *Acción* (jugar, elegir personaje, tienda, salir).
- **Carreras de pista y Go-karts:** vueltas con línea de meta, rivales que corren solos, turbos (resorte), charcos de aceite (pinchos) y derrape con la barra espaciadora en karts. Los «enemigos» son los rivales.
- **Lucha 2D:** mejor de 3 rondas contra un rival con IA. Z = puñetazo, X = patada, ↓ = bloquear. En pantalla táctil hay botones.
- **Rendimiento / Testear (botón «Rendimiento»):** perfiles por plataforma (motor Vulkan o Compatibilidad, FSR 1/2.2, MSAA, FPS) y un verificador que busca inicio/meta que faltan, objetos tapados, fuera del mundo o inalcanzables, imágenes pesadas y calidad mal elegida, con botón *Aplicar corrección*.

## Carreras 3D, lucha con combos y 2 jugadores, selección de personajes
- **Carreras 3D y Go-karts 3D:** misma pista del editor, pero se juega con cámara detrás del auto (como Mario Kart).
- **Lucha:** 3 golpes seguidos hacen *combo* con daño extra. Con «2 jugadores» en Reglas: jugador 1 = A D W S + F/G, jugador 2 = flechas + K/L.
- **Etapa Personajes:** elige hasta 12 personajes (y su poder). Con 2 o más, el juego muestra «¿Con quién quieres jugar?».

## Biblioteca incluida (licencia libre)
La pestaña **Biblioteca** del editor trae ~150 modelos 3D (personas, animales, dinosaurios, monstruos, plataformas, escenarios,
vehículos) y ~115 sonidos, todos CC0. Se usan como héroe, enemigo, decoración o mascota, y viajan con el juego exportado.
Créditos en `docs/CREDITOS.md`.

## Exportar, guardar y abrir
**Exportar** es ahora una sola ventana: ① elige dónde jugarlo (Windows, navegador o Android), ② espera, ③ «Abrir la carpeta».
Se exportan todos los mundos. Debajo: **Guardar como archivo** (`.atrapa.json` + carpeta `assets`), **Abrir un archivo** y **Abrir un APK**.

## Abrir un APK (decompilador)
En la pantalla de inicio o en Exportar: «Abrir un APK». Extrae todo a Documentos → Mis juegos → APK-nombre y dice de qué tipo es
(juego web con Capacitor/Cordova, Godot, Unity…), el nombre del paquete y cuántas imágenes, sonidos y modelos trae.
Si es un juego web, su `index.html` queda listo para editarlo con «Editar un juego HTML». Las apps nativas solo permiten sacar sus recursos.

## Colores del mundo
Botón **Colores** (arriba): cielo, colinas, tierra y pasto de este mundo, con selector de color. Se guardan en el nivel (`paleta`).

## Ambiente, misiones y progreso (nuevo)
- **Colores → Ambiente** (mundos 3D): clima (lluvia, tormenta con rayos, nieve, ventisca, erupción, cambia solo), hora del día (día, atardecer, noche o ciclo que va pasando), perseguidor (un T-Rex te alcanza si chocas) y cantidad de objetos.
- **Reglas**: dificultad (Fácil/Normal/Difícil/Extrema, y si el jugador la elige), misiones del día, revivir al perder pagando monedas, modo prueba (todo desbloqueado).
- **Rendimiento**: brillo suave (bloom) y sombras para el 3D.
- En el juego: botones Misiones, Bitácora (fichas que se abren con fósiles), Vestuario (skins y accesorios con monedas) y Récords; mando (cruceta/palanca, A salta, B agacha) con vibración al chocar.
- Todo se guarda en el aparato del jugador (`user://progreso.json`). En el JSON del juego: `coleccion`, `skins`, `accesorios`, `misiones_lista`.

## Objetos de la pista (Colores → Objetos de la pista, mundos 3D)
- Cada obstáculo (bajo, alto, por arriba) puede ser uno de tus modelos 3D; en el JSON: `obstaculos: {"valla": ["g:tronco.glb", …], "pared": […], "viga": […]}` (si pones varios, salen alternados).
- «Adorno de los lados»: elige varios modelos y salen repartidos a ambos lados en vez de los árboles del tema (`decorado: [{e, alto, dist:[min,max]}]`).
- `premios: {"gem": "g:fosil.glb"}` cambia el dibujo de moneda, estrella o gema por un modelo.
- Un obstáculo alto con modelo propio solo choca por debajo de su altura real: una roca baja se puede saltar.

## Categorías, guía y asistente de ideas
- **Motor completo**: el .exe y el APK se compilan con todo Godot 4.4.1 (3D con física, navegación, GridMap, CSG, ruido, video…). Sólo la versión web usa un perfil recortado para pesar poco (`custom_web.py`).
- **Nuevas categorías**: Disparos (shooter desde arriba, Espacio o clic para disparar), Corredor 2D para celular (corre solo, tú saltas), Mundo libre, Narrativo y Otros géneros. Los tipos marcados «Pronto» aún no tienen juego.
- **🧭 Guía**: botón en la barra del editor; muestra los pasos de tu categoría en orden y abre cada panel.
- **💡 Cuéntame tu idea**: primera tarjeta al elegir categoría. Escribes de qué trata y recomienda categoría, enemigos, premios, puntuación y calidad (FSR, FPS) según la plataforma. Funciona sin internet.
