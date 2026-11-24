extends CharacterBody3D
class_name Player

const SPEED = 10.0
var mouse_sensitivity = 0.002

@export var active = false

@export var party : Array[Agent] = []
var starterPrompted = false

@onready var raycast = RayCast3D.new()

func _process(delta):
	$Camera3D.current = active
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		active = false
	
	if active:
		#raycast.position = $Camera3D.position
		raycast.global_position = $Camera3D.global_position
		raycast.global_rotation = $Camera3D.global_rotation
		if raycast.get_collider() is Agent:
			$Battle.visible = true
			if Input.is_action_just_pressed("interact"):
				$"../PlayerUI".doBattle(self,raycast.get_collider())
		else:
			$Battle.visible = false
	

func _ready():
	add_child(raycast)
	raycast.position = $Camera3D.position
	raycast.collision_mask = 3
	raycast.target_position = Vector3(0, 0, -10)

func _physics_process(delta):
	if !active: return
	
	if !starterPrompted and party.size() == 0: 
		starterPrompted = true
		$"../PlayerUI".doStarterPrompt()
	
	var mouseModeOverwrite = true
	if $"../PlayerUI/Starters".visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouseModeOverwrite = false
	
	var input_dir = Input.get_vector("left","right","forward","backward")
	var dir = (transform.basis * Vector3(input_dir.x,0,input_dir.y)).normalized()
	
	if dir:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		if mouseModeOverwrite: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		velocity.x = move_toward(velocity.x,0,SPEED)
		velocity.z = move_toward(velocity.z,0,SPEED)
	
	if !is_on_floor():
		velocity.y += get_gravity().y
	else:
		velocity.y = 0
	
	move_and_slide()

func addToParty(creature : Agent):
	creature.updateLevelHashes()
	creature.HP = creature._HPHash
	creature.visualGenerator = CreatureGeneratorNode.new()
	creature.visualGenerator.surfaceMaterial.albedo_color = %SpeciesHandler.Species[creature.species].color
	creature.doVisual()
	party.append(creature)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * mouse_sensitivity)
			$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity)
