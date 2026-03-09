/* app.js -- Main application controller for Risk game client. */
"use strict";

// --- State management ---
let gameState = null;
let currentInputType = null;
let selectedSource = null;
let validSources = [];
let validTargets = [];
let ws = null;

// Reinforcement tracking
let reinforcementsRemaining = 0;
let reinforcementPlacements = {};

const PLAYER_COLORS = ['#e74c3c', '#3498db', '#2ecc71', '#f1c40f', '#9b59b6', '#e67e22'];
const PLAYER_NAMES = ['You', 'Bot 1', 'Bot 2', 'Bot 3', 'Bot 4', 'Bot 5'];
const PHASE_NAMES = {1: 'Reinforce', 2: 'Attack', 3: 'Fortify'};

// Adjacency data loaded from server for client-side target computation
let adjacencyMap = {};

// Message queue for messages received before map is loaded
let mapReady = false;
let messageQueue = [];

// --- DOM references ---
const setupScreen = document.getElementById('setup-screen');
const gameBoard = document.getElementById('game-board');
const startBtn = document.getElementById('start-btn');
const playerCountSelect = document.getElementById('player-count');
const difficultySelect = document.getElementById('difficulty');
const confirmReinforceBtn = document.getElementById('confirm-reinforce-btn');
const endAttackBtn = document.getElementById('end-attack-btn');
const skipFortifyBtn = document.getElementById('skip-fortify-btn');
const moveArmiesPrompt = document.getElementById('move-armies-prompt');
const moveArmiesInput = document.getElementById('move-armies-input');
const moveArmiesConfirm = document.getElementById('move-armies-confirm');
const moveArmiesText = document.getElementById('move-armies-text');

// --- Setup screen handler ---
startBtn.addEventListener('click', function() {
    const numPlayers = parseInt(playerCountSelect.value, 10);
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    ws = new WebSocket(protocol + '//' + window.location.host + '/ws');

    ws.onopen = function() {
        // Reset map readiness for new game
        mapReady = false;
        messageQueue = [];
        mapLoaded = false;

        ws.send(JSON.stringify({type: 'start_game', num_players: numPlayers, difficulty: difficultySelect.value}));
        setupScreen.style.display = 'none';
        gameBoard.style.display = 'flex';

        // Load adjacency data and SVG map, then flush queued messages
        var adjacencyLoaded = fetch('/api/map-data')
            .then(function(r) { return r.json(); })
            .then(function(data) { buildAdjacencyMap(data); });

        var mapDone = loadMap();

        Promise.all([mapDone, adjacencyLoaded]).then(function() {
            flushMessageQueue();
        });
    };

    ws.onmessage = handleMessage;

    ws.onclose = function() {
        // Connection closed
    };
});

// --- Build adjacency lookup from map data ---
function buildAdjacencyMap(mapData) {
    adjacencyMap = {};
    if (!mapData || !mapData.adjacencies) return;
    mapData.adjacencies.forEach(function(pair) {
        var a = pair[0], b = pair[1];
        if (!adjacencyMap[a]) adjacencyMap[a] = [];
        if (!adjacencyMap[b]) adjacencyMap[b] = [];
        adjacencyMap[a].push(b);
        adjacencyMap[b].push(a);
    });
}

// --- WebSocket message handler ---
function handleMessage(event) {
    var msg = JSON.parse(event.data);

    // Queue messages until the SVG map is loaded and ready
    if (!mapReady) {
        messageQueue.push(msg);
        return;
    }

    processMessage(msg);
}

function processMessage(msg) {
    switch (msg.type) {
        case 'game_state':
            gameState = msg.state;
            updateMap(msg.state);
            updateSidebar(msg.state, msg.continent_info);
            if (msg.prompt) {
                showBanner(msg.prompt);
            } else {
                hideBanner();
            }
            break;

        case 'request_input':
            currentInputType = msg.input_type;
            validSources = msg.valid_sources || [];
            validTargets = msg.valid_targets || [];
            enableInputMode(msg);
            break;

        case 'game_event':
            appendGameLog(msg);
            break;

        case 'game_over':
            showGameOver(msg);
            break;
    }
}

