extends Node

const Recipe = preload("res://scripts/core/recipe.gd")
const Character = preload("res://scripts/core/character.gd")
const CraftingStartOutcome = preload("res://scripts/core/crafting_outcome.gd")

var active_jobs: Array = []
var _next_id := 1

func start_job(recipe: Recipe, character: Character) -> CraftingStartOutcome:
	var outcome := CraftingStartOutcome.new()
	if recipe == null or recipe.id.is_empty():
		outcome.ok = false
		outcome.log.append("Unknown recipe.")
		return outcome
	if not character.inventory.can_afford(recipe.inputs):
		outcome.ok = false
		outcome.log.append("Missing ingredients.")
		return outcome

	character.inventory.deduct(recipe.inputs)
	var job = {
		"id": _next_id,
		"recipe": recipe,
		"time_left": recipe.craft_time
		}
	_next_id += 1
	active_jobs.append(job)
	outcome.ok = true
	outcome.log.append("Started %s (%.1fs)" % [recipe.id, recipe.craft_time])
	outcome.job_id = int(job["id"])
	return outcome

func tick(delta: float, character: Character) -> Array[String]:
	var finished: Array[String] = []
	if active_jobs.is_empty():
		return finished
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
