@icon("res://art/icons/package.svg")
extends Node
class_name Package

# Needed?
class PackageInstruction:
	var description : String

var time_to_deliver : float
var recipient : Universe.Resident
var special_instructions : Array[PackageInstruction]
