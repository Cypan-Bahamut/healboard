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

## Support

First and foremost: Please support the original author if this is an addon modification. 
If you enjoy the addon and you'd like to buy me a coffee, it's appreciated but never expected:

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-cypan-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/cypan)

Bug reports and pull requests are worth more than donations, so open an issue if something's broken please.
