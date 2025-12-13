class_name TravelService extends RefCounted

const MapNode = preload("res://scripts/core/map_node.gd")
const MapsData = preload("res://data/maps.gd")
const TravelOutcome = preload("res://scripts/core/travel_outcome.gd")

var submap_nodes: Dictionary = {} # submap -> Array[MapNode]
var nodes: Dictionary = {} # id -> MapNode


# Costs moved to GameConstants


func _init():
	_load_data()

func _load_data():
	for submap in MapsData.MAPS.keys():
		submap_nodes[submap] = []
		for node_data in MapsData.MAPS[submap]:
			var node = MapNode.new(node_data)
			submap_nodes[submap].append(node)
			nodes[node.id] = node
		submap_nodes[submap].sort_custom(func(a, b): return a.distance < b.distance)

func list_submaps() -> Array[String]:
	var subs: Array[String] = []
	for key in submap_nodes.keys():
		subs.append(String(key))
	subs.sort()
	return subs

func list_nodes(submap: String) -> Array[String]:
	var ids: Array[String] = []
	if not submap_nodes.has(submap):
		return ids
	var sorted_nodes = submap_nodes[submap].duplicate()
	# Already sorted in load, but copy ensures safety
	for node in sorted_nodes:
		ids.append(node.id)
	return ids

func travel_to_submap(location: String, energy: float, submap: String) -> TravelOutcome:
	var outcome: TravelOutcome = TravelOutcome.new()
	if submap == "":
		outcome.log.append("Choose a submap.")
		outcome.new_location = location
		return outcome

	var current_submap = get_submap_from_location(location)
	var exit_cost = _exit_cost_from_location(location)
	var travel_cost = GameConstants.SUBMAP_TRAVEL_COSTS.get(submap, 10.0)

	# If already in target submap and at entrance
	if current_submap == submap and get_node_from_location(location) == "":
		outcome.log.append("Already in %s." % submap)
		outcome.new_location = location
		return outcome

	# If in same submap but at node, return to entrance logic
	if current_submap == submap:
		var total = exit_cost
		if energy < total:
			outcome.log.append("Not enough energy: need %.1f to return to %s entrance." % [total, submap])
			outcome.new_location = location
			return outcome
		outcome.ok = true
		outcome.energy_cost = total
		outcome.new_location = submap
		outcome.log.append("Returned to %s entrance (-%.1f energy)." % [submap, total])
		return outcome

	# Normal travel
	var total_cost = exit_cost + travel_cost
	if energy < total_cost:
		outcome.log.append("Not enough energy: need %.1f (exit %.1f + travel %.1f)" % [total_cost, exit_cost, travel_cost])
		outcome.new_location = location
		return outcome

	outcome.ok = true
	outcome.energy_cost = total_cost
	outcome.new_location = submap
	outcome.log.append("Traveled to %s (-%.1f energy)." % [submap, total_cost])
	return outcome

func move_to_node(location: String, energy: float, target_submap: String, node_id: String) -> TravelOutcome:
	var outcome: TravelOutcome = TravelOutcome.new()

	if get_submap_from_location(location) != target_submap:
		outcome.log.append("Travel to %s first." % target_submap)
		outcome.new_location = location
		return outcome
	if target_submap == GameConstants.SUBMAP_TOWN:
		outcome.log.append("Town has no nodes.")
		outcome.new_location = location
		return outcome
	if not nodes.has(node_id):
		outcome.log.append("No node named %s." % node_id)
		outcome.new_location = location
		return outcome

	var target_distance = _node_distance(target_submap, node_id)
	if target_distance <= 0:
		outcome.log.append("Node %s is not in %s." % [node_id, target_submap])
		outcome.new_location = location
		return outcome

	var current_node = get_node_from_location(location)
	var current_distance = _node_distance(target_submap, current_node) if current_node != "" else 0

	var diff = abs(target_distance - current_distance)
	if diff == 0:
		outcome.log.append("Already at %s." % node_id)
		outcome.new_location = location
		return outcome

	var node_cost = GameConstants.SUBMAP_NODE_COSTS.get(target_submap, 2.0)
	var total_cost = diff * node_cost

	if energy < total_cost:
		outcome.log.append("Not enough energy: need %.1f to move." % total_cost)
		outcome.new_location = location
		return outcome

	outcome.ok = true
	outcome.energy_cost = total_cost
	outcome.new_location = "%s>%s" % [target_submap, node_id]
	outcome.log.append("Moved to %s (-%.1f energy)." % [node_id, total_cost])
	return outcome

# Helpers
func get_submap_from_location(loc: String) -> String:
	var parts = loc.split(">")
	return parts[0]

func get_node_from_location(loc: String) -> String:
	var parts = loc.split(">")
	return parts[1] if parts.size() > 1 else ""

func _exit_cost_from_location(location: String) -> float:
	var current_node = get_node_from_location(location)
	if current_node == "":
		return 0.0
	var submap = get_submap_from_location(location)
	var distance = _node_distance(submap, current_node)
	if distance <= 0:
		return 0.0
	return distance * GameConstants.SUBMAP_NODE_COSTS.get(submap, 2.0)

func _node_distance(submap: String, node_id: String) -> int:
	if not submap_nodes.has(submap):
		return -1
	for i in range(submap_nodes[submap].size()):
		if submap_nodes[submap][i].id == node_id:
			return i + 1
	return -1
