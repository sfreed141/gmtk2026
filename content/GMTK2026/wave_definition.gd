extends Resource
class_name WaveDefinition

signal wave_defeated(wave_id: int)

@export var wave_scenes: Array[PackedScene]

# wave_id -> Array[Node]
var _wave_cohorts: Dictionary
static var _next_wave_id = 0

func spawn(spawn_root: Node2D, spawn_position_candidates: Array):
	var next_position_idx = 0
	var taken_position_idxs = {}
	var space := spawn_root.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var wave_cohort = []
	var wave_id = _next_wave_id
	_next_wave_id += 1
	
	spawn_position_candidates.shuffle()
	for scene in wave_scenes:
		var instance := scene.instantiate() as RigidBody2D
		var collision := instance.get_node("CollisionShape2D") as CollisionShape2D
		query.shape = collision.shape
		query.collision_mask = instance.collision_mask
		
		var spawned = false
		for i in range(spawn_position_candidates.size()):
			var idx = (next_position_idx + i) % spawn_position_candidates.size()
			if taken_position_idxs.has(idx):
				continue
			
			var candidate := spawn_position_candidates[idx] as Node2D
			var candidate_position = candidate.global_position
			query.transform = Transform2D(instance.rotation, candidate_position) * collision.transform
			
			var query_results = space.intersect_shape(query, 1)
			if query_results.is_empty():
				taken_position_idxs[idx] = true
				instance.position = candidate_position
				spawn_root.add_child(instance)
				instance.reset_physics_interpolation()
				wave_cohort.append(instance)
				next_position_idx = (idx + 1) % spawn_position_candidates.size()
				spawned = true
				break
	
	for n: Node in wave_cohort:
		n.tree_exiting.connect(func ():
			wave_cohort.erase(n)
			if wave_cohort.is_empty():
				wave_defeated.emit(wave_id)
			, CONNECT_ONE_SHOT
		)
	
	_wave_cohorts[wave_id] = wave_cohort
