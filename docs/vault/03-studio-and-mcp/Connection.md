# Studio MCP connection

Studio's MCP server is built in. Enable: Assistant, three dots, Manage MCP Servers, "Enable Studio as MCP server". Connect: Quick connect, toggle Claude Code (and Claude Desktop). Restart both. Green indicator shows connected clients.

Mac server path: `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`. The repo's `.mcp.json` points Claude Code at it. Windows: `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`.

Tools worth knowing: `script_read`, `multi_edit`, `script_grep`, `search_game_tree`, `inspect_instance`, `execute_luau` (Edit, Client or Server), `start_stop_play`, `get_console_output`, `screen_capture`, `user_keyboard_input`, `user_mouse_input`, `generate_mesh`, `generate_material`, `generate_procedural_model`, `search_asset`, `insert_asset`, `list_roblox_studios`. Every call takes a `studio_id`.

Division of labour: Rojo carries code and data tables from the repo; MCP is for live instance edits, UI trees, running installers, playtesting and screenshots.