function flushMessageQueue() {
    mapReady = true;
    var queued = messageQueue.slice();
    messageQueue = [];
    queued.forEach(function(msg) {
        processMessage(msg);
    });
}

// --- Action sending ---
function sendAction(actionType, data) {
    if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
            type: 'player_action',
            action_type: actionType,
            data: data
        }));
    }
}

// --- Input modes ---
function enableInputMode(msg) {
    clearHighlights();
    selectedSource = null;

    // Hide action buttons by default
    confirmReinforceBtn.style.display = 'none';
    endAttackBtn.style.display = 'none';
    skipFortifyBtn.style.display = 'none';

    switch (msg.input_type) {
        case 'choose_reinforcement_placement':
            reinforcementsRemaining = msg.armies || 0;
            reinforcementPlacements = {};
            renderArmyLabels({});
            showBanner('Place ' + reinforcementsRemaining + ' reinforcements - click your territories');
            highlightValidSources(msg.valid_sources || getOwnedTerritories());
            updateActionButtons('choose_reinforcement_placement');
            break;

        case 'choose_attack':
            highlightValidSources(validSources);
            endAttackBtn.style.display = 'block';
            updateActionButtons('choose_attack');
            break;

        case 'choose_fortify':
            highlightValidSources(validSources);
            skipFortifyBtn.style.display = 'block';
            updateActionButtons('choose_fortify');
            break;

        case 'choose_card_trade':
            showCardTradePanel(msg.cards || [], msg.forced || false);
            break;

        case 'choose_defender_dice':
            // Auto-defend with max dice (per project decisions)
            sendAction('defend', {dice: msg.max_dice || 2});
            break;

        case 'choose_blitz':
            // Human does not use blitz per project decisions
            sendAction('no_blitz', {});
            break;

        case 'choose_advance_armies': {
            var minArmies = msg.armies || 1;
            var maxArmies = msg.max_armies || minArmies;
            var source = (msg.valid_sources && msg.valid_sources[0]) || '';
            var target = (msg.valid_targets && msg.valid_targets[0]) || '';
            moveArmiesText.textContent = 'Advance armies from ' + source + ' into ' + target +
                ' (min: ' + minArmies + ')';
            moveArmiesInput.min = minArmies;
            moveArmiesInput.max = maxArmies;
            moveArmiesInput.value = minArmies;
            moveArmiesPrompt.style.display = 'block';

            var newConfirm = moveArmiesConfirm.cloneNode(true);
            moveArmiesConfirm.parentNode.replaceChild(newConfirm, moveArmiesConfirm);

            newConfirm.addEventListener('click', function() {
                var count = parseInt(moveArmiesInput.value, 10);
                if (count < minArmies) count = minArmies;
                if (count > maxArmies) count = maxArmies;
                sendAction('advance_armies', { armies: count });
                moveArmiesPrompt.style.display = 'none';
                currentInputType = null;
            });
            break;
        }
    }
}

// --- Get owned territories (player 0 = human) ---
function getOwnedTerritories() {
    if (!gameState || !gameState.territories) return [];
    var owned = [];
    var territories = gameState.territories;
    for (var name in territories) {
        if (territories[name].owner === 0) {
            owned.push(name);
        }
    }
    return owned;
}

// --- Territory click handler (called from map.js) ---
function handleTerritoryClick(territoryName) {
    if (!currentInputType || !gameState) return;

    switch (currentInputType) {
        case 'choose_reinforcement_placement':
            handleReinforcementClick(territoryName);
            break;

        case 'choose_attack':
            handleAttackClick(territoryName);
            break;

        case 'choose_fortify':
            handleFortifyClick(territoryName);
            break;
    }
}

