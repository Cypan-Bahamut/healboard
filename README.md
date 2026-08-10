# healboard

Modified version of scoreboard to parse healing done instead of damage.

Original scoreboard by Suji. Modified by Cypan (Bahamut).

## Commands

All commands use `//hd` (or `//healboard`):

| Command | Description |
|---------|-------------|
| `//hd help` | Shows the in-game help |
| `//hd visible` | Toggles the board display |
| `//hd reset` | Resets the parse |
| `//hd pos <x> <y>` | Positions the board |
| `//hd report [<target>]` | Reports healing to chat; accepts standard chatmode targets |
| `//hd reportstat <stat> [<player>] [<target>]` (or `rs`) | Reports a specific stat |
| `//hd stat <stat> [<player>]` | Shows specific healing stats (respects filters) |
| `//hd fields` | Lists valid stat fields |
| `//hd filter show \| add <mob...> \| clear` | Manage the mob filter (substrings ok) |
| `//hd set combinepets true\|false` | Merge pet totals into owners |
| `//hd set numplayers <n>` | Max players displayed |
| `//hd save` | Saves current settings |
