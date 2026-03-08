"""FastAPI application with WebSocket endpoint for Risk game."""

import json
from pathlib import Path

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse

from risk.engine.map_graph import MapGraph, load_map
from risk.server.game_manager import GameManager

app = FastAPI(title="Risk Game")

# Mount static files if directory exists
_static_dir = Path(__file__).resolve().parent.parent / "static"
if _static_dir.is_dir():
    from fastapi.staticfiles import StaticFiles
    app.mount("/static", StaticFiles(directory=str(_static_dir)), name="static")

# Map data path
_map_path = Path(__file__).resolve().parent.parent / "data" / "classic.json"


@app.get("/")
async def root() -> HTMLResponse:
    """Serve the game page, or a placeholder if static files don't exist yet."""
    index_path = _static_dir / "index.html"
    if index_path.is_file():
        return HTMLResponse(content=index_path.read_text())
    return HTMLResponse(
        content="<html><body><h1>Risk Game</h1>"
        "<p>Frontend not yet built. Connect via WebSocket at /ws</p>"
        "</body></html>"
    )


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket) -> None:
    """WebSocket endpoint for game communication."""
    await websocket.accept()

    manager = GameManager()
    map_data = load_map(_map_path)
    map_graph = MapGraph(map_data)

    async def send_message(msg: dict) -> None:
        """Send a JSON message to the client."""
        await websocket.send_json(msg)

    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")

            if msg_type == "start_game":
                num_players = data.get("num_players", 4)
                manager.setup(
                    num_players=num_players,
                    map_graph=map_graph,
                    send_callback=lambda msg: _schedule_send(websocket, msg),
                )
                manager.start_game()

            elif msg_type == "player_action":
                manager.handle_player_action(data)

    except WebSocketDisconnect:
        manager.cancel_game()


def _schedule_send(websocket: WebSocket, msg: dict) -> None:
    """Schedule an async send from a sync context (game thread).

    This is called from the game thread, so we use the websocket's
    event loop to schedule the actual async send.
    """
    import asyncio
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            asyncio.run_coroutine_threadsafe(
                websocket.send_json(msg), loop
            )
        else:
            loop.run_until_complete(websocket.send_json(msg))
    except RuntimeError:
        pass  # Connection closed
