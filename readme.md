Minimap Maker

This proof of concept was created as an experiment to emulate the map navigation from Eitrian Odyssey and similar map-focused, dungeon-exploration games. The WASD and QE keys are used for moving and turning.

![movement demo](https://github.com/ipatterson/minimap-maker/blob/main/demo.gif)

Dev-related features include adding and removing different map tiles as well as reading and writing to a JSON file.

![tile placement demo](https://github.com/ipatterson/minimap-maker/blob/main/tiles.gif)

Building the executable requires Godot 4.6. Presets for Windows and Mac exports configured.

See `data/map.json` for an example of the file. When used as an executable, the file is saved in the default ![data path[(https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html):


Windows: `%APPDATA%\Godot\app_userdata\[project_name]`
macOS: `~/Library/Application Support/Godot/app_userdata/[project_name]`
Linux: `~/.local/share/godot/app_userdata/[project_name]`

Dev Roadmap
- Export map.json to user-defined location

Credits
Font: 16bfZX by petrnita (Public Domain) - https://www.pentacom.jp/pentacom/bitfontmaker2/gallery/?id=246
UI Images by Kenney-nl (CC0 1.0 Universal) - https://kenney.nl/
