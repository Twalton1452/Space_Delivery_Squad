@icon("res://art/icons/package.svg")
extends Node
class_name Package

## Component to be attached as a child of an Item.
## It contains information related to the Delivery that can be displayed when picked up

# Needed?
class PackageInstruction:
	var description : String

var destination_galaxy : Universe.Galaxy
var destination_planet : Universe.Planet
var time_to_deliver : float
var time_left_to_deliver : float

var recipient : Universe.Resident
var special_instructions : Array[PackageInstruction]

func _ready() -> void:
	(get_parent() as Item).picked_up.connect(_on_picked_up)
	(get_parent() as Item).dropped.connect(_on_dropped)
	
	test_package_data()

func test_package_data() -> void:
	if not Universe.generated:
		await Universe.finished_generation
	
	destination_galaxy = Universe.galaxies.pick_random()
	destination_planet = destination_galaxy.planets.pick_random()
	recipient = destination_planet.residents.pick_random()
	
	time_to_deliver = randi_range(1, 10)
	time_left_to_deliver = time_to_deliver

func _on_picked_up(picker_upper: Player) -> void:
	picker_upper.hud.update_package_label(self)

func _on_dropped(dropper: Player) -> void:
	dropper.hud.hide_package_label()
