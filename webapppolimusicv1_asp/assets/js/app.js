/* =====================================================================
   PoliMusic  ·  assets/js/app.js
   ---------------------------------------------------------------------
   Reproductor de audio (vanilla JS):
   - Lee las filas .pista del DOM (data-src, data-titulo, data-artista...)
   - Cola de reproducción, anterior/siguiente, aleatorio y repetir
   - Control de volumen, barra de progreso y tiempos
   - Contador de reproducciones en el servidor (play_count.asp)
   - Tema claro/oscuro persistente y mensajes emergentes
   ===================================================================== */
(function () {
  "use strict";

  var audio      = document.getElementById("audio");
  var cola       = [];          // canciones en cola
  var indice     = -1;          // canción actual
  var aleatorio  = false;
  var repetir    = 0;           // 0 = no, 1 = repetir todo, 2 = repetir una
  var contadas   = {};          // ids ya contados en esta sesión de página

  var $ = function (id) { return document.getElementById(id); };

  var repPortada = $("repPortada"), repTitulo = $("repTitulo"), repArtista = $("repArtista"),
      repTiempo  = $("repTiempoActual"), repDuracion = $("repDuracion"),
      repBarra   = $("repBarra"), repVolumen = $("repVolumen"), repCola = $("repCola"),
      btnPlay    = $("btnPlay"), btnAnterior = $("btnAnterior"), btnSiguiente = $("btnSiguiente"),
      btnAleatorio = $("btnAleatorio"), btnRepetir = $("btnRepetir"),
      btnVolumen = $("btnVolumen"), btnFavorito = $("btnFavorito");

  /* ---------- utilidades ---------- */
  function reloj(seg) {
    if (!isFinite(seg) || seg < 0) seg = 0;
    var m = Math.floor(seg / 60), s = Math.floor(seg % 60);
    return m + ":" + (s < 10 ? "0" : "") + s;
  }

  function pintarProgreso(input) {
    var min = parseFloat(input.min) || 0, max = parseFloat(input.max) || 100;
    var pct = ((input.value - min) / (max - min)) * 100;
    input.style.setProperty("--progreso", pct.toFixed(2) + "%");
  }

  function aviso(texto, tipo) {
    var zona = $("zonaMensajes");
    if (!zona) return;
    var div = document.createElement("div");
    div.className = "toast" + (tipo === "error" ? " toast--error" : "");
    div.innerHTML = '<span class="toast__icon">' + (tipo === "error" ? "!" : "✓") + "</span>" +
                    '<span class="toast__body"><strong></strong><span></span></span>' +
                    '<button type="button" class="toast__close" aria-label="Cerrar">×</button>';
    var partes = texto.split("|");
    div.querySelectorAll(".toast__body span")[0].textContent = partes[0] || "";
    var detalle = div.querySelectorAll(".toast__body span")[1];
    if (partes[1] && detalle) detalle.textContent = partes[1];
    div.querySelector(".toast__close").addEventListener("click", function () {
      div.classList.add("saliendo");
      setTimeout(function () { div.remove(); }, 200);
    });
    zona.appendChild(div);
    setTimeout(function () { div.classList.add("saliendo"); }, 4200);
    setTimeout(function () { if (div.parentNode) div.remove(); }, 4500);
  }

  /* ---------- cola de reproducción ---------- */
  function leerFilas() {
    return Array.prototype.slice.call(document.querySelectorAll("tr.pista"));
  }

  function filaACancion(fila) {
    return {
      id: fila.getAttribute("data-id") || "",
      src: fila.getAttribute("data-src") || "",
      titulo: fila.getAttribute("data-titulo") || "Sin título",
      artista: fila.getAttribute("data-artista") || "",
      album: fila.getAttribute("data-album") || "",
      portada: fila.getAttribute("data-portada") || (window.PM_BASE || "/") + "assets/img/placeholder.svg",
      fila: fila
    };
  }

  function construirCola(filas, desde) {
    cola = filas.map(filaACancion);
    indice = desde || 0;
    actualizarCola();
  }

  function actualizarCola() {
    if (repCola) repCola.textContent = "Cola: " + cola.length;
  }

  function marcarReproduciendo() {
    leerFilas().forEach(function (f) { f.classList.remove("reproduciendo"); });
    if (cola[indice] && cola[indice].fila) cola[indice].fila.classList.add("reproduciendo");
  }

  /* ---------- contador de plays en el servidor ---------- */
  function contarReproduccion(id) {
    if (!id || contadas[id]) return;
    contadas[id] = true;
    var url = (window.PM_BASE || "/") + "play_count.asp?id=" + encodeURIComponent(id);
    fetch(url, { credentials: "same-origin" })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (d && d.ok) {
          var celda = $("plays" + d.id);
          if (celda) celda.textContent = d.plays;
          var fila = document.querySelector('tr.pista[data-id="' + d.id + '"]');
          if (fila) fila.setAttribute("data-plays", d.plays);
        }
      })
      .catch(function () { /* silencioso: el contador no debe interrumpir la música */ });
  }

  /* ---------- reproducción ---------- */
  function cargar(i, reproducir) {
    if (i < 0 || i >= cola.length) return;
    indice = i;
    var c = cola[i];
    audio.src = c.src;
    audio.load();
    if (repPortada) repPortada.src = c.portada;
    if (repTitulo) repTitulo.textContent = c.titulo;
    if (repArtista) repArtista.textContent = c.artista;
    if (repTiempo) repTiempo.textContent = "0:00";
    if (repDuracion) repDuracion.textContent = "0:00";
    if (repBarra) { repBarra.value = 0; pintarProgreso(repBarra); }
    marcarReproduciendo();
    contarReproduccion(c.id);
    if (reproducir !== false) {
      var p = audio.play();
      if (p && p.catch) p.catch(function () {});
    }
    actualizarIconos();
  }

  function siguiente() {
    if (!cola.length) return;
    if (aleatorio) {
      var n;
      do { n = Math.floor(Math.random() * cola.length); } while (cola.length > 1 && n === indice);
      cargar(n);
    } else if (indice + 1 < cola.length) {
      cargar(indice + 1);
    } else if (repetir === 1) {
      cargar(0);
    }
  }

  function anterior() {
    if (!cola.length) return;
    if (audio.currentTime > 4) { audio.currentTime = 0; return; }
    if (indice > 0) cargar(indice - 1);
    else if (repetir === 1) cargar(cola.length - 1);
  }

  function alternarPlay() {
    if (!audio.src) {
      var filas = leerFilas();
      if (filas.length) { construirCola(filas, 0); cargar(0); }
      return;
    }
    if (audio.paused) { var p = audio.play(); if (p && p.catch) p.catch(function(){}); }
    else audio.pause();
    actualizarIconos();
  }

  function actualizarIconos() {
    if (!btnPlay) return;
    var pausado = audio.paused;
    var icoPlay = btnPlay.querySelector(".ico-play");
    var icoPausa = btnPlay.querySelector(".ico-pausa");
    if (icoPlay) icoPlay.style.display = pausado ? "" : "none";
    if (icoPausa) icoPausa.style.display = pausado ? "none" : "";
    btnPlay.setAttribute("aria-label", pausado ? "Reproducir" : "Pausar");
  }

  /* ---------- eventos del reproductor ---------- */
  if (btnPlay) btnPlay.addEventListener("click", alternarPlay);
  if (btnSiguiente) btnSiguiente.addEventListener("click", siguiente);
  if (btnAnterior) btnAnterior.addEventListener("click", anterior);

  if (btnAleatorio) btnAleatorio.addEventListener("click", function () {
    aleatorio = !aleatorio;
    btnAleatorio.classList.toggle("activo", aleatorio);
    aviso((aleatorio ? "Aleatorio activado" : "Aleatorio desactivado"));
  });

  if (btnRepetir) btnRepetir.addEventListener("click", function () {
    repetir = (repetir + 1) % 3;
    btnRepetir.classList.remove("activo", "repetir-uno");
    if (repetir === 1) { btnRepetir.classList.add("activo"); aviso("Repetir toda la cola"); }
    else if (repetir === 2) { btnRepetir.classList.add("activo"); btnRepetir.classList.add("repetir-uno"); aviso("Repetir esta canción"); }
    else aviso("Repetición desactivada");
  });

  if (btnFavorito) btnFavorito.addEventListener("click", function () {
    btnFavorito.classList.toggle("activo");
    aviso(btnFavorito.classList.contains("activo") ? "Añadida a favoritas|Te gusta esta canción" : "Quitada de favoritas");
  });

  if (btnVolumen) btnVolumen.addEventListener("click", function () {
    audio.muted = !audio.muted;
    btnVolumen.classList.toggle("activo", audio.muted);
    btnVolumen.setAttribute("aria-label", audio.muted ? "Activar sonido" : "Silenciar");
  });

  audio.addEventListener("timeupdate", function () {
    if (repTiempo) repTiempo.textContent = reloj(audio.currentTime);
    if (repBarra && audio.duration) {
      repBarra.value = (audio.currentTime / audio.duration) * 100;
      pintarProgreso(repBarra);
    }
  });

  audio.addEventListener("loadedmetadata", function () {
    if (repDuracion) repDuracion.textContent = reloj(audio.duration);
  });

  audio.addEventListener("play", actualizarIconos);
  audio.addEventListener("pause", actualizarIconos);

  audio.addEventListener("ended", function () {
    if (repetir === 2) { audio.currentTime = 0; var p = audio.play(); if (p && p.catch) p.catch(function(){}); return; }
    siguiente();
    if (cola[indice] && audio.paused && audio.src) { var q = audio.play(); if (q && q.catch) q.catch(function(){}); }
  });

  audio.addEventListener("error", function () {
    aviso("No se pudo reproducir el archivo|Revisa la ruta del MP3 en la base de datos", "error");
  });

  if (repBarra) repBarra.addEventListener("input", function () {
    pintarProgreso(repBarra);
    if (audio.duration) audio.currentTime = (repBarra.value / 100) * audio.duration;
  });

  if (repVolumen) {
    audio.volume = 0.8;
    repVolumen.addEventListener("input", function () {
      audio.volume = repVolumen.value / 100;
      audio.muted = false;
      if (btnVolumen) btnVolumen.classList.remove("activo");
      pintarProgreso(repVolumen);
    });
  }

  /* ---------- eventos de las filas y tarjetas ---------- */
  document.addEventListener("click", function (ev) {
    var btn = ev.target.closest ? ev.target.closest(".js-play") : null;
    if (btn) {
      var fila = btn.closest("tr.pista");
      if (!fila) return;
      var filas = leerFilas();
      var i = filas.indexOf(fila);
      construirCola(filas, i < 0 ? 0 : i);
      cargar(i < 0 ? 0 : i, true);
      return;
    }

    var add = ev.target.closest ? ev.target.closest(".js-cola") : null;
    if (add) {
      var f2 = add.closest("tr.pista");
      if (f2) {
        cola.push(filaACancion(f2));
        actualizarCola();
        aviso("Añadida a la cola|" + f2.getAttribute("data-titulo"));
      }
      return;
    }

    var todo = ev.target.closest ? ev.target.closest(".js-play-todo") : null;
    if (todo) {
      var fs = leerFilas();
      if (!fs.length) { aviso("No hay canciones en la lista", "error"); return; }
      if (aleatorio) { construirCola(fs, 0); cargar(Math.floor(Math.random() * fs.length), true); }
      else { construirCola(fs, 0); cargar(0, true); }
      return;
    }
  });

  var btnAzar = $("btnAleatorioTodo");
  if (btnAzar) btnAzar.addEventListener("click", function () {
    var fs = leerFilas();
    if (!fs.length) { aviso("No hay canciones en la lista", "error"); return; }
    construirCola(fs, Math.floor(Math.random() * fs.length));
    cargar(indice, true);
  });

  /* ---------- tema claro / oscuro ---------- */
  var btnTema = $("btnTema");
  if (btnTema) btnTema.addEventListener("click", function () {
    var actual = document.documentElement.getAttribute("data-tema");
    var nuevo = actual === "claro" ? "oscuro" : "claro";
    document.documentElement.setAttribute("data-tema", nuevo);
    try { localStorage.setItem("pm_tema", nuevo); } catch (e) {}
    aviso(nuevo === "claro" ? "Tema claro activado" : "Tema oscuro activado");
  });

  /* ---------- mensajes flash de la aplicación ---------- */
  Array.prototype.forEach.call(document.querySelectorAll(".toast"), function (t) {
    var cerrar = t.querySelector(".toast__close");
    if (cerrar) cerrar.addEventListener("click", function () {
      t.classList.add("saliendo");
      setTimeout(function () { t.remove(); }, 200);
    });
    setTimeout(function () { t.classList.add("saliendo"); }, 5000);
    setTimeout(function () { if (t.parentNode) t.remove(); }, 5300);
  });

  /* ---------- búsqueda por teclado en la tabla ---------- */
  var buscador = $("buscador");
  if (buscador) {
    buscador.addEventListener("keydown", function (e) {
      if (e.key === "Enter") { e.preventDefault(); buscador.closest("form").submit(); }
    });
  }

  /* ---------- atajos de teclado ---------- */
  document.addEventListener("keydown", function (e) {
    var etiqueta = (e.target.tagName || "").toLowerCase();
    if (etiqueta === "input" || etiqueta === "select" || etiqueta === "textarea") return;
    if (e.code === "Space") { e.preventDefault(); alternarPlay(); }
    else if (e.key === "ArrowRight" && e.shiftKey) { siguiente(); }
    else if (e.key === "ArrowLeft" && e.shiftKey) { anterior(); }
  });

  pintarProgreso(repVolumen);
  actualizarIconos();
})();
