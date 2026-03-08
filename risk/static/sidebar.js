/* sidebar.js -- Sidebar rendering logic for Risk game client. */
"use strict";

// --- Update sidebar from game state ---
function updateSidebar(state, continentInfo) {
    if (!state) return;

    // Update turn info: current player name and color
    var playerIndex = state.current_player_index;
    var playerName = PLAYER_NAMES[playerIndex] || ('Player ' + (playerIndex + 1));
    var playerColor = PLAYER_COLORS[playerIndex] || '#888';

    var nameEl = document.getElementById('player-name');
    var colorEl = document.getElementById('player-color-indicator');
    var turnEl = document.getElementById('turn-number');

    if (nameEl) nameEl.textContent = playerName;
    if (colorEl) colorEl.style.background = playerColor;
    if (turnEl) turnEl.textContent = 'Turn ' + (state.turn_number || 1);

    // Update phase stepper
    var phaseValue = state.turn_phase;
    var steps = document.querySelectorAll('#phase-stepper .phase-step');
    var phaseMap = {reinforce: 1, attack: 2, fortify: 3};

    steps.forEach(function(step) {
        var stepPhase = phaseMap[step.getAttribute('data-phase')];
        step.classList.remove('active', 'completed');
        if (stepPhase === phaseValue) {
            step.classList.add('active');
        } else if (stepPhase < phaseValue) {
            step.classList.add('completed');
        }
    });

    // Update continent info
    updateContinentInfo(state, continentInfo);
}

// --- Update continent bonuses and territory counts ---
function updateContinentInfo(state, continentInfo) {
    if (!continentInfo || !state || !state.territories) return;

    continentInfo.forEach(function(continent) {
        var li = document.querySelector('[data-continent="' + continent.name + '"]');
        if (!li) return;

        var controlEl = li.querySelector('.continent-control');
        if (!controlEl) return;

        // Count how many territories in this continent the human (player 0) owns
        var ownedCount = 0;
        var totalCount = continent.territories.length;

        continent.territories.forEach(function(terrName) {
            if (state.territories[terrName] && state.territories[terrName].owner === 0) {
                ownedCount++;
            }
        });

        controlEl.textContent = ownedCount + '/' + totalCount;

        // Update bonus display in case it differs
        var bonusEl = li.querySelector('.continent-bonus');
        if (bonusEl) {
            bonusEl.textContent = '(+' + continent.bonus + ')';
        }
    });
}

// --- Show phase prompt banner ---
function showBanner(text) {
    var banner = document.getElementById('phase-banner');
    if (banner) {
        banner.textContent = text;
        banner.style.display = 'block';
    }
}

// --- Hide phase prompt banner ---
function hideBanner() {
    var banner = document.getElementById('phase-banner');
    if (banner) {
        banner.style.display = 'none';
    }
}

// --- Append entry to game log ---
function appendGameLog(eventMsg) {
    var gameLog = document.getElementById('game-log');
    if (!gameLog) return;

    var entry = document.createElement('div');
    entry.className = 'log-entry';

    var text = formatGameEvent(eventMsg.event, eventMsg.details || {});
    entry.textContent = text;

    gameLog.appendChild(entry);
    gameLog.scrollTop = gameLog.scrollHeight;
}

// --- Format game event into readable text ---
function formatGameEvent(event, details) {
    var playerName = function(idx) {
        if (idx === undefined || idx === null) return 'Unknown';
        return PLAYER_NAMES[idx] || ('Player ' + (idx + 1));
    };

    switch (event) {
        case 'attack':
            return playerName(details.attacker) + ' attacked ' + details.target +
                   ' from ' + details.source +
                   ' (dice: ' + (details.attack_dice || '?') + ' vs ' + (details.defend_dice || '?') +
                   ', lost: ' + (details.attacker_losses || 0) + ' att / ' + (details.defender_losses || 0) + ' def)';

        case 'conquest':
            // Server sends attacker/attacker_name, not player
            var conquererName = details.attacker_name || playerName(details.attacker);
            return conquererName + ' conquered ' + (details.territory || details.target) + '!';

        case 'card_trade':
            var traderName = details.player_name || playerName(details.player);
            return traderName + ' traded cards';

        case 'elimination':
            // Server sends eliminated_player/eliminated_name/by_player
            var eliminatorName = playerName(details.by_player);
            var eliminatedName = details.eliminated_name || playerName(details.eliminated_player);
            return eliminatorName + ' eliminated ' + eliminatedName + '!';

        case 'reinforcement':
            return playerName(details.player) + ' placed ' + (details.armies || '?') + ' reinforcement armies';

        default:
            return event + ': ' + JSON.stringify(details);
    }
}

// --- Update action buttons visibility ---
function updateActionButtons(inputType) {
    var endAttack = document.getElementById('end-attack-btn');
    var skipFortify = document.getElementById('skip-fortify-btn');

    if (endAttack) {
        endAttack.style.display = (inputType === 'choose_attack') ? 'block' : 'none';
    }
    if (skipFortify) {
        skipFortify.style.display = (inputType === 'choose_fortify') ? 'block' : 'none';
    }
}
