extends Node3D
class_name ConnecterSystem

@onready var emission_timer = $EmissionTimer

var connecters : Array[Connecter]
var max_fluid_reserves = 1.0
var fluid_reserves = 1.0
var flow_rate = 0.1

var debug_label : Label3D

func _ready():
	add_to_group(Constants.CONNECTER_GROUP)
	if multiplayer.is_server():
		emission_timer.timeout.connect(_on_emission_timer_timeout)
		debug_label = Label3D.new()
		add_child(debug_label)
		debug_label.text = str(fluid_reserves)
		debug_label.position += Vector3(0.0, 1.5, 0.0)

## The ConnecterSystem lets Connecters find it
func connect_to(connecter: Connecter) -> void:
	if connecter in connecters:
		return
	connecters.push_back(connecter)
	connecter.disconnecting.connect(_on_connecter_disconnected)
	#print(connecter.name, " connected to ", name)
	
	if multiplayer.is_server() and emission_timer.is_stopped():
		emission_timer.start()

func _on_connecter_disconnected(connecter: Connecter) -> void:
	connecter.disconnecting.disconnect(_on_connecter_disconnected)
	connecters.erase(connecter)
	#print(connecter.name, " disconnected from ", name)
	if connecters.size() == 0:
		emission_timer.stop()

func _on_emission_timer_timeout() -> void:
	if fluid_reserves > 0:
		push_fluid()
		emission_timer.start()
	else:
		#print(name, " ran out of fluid. Good Luck Players")
		emission_timer.stop()
	debug_label.text = str(fluid_reserves)
	debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func push_fluid() -> void:
	for connecter in connecters:
		var pushable_fluid = fluid_reserves - flow_rate
		# Normal Flow
		if pushable_fluid > 0.0:
			if connecter.carry(flow_rate, null):
				fluid_reserves -= flow_rate
		# Exhausting every last drop
		elif fluid_reserves > 0.0:
			if connecter.carry(fluid_reserves, null):
				fluid_reserves = 0.0
		# Empty
		else:
			#print(name, " ran out of fluid. This is a problem for the players!")
			break
