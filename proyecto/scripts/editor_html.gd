extends RefCounted
## Editor visual para juegos y páginas HTML. Se abre en el navegador, sin internet.

const RUTA := "user://editor_html.html"


static func abrir() -> bool:
	var f := FileAccess.open(RUTA, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(PAGINA)
	f.close()
	return OS.shell_open(ProjectSettings.globalize_path(RUTA)) == OK


const PAGINA := """<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8"><title>Editor visual HTML · Atrapa Juegos Estudio</title>
<style>
*{box-sizing:border-box}body{margin:0;font-family:system-ui,sans-serif;background:#241b4b;color:#241b4b;display:flex;flex-direction:column;height:100vh}
header{background:linear-gradient(90deg,#00c4cc,#6d4aff);padding:10px;display:flex;gap:8px;flex-wrap:wrap;align-items:center;color:#fff}
header b{font-size:18px;margin-right:8px}button,label.btn{background:#fff;color:#241b4b;border:0;border-radius:12px;padding:9px 14px;font-weight:700;cursor:pointer;font-size:14px}
button.y{background:#ffd23f}button.p{background:#6d4aff;color:#fff}main{flex:1;display:flex;min-height:0}
#lado{width:290px;background:#fff;padding:12px;overflow:auto;font-size:14px}#lado h3{margin:6px 0}
#lado label{display:block;margin:8px 0 2px;font-weight:700}#lado input,#lado textarea{width:100%;padding:7px;border:2px solid #e3dfff;border-radius:10px;font-size:14px}
#lado input[type=color]{height:38px;padding:2px}#cen{flex:1;display:flex;justify-content:center;align-items:flex-start;overflow:auto;padding:12px}
iframe{background:#fff;border:0;border-radius:10px;width:100%;height:100%;min-height:500px}#msg{color:#fff;margin-left:auto;font-size:13px}
.fila{display:flex;gap:6px}.fila button{flex:1;padding:7px 4px;font-size:13px;background:#f1efff}
</style></head><body>
<header><b>Editor visual HTML</b>
<label class="btn y">Abrir juego .html<input id="abrir" type="file" accept=".html,.htm" hidden></label>
<button id="deshacer">Deshacer</button><button id="modo" class="p">Probar el juego</button><button id="guardar" class="y">Descargar HTML</button>
<span id="msg">Abre tu archivo .html, haz clic en cualquier cosa para editarla y arrastra para moverla.</span></header>
<main><div id="cen"><iframe id="v" sandbox="allow-same-origin"></iframe></div>
<aside id="lado"><h3>Elemento</h3><div id="nada">Haz clic en algo de la página.</div>
<div id="panel" hidden>
<div id="etq" style="color:#6d4aff;font-weight:700"></div>
<label>Texto</label><textarea id="txt" rows="3"></textarea>
<label>Color del texto</label><input id="col" type="color">
<label>Color de fondo</label><input id="fon" type="color">
<label>Tamaño de letra (px)</label><input id="tam" type="number" min="6" max="200">
<label>Ancho (px)</label><input id="anc" type="number" min="0">
<label>Alto (px)</label><input id="alt" type="number" min="0">
<label>Esquinas redondas (px)</label><input id="rad" type="number" min="0" max="200">
<label>Transparencia (0 a 1)</label><input id="opa" type="number" min="0" max="1" step="0.1">
<label>Cambiar imagen</label><input id="img" type="file" accept="image/*">
<div class="fila" style="margin-top:10px"><button id="dup">Duplicar</button><button id="del">Borrar</button></div>
</div><h3 style="margin-top:18px">Agregar</h3>
<div class="fila"><button id="aT">Texto</button><button id="aB">Botón</button><button id="aC">Caja</button></div>
<label>Agregar imagen</label><input id="aI" type="file" accept="image/*"></aside></main>
<script>
var v=document.getElementById('v'),sel=null,hist=[],modoProbar=false,drag=null,base='';
function $(i){return document.getElementById(i)}
function d(){return v.contentDocument}
function say(t){$('msg').textContent=t}
function limpio(){var c=d().documentElement.cloneNode(true);
  c.querySelectorAll('[data-sel]').forEach(function(e){e.removeAttribute('data-sel')});
  var s=c.querySelector('#__ed');if(s)s.remove();return '<!DOCTYPE html>\\n'+c.outerHTML}
function snap(){hist.push(limpio());if(hist.length>60)hist.shift()}
function cargar(h){v.srcdoc=h;v.onload=function(){if(modoProbar)return;
  var st=d().createElement('style');st.id='__ed';st.textContent='[data-sel]{outline:3px solid #6d4aff!important;outline-offset:2px}*{cursor:default}';
  d().head.appendChild(st);d().addEventListener('mousedown',dn,true);d().addEventListener('mousemove',mv,true);d().addEventListener('mouseup',up,true);
  d().addEventListener('click',function(e){e.preventDefault()},true);d().addEventListener('keydown',kd,true);sel=null;mostrar()}}
function dn(e){e.preventDefault();var t=e.target;if(t===d().documentElement)t=d().body;seleccionar(t);
  var cs=d().defaultView.getComputedStyle(t);var tx=parseFloat(t.getAttribute('data-x')||0),ty=parseFloat(t.getAttribute('data-y')||0);
  drag={x:e.clientX,y:e.clientY,tx:tx,ty:ty,moved:false}}
function mv(e){if(!drag||!sel||sel===d().body)return;var dx=e.clientX-drag.x,dy=e.clientY-drag.y;
  if(!drag.moved&&Math.abs(dx)+Math.abs(dy)<4)return;if(!drag.moved){snap();drag.moved=true}
  mover(sel,drag.tx+dx,drag.ty+dy)}
function up(){drag=null}
function mover(el,x,y){el.setAttribute('data-x',x);el.setAttribute('data-y',y);el.style.transform='translate('+x+'px,'+y+'px)'}
function kd(e){if(!sel||sel===d().body)return;var s=e.shiftKey?10:1,x=parseFloat(sel.getAttribute('data-x')||0),y=parseFloat(sel.getAttribute('data-y')||0),m=true;
  if(e.key=='ArrowLeft')x-=s;else if(e.key=='ArrowRight')x+=s;else if(e.key=='ArrowUp')y-=s;else if(e.key=='ArrowDown')y+=s;else if(e.key=='Delete'){borrar();return}else m=false;
  if(m){e.preventDefault();snap();mover(sel,x,y)}}
function seleccionar(t){if(sel)sel.removeAttribute('data-sel');sel=t;sel.setAttribute('data-sel','1');mostrar()}
function hex(c){var m=c.match(/\\d+/g);if(!m||(m.length>3&&+m[3]===0))return '#ffffff';return '#'+m.slice(0,3).map(function(n){return ('0'+(+n).toString(16)).slice(-2)}).join('')}
function mostrar(){$('nada').hidden=!!sel;$('panel').hidden=!sel;if(!sel)return;
  var cs=d().defaultView.getComputedStyle(sel);$('etq').textContent='<'+sel.tagName.toLowerCase()+'>'+(sel.id?' #'+sel.id:'');
  $('txt').value=sel.children.length===0?sel.textContent:'(tiene otros elementos dentro)';$('txt').disabled=sel.children.length!==0;
  $('col').value=hex(cs.color);$('fon').value=hex(cs.backgroundColor);$('tam').value=parseFloat(cs.fontSize);
  $('anc').value=Math.round(sel.getBoundingClientRect().width);$('alt').value=Math.round(sel.getBoundingClientRect().height);
  $('rad').value=parseFloat(cs.borderRadius)||0;$('opa').value=cs.opacity}
function cambiar(id,fn){$(id).addEventListener('input',function(){if(!sel)return;snap();fn($(id).value)})}
cambiar('txt',function(x){sel.textContent=x});cambiar('col',function(x){sel.style.color=x});cambiar('fon',function(x){sel.style.backgroundColor=x});
cambiar('tam',function(x){sel.style.fontSize=x+'px'});cambiar('anc',function(x){sel.style.width=x+'px'});cambiar('alt',function(x){sel.style.height=x+'px'});
cambiar('rad',function(x){sel.style.borderRadius=x+'px'});cambiar('opa',function(x){sel.style.opacity=x});
function leer(f,cb){var r=new FileReader();r.onload=function(){cb(r.result)};r.readAsDataURL(f)}
$('img').onchange=function(e){if(sel&&e.target.files[0]){snap();leer(e.target.files[0],function(u){if(sel.tagName=='IMG')sel.src=u;else sel.style.backgroundImage='url('+u+')'})}};
function borrar(){if(sel&&sel!==d().body){snap();sel.remove();sel=null;mostrar()}}
$('del').onclick=borrar;
$('dup').onclick=function(){if(sel&&sel!==d().body){snap();var c=sel.cloneNode(true);c.removeAttribute('data-sel');sel.after(c);seleccionar(c);mover(c,(+c.getAttribute('data-x')||0)+20,(+c.getAttribute('data-y')||0)+20)}};
function agregar(el){snap();(sel&&sel!==d().body&&sel.children.length>=0&&sel.tagName!='IMG'&&sel.tagName!='BUTTON'?d().body:d().body).appendChild(el);seleccionar(el)}
$('aT').onclick=function(){var e=d().createElement('p');e.textContent='Nuevo texto';e.style.cssText='font-size:28px;color:#241b4b';agregar(e)};
$('aB').onclick=function(){var e=d().createElement('button');e.textContent='Botón';e.style.cssText='font-size:22px;padding:12px 22px;border:0;border-radius:14px;background:#ffd23f';agregar(e)};
$('aC').onclick=function(){var e=d().createElement('div');e.style.cssText='width:160px;height:100px;background:#6d4aff;border-radius:16px';agregar(e)};
$('aI').onchange=function(e){if(e.target.files[0])leer(e.target.files[0],function(u){var i=d().createElement('img');i.src=u;i.style.maxWidth='240px';agregar(i)})};
$('deshacer').onclick=function(){if(hist.length){cargar(hist.pop());say('Deshecho')}};
$('modo').onclick=function(){if(!base&&!hist.length&&!v.srcdoc)return;var h=limpio();modoProbar=!modoProbar;
  if(modoProbar){v.setAttribute('sandbox','allow-scripts allow-same-origin allow-pointer-lock');v.srcdoc=h;$('modo').textContent='Volver a editar';say('Probando: los scripts del juego funcionan aquí')}
  else{v.setAttribute('sandbox','allow-same-origin');cargar(h);$('modo').textContent='Probar el juego';say('Editando')}};
$('guardar').onclick=function(){var h=modoProbar?v.srcdoc:limpio();var a=document.createElement('a');a.href=URL.createObjectURL(new Blob([h],{type:'text/html'}));a.download='mi-juego-editado.html';a.click();say('Descargado')};
$('abrir').onchange=function(e){var f=e.target.files[0];if(!f)return;var r=new FileReader();r.onload=function(){base=r.result;hist=[];modoProbar=false;v.setAttribute('sandbox','allow-same-origin');cargar(base);say('Abierto: '+f.name)};r.readAsText(f)};
cargar('<!DOCTYPE html><html><body style="font-family:sans-serif;text-align:center;padding:60px"><h1>Abre tu juego .html con el botón amarillo</h1><p>Aquí podrás cambiar textos, colores, tamaños, mover y agregar cosas.</p></body></html>');
</script></body></html>"""
