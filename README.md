# Space Delivery Squad
 A Multiplayer Coop game about delivering alive packages while maintaining a failing Ship with your friends, through Space!
 <br>
 <br>

# Structure

## Flow
- Entry point is `Main.tscn`
- Host will instantiate levels through the `LevelManager`
- Clients get their levels spawned through the `LevelManager` that has a `MultiplayerSpawner`
- `Autoload` `Transition.tscn` fades to black and fades in when levels are switching

## Autoloads
- `LevelManager.tscn`
  - Responsible for spawning levels and removing previous levels through a `MultiplayerSpawner` (named `LevelSpawner`)
  - Listens for a `finished_level` `signal` attached to the level it spawns to determine when to switch levels if it should
- `Transition.tscn`
  - Responisble for transitioning the screen to hide level cleanup and creation
  - Has a `TextureRect` which fades to black and fades in when levels are switching
- `AudioManager.tscn`
  - Responsible for music and sfx
  - Has 5 Buses:
	- Master
	- Music
	- SFX
   	- Mic
     	- Ambience
  - Has an `AudioStreamPlayer` for music by default with no music attached
  - Unmutes the Audio Buses when exported, so you can edit in peace and quiet
- `PlayerManager.gd`
	- Responsible for keeping track of Player information during gameplay
		- Player ID
		- Player Name
		- Node the Player is controlling
  		- Color
## Game Logic
- Manager / Handler differentiation
 	- Manager scripts deal with overarching systems outside of the Players direct control (some are not explicitly named manager sometimes and that is probably confusing)
   		- Audio
  		- Events
    		- PowerGrid
   	- Handlers deal with resolving individual player actions
   	 	- Interacting
   	    	- Picking up something
   	     	- Dropping something
		- etc
## Creating Levels
  - Add your level scenes to the `LevelStore` `Resource` file `res://resources/StandardLevels.tres`
  - The level being spawned should have a top level script that emits a `finished_level` `signal` when players finish a level
	- once this `signal` is emitted then it will proceed to the next level
  - You can create another `LevelStore` for levels you are testing and adjust the `level_store` variable in `LevelManager.gd`
	- Note: You can export the `level_store` variable for more of an editor workflow

## Debug Related Things
- `my_debug` folder is gitignored, you can store any personal debugging stuff in there

## Credits
- SFX from [Kenney](https://www.kenney.nl/)
- VOIP from [WIP] https://github.com/RevoluPowered/one-voip-godot-4
- Icons
	- O2 https://www.svgrepo.com/svg/139900/oxygen
	- Run https://www.svgrepo.com/svg/489113/run
	- Heart https://www.svgrepo.com/svg/525369/heart
