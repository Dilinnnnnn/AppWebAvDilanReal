/* =====================================================================
   PoliMusic  ·  assets/js/login.js
   Script exclusivo de la pantalla de inicio de sesión:
   - Rellena el formulario al pulsar una cuenta de demostración
   - Muestra un estado de carga al enviar
   - Mensaje al cerrar sesión (llega por ?msg=salida)
   ===================================================================== */
(function () {
  "use strict";

  var form = document.getElementById("formLogin");
  var usuario = document.getElementById("usuario");
  var clave = document.getElementById("clave");
  var btnEntrar = document.getElementById("btnEntrar");

  function aviso(texto) {
    var zona = document.createElement("div");
    zona.className = "zona-mensajes";
    var div = document.createElement("div");
    div.className = "toast";
    div.innerHTML = '<span class="toast__icon">✓</span>' +
                    '<span class="toast__body"><strong></strong></span>' +
                    '<button type="button" class="toast__close" aria-label="Cerrar">×</button>';
    div.querySelector("strong").textContent = texto;
    div.querySelector(".toast__close").addEventListener("click", function () {
      div.classList.add("saliendo");
      setTimeout(function () { zona.remove(); }, 200);
    });
    zona.appendChild(div);
    document.body.appendChild(zona);
    setTimeout(function () { div.classList.add("saliendo"); }, 4200);
    setTimeout(function () { if (zona.parentNode) zona.remove(); }, 4500);
  }

  // Cuentas de demostración: rellenan usuario y contraseña
  Array.prototype.forEach.call(document.querySelectorAll(".cuenta"), function (cuenta) {
    cuenta.addEventListener("click", function () {
      usuario.value = cuenta.getAttribute("data-usuario");
      clave.value = cuenta.getAttribute("data-clave");
      if (form && form.reportValidity) form.reportValidity();
      btnEntrar.focus();
    });
  });

  // Estado de envío
  if (form) {
    form.addEventListener("submit", function (e) {
      if (form.reportValidity && !form.reportValidity()) return;
      btnEntrar.disabled = true;
      btnEntrar.textContent = "Verificando...";
    });
  }

  // Aviso procedente del cierre de sesión
  var params = new URLSearchParams(window.location.search);
  if (params.get("msg") === "salida") {
    aviso("Sesión cerrada correctamente. ¡Vuelve pronto!");
  }

  usuario.focus();
})();