// --- Reinforcement click handler ---
function handleReinforcementClick(territoryName) {
    var territories = gameState.territories;
    if (!territories[territoryName] || territories[territoryName].owner !== 0) return;

    if (reinforcementsRemaining <= 0) return;

    // Show move armies modal for how many to place
    moveArmiesText.textContent = 'Place armies in ' + territoryName + ' (' + reinforcementsRemaining + ' remaining)';
    moveArmiesInput.min = 1;
    moveArmiesInput.max = reinforcementsRemaining;
    moveArmiesInput.value = 1;
    moveArmiesPrompt.style.display = 'block';

    // Remove previous listener if any
    var newConfirm = moveArmiesConfirm.cloneNode(true);
    moveArmiesConfirm.parentNode.replaceChild(newConfirm, moveArmiesConfirm);

    newConfirm.addEventListener('click', function() {
        var count = parseInt(moveArmiesInput.value, 10);
        if (count < 1) count = 1;
        if (count > reinforcementsRemaining) count = reinforcementsRemaining;

        if (!reinforcementPlacements[territoryName]) {
            reinforcementPlacements[territoryName] = 0;
        }
        reinforcementPlacements[territoryName] += count;
        reinforcementsRemaining -= count;

        moveArmiesPrompt.style.display = 'none';

        renderArmyLabels(reinforcementPlacements);

        if (reinforcementsRemaining <= 0) {
            // All placed — show confirm button instead of auto-sending
            showBanner('All reinforcements placed. Confirm to proceed to Attack phase.');
            confirmReinforceBtn.style.display = 'block';
        } else {
            showBanner('Place ' + reinforcementsRemaining + ' reinforcements - click your territories');
            confirmReinforceBtn.style.display = 'none';
        }
    });

    // Reassign reference
    document.getElementById('move-armies-confirm');
}

// --- Attack click handler ---
function handleAttackClick(territoryName) {
    if (!selectedSource) {
        // First click: select source
        if (validSources.indexOf(territoryName) === -1) return;
        selectedSource = territoryName;

        // Compute valid attack targets client-side
        var attackTargets = getValidAttackTargets(selectedSource, gameState);
        highlightValidTargets(selectedSource, attackTargets);
    } else {
        // Second click: select target
        var targets = getValidAttackTargets(selectedSource, gameState);
        if (targets.indexOf(territoryName) === -1) {
            // Invalid target -- deselect and restart
            selectedSource = null;
            clearHighlights();
            highlightValidSources(validSources);
            return;
        }

        // Get dice count from radio buttons
        var diceRadios = document.getElementsByName('attack-dice');
        var attackDice = 3;
        for (var i = 0; i < diceRadios.length; i++) {
            if (diceRadios[i].checked) {
                attackDice = parseInt(diceRadios[i].value, 10);
                break;
            }
        }

        // Limit dice to source armies - 1
        var sourceArmies = gameState.territories[selectedSource].armies;
        if (attackDice > sourceArmies - 1) {
            attackDice = sourceArmies - 1;
        }
        if (attackDice < 1) attackDice = 1;

        sendAction('attack', {
            source: selectedSource,
            target: territoryName,
            dice: attackDice
        });

        selectedSource = null;
        clearHighlights();
        // Don't re-highlight -- server will send new request_input if more attacks available
    }
}

// --- Fortify click handler ---
function handleFortifyClick(territoryName) {
    if (!selectedSource) {
        // First click: select source
        if (validSources.indexOf(territoryName) === -1) return;
        selectedSource = territoryName;

        var fortifyTargets = getValidFortifyTargets(selectedSource, gameState);
        highlightValidTargets(selectedSource, fortifyTargets);
    } else {
        // Second click: select target
        var targets = getValidFortifyTargets(selectedSource, gameState);
        if (targets.indexOf(territoryName) === -1) {
            selectedSource = null;
            clearHighlights();
            highlightValidSources(validSources);
            return;
        }

        // Show move armies modal
        var maxArmies = gameState.territories[selectedSource].armies - 1;
        moveArmiesText.textContent = 'Move armies from ' + selectedSource + ' to ' + territoryName;
        moveArmiesInput.min = 1;
        moveArmiesInput.max = maxArmies;
        moveArmiesInput.value = 1;
        moveArmiesPrompt.style.display = 'block';

        var targetName = territoryName;
        var sourceName = selectedSource;

        var newConfirm = moveArmiesConfirm.cloneNode(true);
        moveArmiesConfirm.parentNode.replaceChild(newConfirm, moveArmiesConfirm);

        newConfirm.addEventListener('click', function() {
            var count = parseInt(moveArmiesInput.value, 10);
            if (count < 1) count = 1;
            if (count > maxArmies) count = maxArmies;

            sendAction('fortify', {
                source: sourceName,
                target: targetName,
                armies: count
            });

            moveArmiesPrompt.style.display = 'none';
            selectedSource = null;
            currentInputType = null;
            clearHighlights();
        });
    }
}

