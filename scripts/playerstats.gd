extends Spatial

onready var kinematic = $KinematicBody
onready var model = $KinematicBody/MeshInstance
export var player_number: int = 0

var detected_devices = [ # todo: test with Joypads
	InputEventMouseMotion,
	InputEventJoypadMotion,
]

func _ready():
	kinematic.controlling_player = player_number # todo: test with Joypads
	kinematic.look_device = detected_devices[player_number]
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func update_player_number(number:int):
	player_number = number
	kinematic.controlling_player = number

func disable_input():
	kinematic.movement_enabled = false

func enable_input():
	kinematic.movement_enabled = true
