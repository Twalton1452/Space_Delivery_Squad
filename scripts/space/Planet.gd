extends Node3D
class_name Planet

class PlanetCondition:
	pass

var id : int
var display_name : String
var galaxy : Galaxy
var residents : Array[Universe.Resident]
var conditions : Array[PlanetCondition]