// --- Card trade panel ---
function showCardTradePanel(cards, forced) {
    var panel = document.getElementById('card-trade-panel');
    var cardHand = document.getElementById('card-hand');
    var tradeBtn = document.getElementById('trade-cards-btn');
    var skipBtn = document.getElementById('skip-trade-btn');

    cardHand.innerHTML = '';
    var selectedCards = [];

    if (forced) {
        skipBtn.style.display = 'none';
    } else {
        skipBtn.style.display = 'inline-block';
    }

    cards.forEach(function(card, idx) {
        var el = document.createElement('div');
        el.className = 'card-item';
        el.textContent = card.type || card.card_type || 'Card';
        el.dataset.index = idx;

        el.addEventListener('click', function() {
            var cardIdx = parseInt(el.dataset.index, 10);
            var pos = selectedCards.indexOf(cardIdx);
            if (pos >= 0) {
                selectedCards.splice(pos, 1);
                el.classList.remove('selected');
            } else if (selectedCards.length < 3) {
                selectedCards.push(cardIdx);
                el.classList.add('selected');
            }
            tradeBtn.textContent = 'Trade Selected (' + selectedCards.length + '/3)';
            tradeBtn.disabled = selectedCards.length !== 3;
        });

        cardHand.appendChild(el);
    });

    tradeBtn.disabled = true;
    tradeBtn.textContent = 'Trade Selected (0/3)';
    panel.style.display = 'block';

    // Remove previous listeners
    var newTradeBtn = tradeBtn.cloneNode(true);
    tradeBtn.parentNode.replaceChild(newTradeBtn, tradeBtn);
    var newSkipBtn = skipBtn.cloneNode(true);
    skipBtn.parentNode.replaceChild(newSkipBtn, skipBtn);

    newTradeBtn.addEventListener('click', function() {
        if (selectedCards.length === 3) {
            var tradedCards = selectedCards.map(function(i) { return cards[i]; });
            sendAction('card_trade', {cards: tradedCards});
            panel.style.display = 'none';
            currentInputType = null;
        }
    });

    newSkipBtn.addEventListener('click', function() {
        sendAction('end_phase', {});
        panel.style.display = 'none';
        currentInputType = null;
    });
}

// --- Action button handlers ---
endAttackBtn.addEventListener('click', function() {
    sendAction('end_phase', {});
    currentInputType = null;
    selectedSource = null;
    clearHighlights();
    endAttackBtn.style.display = 'none';
});

skipFortifyBtn.addEventListener('click', function() {
    sendAction('end_phase', {});
    currentInputType = null;
    selectedSource = null;
    clearHighlights();
    skipFortifyBtn.style.display = 'none';
});

confirmReinforceBtn.addEventListener('click', function() {
    renderArmyLabels({});
    sendAction('reinforce', {placements: reinforcementPlacements});
    currentInputType = null;
    clearHighlights();
    hideBanner();
    confirmReinforceBtn.style.display = 'none';
});

// --- Game over ---
function showGameOver(msg) {
    var overlay = document.getElementById('game-over');
    var message = document.getElementById('game-over-message');
    var newGameBtn = document.getElementById('new-game-btn');

    if (msg.is_human_winner) {
        message.textContent = 'Victory! You win!';
    } else {
        message.textContent = 'Defeat! ' + msg.winner_name + ' wins.';
    }

    overlay.style.display = 'block';
    currentInputType = null;
    clearHighlights();

    var newBtn = newGameBtn.cloneNode(true);
    newGameBtn.parentNode.replaceChild(newBtn, newGameBtn);
    newBtn.addEventListener('click', function() {
        if (ws) ws.close();
        ws = null;
        gameState = null;
        currentInputType = null;
        selectedSource = null;
        validSources = [];
        validTargets = [];
        reinforcementsRemaining = 0;
        reinforcementPlacements = {};
        mapReady = false;
        messageQueue = [];

        overlay.style.display = 'none';
        gameBoard.style.display = 'none';
        setupScreen.style.display = 'flex';
    });
}
