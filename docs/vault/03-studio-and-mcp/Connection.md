# Studio MCP connection

Studio's MCP server is built in. The mezzanine bar (Home, Model, Avatar, UI, Script, Plugins) and the Assistant button only exist once a place is open, not on the start screen.

1. Open a place (New, then Baseplate is fine).
2. Click the **Assistant** button: the purple atom icon at the top right of the mezzanine bar, between Share and the bell (`img/Toolbar-Assistant.png`).
3. In the Assistant panel, click the **three dots** at the bottom right of the text box (`img/Studio-General-UI.png`), then **Settings** or **Manage MCP Servers**.
4. Pick **MCP Servers** on the left and turn on **Enable Studio as MCP server** (`img/MCP.png`). Expand **Quick connect** and toggle **Claude Code**; or copy the **Startup Command (for CLI tools)** and run `claude mcp add --transport stdio Roblox_Studio -- <that command>`.
5. Restart Studio and Claude Code. The page shows a green dot with the number of connected clients.

Screenshots are from Roblox's creator-docs repository (CC BY 4.0).

Mac server path: `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`. The repo's `.mcp.json` points Claude Code at it. Windows: `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`.

Tools worth knowing: `script_read`, `multi_edit`, `script_grep`, `search_game_tree`, `inspect_instance`, `execute_luau` (Edit, Client or Server), `start_stop_play`, `get_console_output`, `screen_capture`, `user_keyboard_input`, `user_mouse_input`, `generate_mesh`, `generate_material`, `generate_procedural_model`, `search_asset`, `insert_asset`, `list_roblox_studios`. Every call takes a `studio_id`.

Division of labour: Rojo carries code and data tables from the repo; MCP is for live instance edits, UI trees, running installers, playtesting and screenshots.
