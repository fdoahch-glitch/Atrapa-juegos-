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

## Dino Run (pack de dinosaurios)
En la pantalla de inicio, el botón «Abrir Dino Run» instala 10 dinosaurios 3D animados en «Mis cosas»
(T-Rex, Triceratops, Pterodáctilo, Plesiosaurio, Spinosaurio, Estegosaurio, Anquilosaurio, Paquicefalo,
Oviraptor, Carnotauro) y abre un proyecto de 5 mundos (Jungla, Desierto, Hielo, Pantano, Valle) con
obstáculos, huevos y 3 vidas. Todo se edita con arrastrar y soltar. Los modelos GLB con animación ahora
se reproducen solos en bucle.

## Mascotas con poder
En «Reglas» eliges una mascota (emoji, animalito, tus modelos o dibujos importados) y su poder:
Escudo (te protege de 1 golpe), Doble escudo (2 golpes), Vida extra, Imán (recoge premios desde más lejos)
o Más puntos (×1,5). Funciona en plataformas 2D, 2.5D, corredor, aventura y vista desde arriba;
la mascota te acompaña y se exporta con el juego. Dino Run usa la tienda en vez de una mascota fija.

## Cambiar el tipo de juego
Botón «Tipo de juego» (arriba): convierte el nivel a Plataformas 2D, 2.5D, Vista desde arriba, Aventura 3D
o Corredor 3D. Se crea como un nivel nuevo (el original no se toca) y se conservan héroe, tema, fondo,
monedas, estrellas, gemas, enemigos, pinchos, meta y decoración. Revisa el resultado y ajústalo a mano.

## Tienda y 2 jugadores
- Reglas → «Tienda de mascotas: Sí»: las monedas de cada partida se guardan y se compran mascotas con poder
  (pantalla de título → «Tienda de mascotas»). Dino Run trae la tienda con sus 15 mascotas.
- Reglas → «Jugadores: 2» (solo Corredor 3D): Jugador 1 con A D W S, Jugador 2 con las flechas; vidas y puntos compartidos.

## Dinosaurios chilenos de Dino Run (personajes jugables)
Los 5 dinosaurios chilenos del juego original son los PERSONAJES JUGABLES: Chilesaurus (salto más alto),
Atacamatitán (la comida vale +20%), Arackar (empiezas con 4 vidas), Stegouros (2,6 s de protección tras un golpe)
y Gonkoken (salto alto y ágil). En la pantalla de título: «Elegir dinosaurio». Ninguno es mascota.

## Tienda de mascotas de Dino Run
Las 15 mascotas originales, con su precio y su poder, se compran con monedas: Pteranodón, Triceratops, Velociraptor,
Dilofosaurio, Iguanodón, Estegosaurio, Parasaurolophus, Pachycephalosaurus (Mini), Anquilosaurio, Apatosaurio, Espinosaurio,
Tyrannosaurus Rex (Mini), Oviraptor, Carnotaurio y Plesiosaurio. Aún no están: accesorios, piezas coleccionables,
bitácora de fósiles, persecuciones (se aproximan como enemigos más lentos) ni las skins Brachiosaurus y Clásico. Nota: Godot no lee modelos con la extensión
KHR_mesh_quantization; estos se convirtieron antes de incluirlos. Si un .glb tuyo no carga, conviértelo igual.

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
