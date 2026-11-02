/* ============================================================
   PoliMusic - custom audio player for Song.aspx
   One player per row, only one song can sound at a time.
   ============================================================ */

(function () {
    "use strict";

    var players = Array.prototype.slice.call(document.querySelectorAll(".player"));
    var playsUrl = document.body.getAttribute("data-plays-url");

    if (!players.length) {
        return;
    }

    function formatTime(seconds) {
        if (!isFinite(seconds) || isNaN(seconds) || seconds < 0) {
            seconds = 0;
        }
        var total = Math.floor(seconds);
        var min = Math.floor(total / 60);
        var sec = total % 60;
        return min + ":" + (sec < 10 ? "0" + sec : sec);
    }

    function pauseOthers(current) {
        players.forEach(function (other) {
            if (other !== current && other.audio && !other.audio.paused) {
                other.audio.pause();
            }
        });
    }

    /* Asks the server to add one play to the counter of this song. */
    function registerPlay(player) {
        if (player.counted || !playsUrl) {
            return;
        }
        player.counted = true;

        var id = player.getAttribute("data-song-id");
        if (!id) {
            return;
        }

        fetch(playsUrl + "?id=" + encodeURIComponent(id), { credentials: "same-origin" })
            .then(function (response) {
                return response.ok ? response.json() : null;
            })
            .then(function (data) {
                if (!data || typeof data.plays !== "number" || !player.row) {
                    return;
                }
                var cell = player.row.querySelector("[data-plays]");
                if (cell) {
                    cell.textContent = data.plays;
                }
            })
            .catch(function () {
                /* the counter is not critical, ignore network errors */
            });
    }

    players.forEach(function (player) {
        var audio = player.querySelector("audio");
        var playBtn = player.querySelector("[data-play]");
        var progress = player.querySelector("[data-progress]");
        var fill = player.querySelector("[data-fill]");
        var timeLabel = player.querySelector("[data-time]");
        var muteBtn = player.querySelector("[data-mute]");
        var volume = player.querySelector("[data-vol]");

        if (!audio || !playBtn || !progress || !fill || !timeLabel) {
            return;
        }

        player.audio = audio;
        player.row = player.closest ? player.closest("tr") : null;

        function render() {
            var duration = audio.duration;
            var percent = 0;

            if (isFinite(duration) && duration > 0) {
                percent = (audio.currentTime / duration) * 100;
            }
            fill.style.width = percent + "%";
            timeLabel.textContent = formatTime(audio.currentTime) + " / " + formatTime(duration);
        }

        playBtn.addEventListener("click", function () {
            if (audio.paused) {
                pauseOthers(player);
                var promise = audio.play();
                if (promise && typeof promise.catch === "function") {
                    promise.catch(function () {
                        /* file missing or not supported: keep the UI quiet */
                    });
                }
            } else {
                audio.pause();
            }
        });

        audio.addEventListener("play", function () {
            if (player.row) {
                player.row.classList.add("is-playing");
            }
            registerPlay(player);
        });

        audio.addEventListener("pause", function () {
            if (player.row) {
                player.row.classList.remove("is-playing");
            }
        });

        audio.addEventListener("loadedmetadata", render);
        audio.addEventListener("timeupdate", render);

        audio.addEventListener("ended", function () {
            if (player.row) {
                player.row.classList.remove("is-playing");
            }
            audio.currentTime = 0;
            player.counted = false;
            render();
        });

        progress.addEventListener("click", function (event) {
            if (!isFinite(audio.duration) || audio.duration <= 0) {
                return;
            }
            var rect = progress.getBoundingClientRect();
            var ratio = (event.clientX - rect.left) / rect.width;
            ratio = Math.max(0, Math.min(1, ratio));
            audio.currentTime = ratio * audio.duration;
            render();
        });

        if (muteBtn) {
            muteBtn.addEventListener("click", function () {
                audio.muted = !audio.muted;
                muteBtn.classList.toggle("is-muted", audio.muted);
                if (volume) {
                    volume.value = audio.muted ? 0 : Math.round(audio.volume * 100);
                }
            });
        }

        if (volume) {
            volume.addEventListener("input", function () {
                audio.volume = Number(volume.value) / 100;
                audio.muted = audio.volume === 0;
                if (muteBtn) {
                    muteBtn.classList.toggle("is-muted", audio.muted);
                }
            });
        }

        render();
    });
})();
