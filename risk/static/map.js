/* map.js -- SVG map rendering and interaction for Risk game client. */
"use strict";

var mapLoaded = false;

// --- Load SVG map into container ---
function loadMap() {
    if (mapLoaded) return Promise.resolve();

    return fetch('/api/map')
        .then(function(response) { return response.text(); })
        .then(function(svgText) {
            var container = document.getElementById('map-container');
            container.innerHTML = svgText;
            mapLoaded = true;

            // Attach click handlers to all territory elements
            var territories = container.querySelectorAll('[data-territory]');
            territories.forEach(function(el) {
                el.addEventListener('click', function() {
                    var name = el.getAttribute('data-territory');
                    handleTerritoryClick(name);
                });
            });
        });
}

// --- Update map from game state ---
function updateMap(state) {
    if (!state || !state.territories) return;

    var container = document.getElementById('map-container');
    var territories = state.territories;

    for (var name in territories) {
        var info = territories[name];

        // Update territory fill color based on owner
        var el = container.querySelector('[data-territory="' + name + '"]');
        if (el) {
            el.style.fill = PLAYER_COLORS[info.owner];
        }

        // Update army label
        var label = container.querySelector('[data-army-label="' + name + '"]');
        if (label) {
            label.textContent = info.armies;
        }
    }
}

// --- Highlight valid source territories ---
function highlightValidSources(sources) {
    clearHighlights();
    var container = document.getElementById('map-container');
    var all = container.querySelectorAll('[data-territory]');

    all.forEach(function(el) {
        var name = el.getAttribute('data-territory');
        if (sources.indexOf(name) >= 0) {
            el.classList.add('valid-source');
        } else {
            el.classList.add('dimmed');
        }
    });
}

// --- Highlight valid target territories after source selection ---
function highlightValidTargets(source, targets) {
    clearHighlights();
    var container = document.getElementById('map-container');
    var all = container.querySelectorAll('[data-territory]');

    all.forEach(function(el) {
        var name = el.getAttribute('data-territory');
        if (name === source) {
            el.classList.add('selected');
        } else if (targets.indexOf(name) >= 0) {
            el.classList.add('valid-target');
        } else {
            el.classList.add('dimmed');
        }
    });
}

// --- Clear all highlight classes ---
function clearHighlights() {
    var container = document.getElementById('map-container');
    var all = container.querySelectorAll('[data-territory]');

    all.forEach(function(el) {
        el.classList.remove('selected', 'valid-source', 'valid-target', 'dimmed');
    });
}

// --- Client-side target computation for attacks ---
function getValidAttackTargets(source, state) {
    if (!state || !state.territories || !adjacencyMap[source]) return [];

    var sourceOwner = state.territories[source].owner;
    var targets = [];

    adjacencyMap[source].forEach(function(neighbor) {
        if (state.territories[neighbor] && state.territories[neighbor].owner !== sourceOwner) {
            targets.push(neighbor);
        }
    });

    return targets;
}

// --- Client-side target computation for fortify (adjacent friendly only) ---
function getValidFortifyTargets(source, state) {
    if (!state || !state.territories || !adjacencyMap[source]) return [];

    var sourceOwner = state.territories[source].owner;
    var targets = [];

    adjacencyMap[source].forEach(function(neighbor) {
        if (state.territories[neighbor] && state.territories[neighbor].owner === sourceOwner) {
            targets.push(neighbor);
        }
    });

    return targets;
}
