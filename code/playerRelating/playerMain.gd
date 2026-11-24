extends CharacterBody3D
class_name Player

const SPEED = 10.0
var mouse_sensitivity = 0.002

@export var active = false

@export var party : Array[Agent] = []

func _process(delta):
	$Camera3D.current = active
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		active = false

func _physics_process(delta):
	if !active: return
	
	if party.size() != 4:
		var kinapped : Agent = get_tree().get_nodes_in_group("creature").pick_random()
		print("i got ", kinapped)
		party.append(kinapped)
		kinapped.get_parent().remove_child(kinapped)
		$"../PlayerUI".render(self)
	
	var input_dir = Input.get_vector("left","right","forward","backward")
	var dir = (transform.basis * Vector3(input_dir.x,0,input_dir.y)).normalized()
	
	if dir:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		velocity.x = move_toward(velocity.x,0,SPEED)
		velocity.z = move_toward(velocity.z,0,SPEED)
	
	if !is_on_floor():
		velocity.y += get_gravity().y
	else:
		velocity.y = 0
	
	move_and_slide()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * mouse_sensitivity)
			$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity)
