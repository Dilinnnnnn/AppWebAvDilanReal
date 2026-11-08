/* ============================================
   Song.js - Audio player for Song.aspx
   SquareSpace Lexington inspired
   Dilan Real - PoliMusic V3
   ============================================ */

(function () {
    'use strict';

    var currentAudio = null;
    var currentButton = null;

    function formatTime(seconds) {
        if (isNaN(seconds)) return '0:00';
        var min = Math.floor(seconds / 60);
        var sec = Math.floor(seconds % 60);
        return min + ':' + (sec < 10 ? '0' + sec : sec);
    }

    function pauseCurrent() {
        if (currentAudio) {
            currentAudio.pause();
            currentAudio.currentTime = 0;
            currentAudio = null;
        }
        if (currentButton) {
            currentButton.classList.remove('playing');
            currentButton.innerHTML = playIcon();
            currentButton = null;
        }
        // reset all progress bars
        var fills = document.querySelectorAll('.song-inline-player-fill');
        for (var i = 0; i < fills.length; i++) {
            fills[i].style.width = '0%';
        }
        var times = document.querySelectorAll('.song-inline-player-time');
        for (var j = 0; j < times.length; j++) {
            times[j].textContent = '0:00';
        }
    }

    function playIcon() {
        return '<svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>';
    }

    function pauseIcon() {
        return '<svg viewBox="0 0 24 24"><path d="M6 4h4v16H6zM14 4h4v16h-4z"/></svg>';
    }

    function togglePlay(button, audioUrl, songId) {
        // If clicking the same button that's playing, pause it
        if (currentButton === button) {
            pauseCurrent();
            return;
        }

        // Pause whatever was playing before
        pauseCurrent();

        // Create new audio element
        currentAudio = new Audio(audioUrl);
        currentButton = button;

        currentAudio.play().then(function () {
            button.classList.add('playing');
            button.innerHTML = pauseIcon();
        }).catch(function (err) {
            console.log('Playback error:', err);
        });

        var row = button.closest('.song-inline-player');
        if (!row) return;

        var fill = row.querySelector('.song-inline-player-fill');
        var timeDisplay = row.querySelector('.song-inline-player-time');
        var track = row.querySelector('.song-inline-player-track');

        currentAudio.addEventListener('timeupdate', function () {
            if (currentAudio && currentAudio.duration) {
                var pct = (currentAudio.currentTime / currentAudio.duration) * 100;
                fill.style.width = pct + '%';
                timeDisplay.textContent = formatTime(currentAudio.currentTime) + ' / ' + formatTime(currentAudio.duration);
            }
        });

        currentAudio.addEventListener('ended', function () {
            pauseCurrent();
        });

        // seek on track click
        if (track) {
            track.onclick = function (e) {
                if (!currentAudio || !currentAudio.duration) return;
                var rect = track.getBoundingClientRect();
                var pct = (e.clientX - rect.left) / rect.width;
                currentAudio.currentTime = pct * currentAudio.duration;
            };
        }

        // increment plays via AJAX
        incrementPlays(songId);
    }

    function incrementPlays(songId) {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'SongPlayHandler.ashx?id=' + songId, true);
        xhr.onreadystatechange = function () {
            if (xhr.readyState === 4 && xhr.status === 200) {
                try {
                    var resp = JSON.parse(xhr.responseText);
                    var playsElement = document.getElementById('plays-' + songId);
                    if (playsElement && resp.plays !== undefined) {
                        playsElement.textContent = resp.plays + ' reproducciones';
                    }
                } catch (e) {
                    // ignore JSON parse errors
                }
            }
        };
        xhr.send();
    }

    // Initialize after DOM is ready
    function init() {
        var playButtons = document.querySelectorAll('.song-inline-player-btn');
        for (var i = 0; i < playButtons.length; i++) {
            (function (btn) {
                var audioUrl = btn.getAttribute('data-audio-url');
                var songId = btn.getAttribute('data-song-id');
                if (audioUrl && songId) {
                    btn.addEventListener('click', function () {
                        togglePlay(btn, audioUrl, songId);
                    });
                }
            })(playButtons[i]);
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
