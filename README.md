# Space Delivery Squad
 A Multiplayer Coop game about delivering packages with your friends through Space!
 <br>
 <br>

# Structure

## Flow
- Entry point is `Main.tscn`
- Host will spawn its' own levels and add them to the `SceneTree`
- Clients get their level's spawned through the `Autoload` `LevelManager` that has a `MultiplayerSpawner` `Node`
- The `Autoload` `Transition.tscn` fades to black and fades in when levels are switching

## Autoloads
- `LevelManager.tscn`
  - Responsible for spawning levels and removing previous levels through a `MultiplayerSpawner` (named `LevelSpawner`)
  - Listens for a `finished_level` `signal` attached to the level it spawns to determine when to switch levels
- `Transition.tscn`
  - Responisble for transitioning the screen to hide level cleanup and creation
  - Has a `TextureRect` which fades to black and fades in when levels are switching
- `AudioManager.tscn`
  - Responsible for music and sfx
  - Has 3 Buses:
	- Master
	- Music
	- SFX
  - Has an `AudioStreamPlayer` for music by default with no music attached
  - Unmutes the Audio Buses when exported
- `InteractionHandler.gd`
	- Responsible for authoritatively handling interactions between players
- `PlayerManager.gd`
	- Responsible for keeping track of Player information during gameplay
		- Player ID
		- Player Name
		- Node the Player is controlling

## Creating Levels
  - Add your level scenes to the `LevelStore` `Resource` file `res://resources/StandardLevels.tres`
  - The level being spawned should have a top level script that emits a `finished_level` `signal` when players finish a level
	- once this `signal` is emitted then it will proceed to the next level
  - You can create another `LevelStore` for levels you are testing and adjust the `level_store` variable in `LevelManager.gd`
	- Note: You can export the `level_store` variable for more of an editor workflow

## Debug Related Things
	- Sometimes you need to create scripts to mess with data that you don't want to commit
	- Create a "my_debug" folder and store everything in there as its already in the .gitignore

## Credits
- SFX from [Kenney](https://www.kenney.nl/)
- VOIP from [WIP] https://github.com/RevoluPowered/one-voip-godot-4
- Icons
	- O2 https://www.svgrepo.com/svg/139900/oxygen
	- Run https://www.svgrepo.com/svg/489113/run
	- Heart https://www.svgrepo.com/svg/525369/heart
