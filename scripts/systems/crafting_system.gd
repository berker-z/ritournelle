extends Node

const Recipe = preload("res://scripts/core/recipe.gd")
const Character = preload("res://scripts/core/character.gd")

var active_jobs: Array = []
var _next_id := 1

func start_job(recipe: Recipe, character: Character) -> Dictionary:
	if recipe.id.is_empty():
		return {"ok": false, "log": ["Unknown recipe."]}
	if not character.inventory.can_afford(recipe.inputs):
		return {"ok": false, "log": ["Missing ingredients."]}

	character.inventory.deduct(recipe.inputs)
	var job = {
		"id": _next_id,
		"recipe": recipe,
		"time_left": recipe.craft_time
	}
	_next_id += 1
	active_jobs.append(job)
	return {"ok": true, "log": ["Started %s (%.1fs)" % [recipe.id, recipe.craft_time]], "job_id": job["id"]}

func tick(delta: float, character: Character) -> Array:
	if active_jobs.is_empty():
		return []
	var finished: Array = []
	for job in active_jobs:
		job["time_left"] -= delta
	for job in active_jobs.duplicate():
		if job["time_left"] <= 0:
			finished.append(_complete_job(job, character))
			active_jobs.erase(job)
	return finished

func _complete_job(job: Dictionary, character: Character) -> String:
	var recipe: Recipe = job["recipe"]
	for item_id in recipe.output.keys():
		var amount: int = int(recipe.output[item_id])
		character.inventory.add(item_id, amount)
	var log = ["Crafted %s" % recipe.id]
	if recipe.xp_reward.size() > 0:
		log.append_array(character.apply_rewards({"xp": recipe.xp_reward})["log"])
	return " | ".join(PackedStringArray(log))

func has_jobs() -> bool:
	return not active_jobs.is_empty()

func reset():
	active_jobs.clear()
	_next_id = 1
