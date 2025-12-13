class_name TravelService extends RefCounted

const MapNode = preload("res://scripts/core/map_node.gd")
const MapsData = preload("res://data/maps.gd")

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

func travel_to_submap(player, submap: String) -> Array[String]:
	var logs: Array[String] = []
	if player == null:
		logs.append("No active character. Create or select one first.")
		return logs
	if submap == "":
		logs.append("Choose a submap.")
		return logs

	var current_submap = get_submap_from_location(player.location)
	var exit_cost = _exit_cost_from_current(player)
	var travel_cost = GameConstants.SUBMAP_TRAVEL_COSTS.get(submap, 10.0)

	# If already in target submap and at entrance
	if current_submap == submap and get_node_from_location(player.location) == "":
		logs.append("Already in %s." % submap)
		return logs

	# If in same submap but at node, return to entrance logic
	if current_submap == submap:
		var total = exit_cost
		if player.stats.energy < total:
			logs.append("Not enough energy: need %.1f to return to %s entrance." % [total, submap])
			return logs
		player.stats.consume_energy(total)
		player.location = submap
		logs.append("Returned to %s entrance (-%.1f energy)." % [submap, total])
		return logs

	# Normal travel
	var total_cost = exit_cost + travel_cost
	if player.stats.energy < total_cost:
		logs.append("Not enough energy: need %.1f (exit %.1f + travel %.1f)" % [total_cost, exit_cost, travel_cost])
		return logs

	player.stats.consume_energy(total_cost)
	player.location = submap
	logs.append("Traveled to %s (-%.1f energy)." % [submap, total_cost])
	return logs

func move_to_node(player, target_submap: String, node_id: String) -> Array[String]:
	var logs: Array[String] = []
	if player == null:
		logs.append("No active character.")
		return logs

	if get_submap_from_location(player.location) != target_submap:
		logs.append("Travel to %s first." % target_submap)
		return logs
	if target_submap == GameConstants.SUBMAP_TOWN:
		logs.append("Town has no nodes.")
		return logs
	if not nodes.has(node_id):
		logs.append("No node named %s." % node_id)
		return logs

	var target_distance = _node_distance(target_submap, node_id)
	if target_distance <= 0:
		logs.append("Node %s is not in %s." % [node_id, target_submap])
		return logs

	var current_node = get_node_from_location(player.location)
	var current_distance = _node_distance(target_submap, current_node) if current_node != "" else 0

	var diff = abs(target_distance - current_distance)
	if diff == 0:
		logs.append("Already at %s." % node_id)
		return logs

	var node_cost = GameConstants.SUBMAP_NODE_COSTS.get(target_submap, 2.0)
	var total_cost = diff * node_cost

	if player.stats.energy < total_cost:
		logs.append("Not enough energy: need %.1f to move." % total_cost)
		return logs

	player.stats.consume_energy(total_cost)
	player.location = "%s>%s" % [target_submap, node_id]
	logs.append("Moved to %s (-%.1f energy)." % [node_id, total_cost])
	return logs

func return_to_town(player) -> Array[String]:
	return travel_to_submap(player, GameConstants.SUBMAP_TOWN)

# Helpers
func get_submap_from_location(loc: String) -> String:
	var parts = loc.split(">")
	return parts[0]

func get_node_from_location(loc: String) -> String:
	var parts = loc.split(">")
	return parts[1] if parts.size() > 1 else ""

func _exit_cost_from_current(player) -> float:
	var current_node = get_node_from_location(player.location)
	if current_node == "":
		return 0.0
	var submap = get_submap_from_location(player.location)
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
