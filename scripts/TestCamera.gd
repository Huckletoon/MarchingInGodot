extends Camera

export var turnSpeed = 2.0
export var goSpeed = 4

var rotX = 0
var rotZ = 0
var rotDecay = 0.1

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotX = -event.relative.y
		rotZ = event.relative.x
		pass
	

func _physics_process(delta):
	var forward = Input.get_action_strength("move_foward")
	var back = Input.get_action_strength("move_back")
	var moveLeft = Input.get_action_strength("move_left")
	var moveRight = Input.get_action_strength("move_right")
	var moveUp = Input.get_action_strength("move_up")
	var moveDown= Input.get_action_strength("move_down")
	var right = Input.get_action_strength("ui_right")
	var left = Input.get_action_strength("ui_left")
	var up = Input.get_action_strength("ui_up")
	var down = Input.get_action_strength("ui_down")
	
	var movement = Vector3((moveRight - moveLeft) * delta * goSpeed, (moveUp - moveDown) * delta * goSpeed, (back - forward) * delta * goSpeed)
	#rotX = (up - down) * PI / 180
	#rotZ = (right - left) * PI / 180
	if (rotX > 0 and rotX < rotDecay) or (rotX < 0 and rotX > -rotDecay):
		rotX = 0
	elif (rotX != 0):
		rotX -= sign(rotX)*rotDecay
	
	if (rotZ > 0 and rotZ < rotDecay) or (rotZ < 0 and rotZ > -rotDecay):
		rotZ = 0
	elif (rotZ !=0):
		rotZ -= sign(rotZ)*rotDecay
	
	
	translate(movement)
	rotate_object_local(Vector3(1, 0, 0), rotX * turnSpeed * delta)
	rotate(Vector3(0, -1, 0), rotZ * turnSpeed * delta)
	