extends SceneTree

const Core = preload("res://scripts/chapter_core.gd")
var failures: Array[String] = []

func _init() -> void:
	var core = Core.new()
	check(core.content["people"].size() == 8, "Eight authored people")
	check(core.all_items.size() >= 24, "At least 24 individual items")
	check(core.guests.size() == 4, "Four daily visits")
	var met := {}
	for day in range(1, 11):
		check(core.day == day, "Ten consecutive days")
		for slot in range(4):
			if slot == 2:
				core.next_guest()
				check(core.phase == "noon", "Pause at noon")
				core.continue_afternoon()
			core.next_guest()
			core.reveal_opening()
			met[core.current_guest["id"]] = true
			if core.current_guest["role"] == "seller":
				var before: int = core.money
				core.process_action("offer", {"amount": core.current_guest["min_price"]})
				check(core.money == before, "Appraisal required before acquisition")
				core.process_action("source")
				core.process_action("appraise")
				if core.money >= int(core.current_guest["min_price"]):
					core.process_action("offer", {"amount": core.current_guest["min_price"]})
			else:
				core.process_action("need")
				for item in core.inventory:
					if core.get_match_level(item, core.current_guest) == "exact" and not item.get("custody", false):
						core.select_item(item["id"])
						core.process_action("recommend")
						check(core.answer_suggestions().size() == 3, "Three factual answer drafts")
						core.process_action("respond", {"text": core.answer_suggestions()[0]})
						core.process_action("offer", {"amount": int(core.current_guest["need"]["max_price"])})
						break
			if not core.current_guest["completed"]: core.process_action("decline")
		core.next_guest()
		check(core.phase == "closing", "Daily closing after visitors")
		for node in core.available_story():
			check(core.choose_story(node["id"], node["choices"][0]["id"]), "Available story choice executable")
		check(core.money >= 0, "Balance never negative")
		if day < 10: check(core.next_day(), "Can advance day")
	check(met.size() == 8, "Every main character appears during actual visits")
	check(core.flags.has("consent") and core.flags.has("catalogue"), "Clues and consent chain reachable")
	var save := "user://test_chapter_save.json"
	check(core.save_game(save) == OK, "Save at chapter end")
	var loaded = Core.new()
	check(loaded.load_game(save) == OK, "Load chapter save")
	check(loaded.money == core.money and loaded.inventory.size() == core.inventory.size(), "Inventory and money survive reload")
	for actor in core.contacts:
		check(int(loaded.contacts[actor]["relation"]) == int(core.contacts[actor]["relation"]), "Relationship survives reload")
		check(loaded.contacts[actor]["memories"] == core.contacts[actor]["memories"], "Memories survive reload")
	check(loaded.flags == core.flags, "Evidence survives reload")
	check(core.finish_chapter("return").get("title") == "旧物归人", "Return ending reachable")
	check(loaded.finish_chapter("sale").get("title") == "有据可循", "Consented sale ending reachable")
	var reserved = Core.new()
	reserved.day = 10
	reserved.phase = "closing"
	check(reserved.finish_chapter("return").get("title") == "未完的账", "Missing evidence cannot fake resolved ending")
	_test_outside()
	_test_knowledge_and_recovery()
	_test_saved_state_and_consequences()
	if failures.is_empty():
		print("PASS: ten-day chapter, eight visitors, trade guards, evidence branches, save/load, outside and recovery")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _test_outside() -> void:
	var core = Core.new()
	check(not core.can_go_out(), "No abandoning active opening for outside trade")
	core.phase = "noon"
	var item: Dictionary = core.market_item()
	core.inspect_outside(item["id"])
	core.market_buy(int(item["minimum"]))
	var count: int = core.inventory.size()
	core.market_buy(int(item["minimum"]))
	check(core.inventory.size() == count, "Market cannot duplicate goods")
	var before: int = core.money
	core.consult("inkstone")
	core.consult("inkstone")
	check(core.money == before - 100, "One expert service per day")
	core.day = 3
	core.money = 5000
	core.auction_preview()
	core.inspect_outside(core.auction["item_id"])
	core.bid(1200)
	check(core.auction["done"], "Auction settles after outbidding rival")
	check(core.money == 3740, "Auction pays hammer price plus disclosed fee")
	core.bid(1300)
	check(core.money == 3740, "Auction cannot charge twice")

func _test_knowledge_and_recovery() -> void:
	var core = Core.new()
	core.next_guest()
	core.reveal_opening()
	core.process_action("appraise")
	check(not core.current_guest["item"]["judged_fake"], "Low skill does not reveal decisive hidden flaw")
	core.skills["瓷器"] = 65
	core.process_action("appraise")
	check(core.current_guest["item"]["judged_fake"], "New skill permits evidence-based definite false result")
	check(core.appraisal_history.size() == 2, "New judgment preserves old record")
	core.inventory.clear()
	core.money = 0
	core.current_guest = {}
	core.phase = "closing"
	check(core.recovery_available(), "Empty inventory and zero cash have recovery")
	core.complete_recovery()
	core.complete_recovery()
	check(core.money == 500, "Recovery cannot be farmed twice")

func _test_saved_state_and_consequences() -> void:
	var core = Core.new()
	var save := "user://test_chapter_guard.json"
	core.next_guest()
	core.reveal_opening()
	core.save_game(save)
	core.process_action("appraise")
	check(core.load_game(save) == OK, "Earlier save loads after new optional appraisal fields")
	check(not core.current_guest["item"]["appraised"], "Earlier appraisal state restored")
	var parser := JSON.new()
	parser.parse(FileAccess.get_file_as_string(save))
	var data: Dictionary = parser.data
	data["contacts"] = []
	var corrupt := FileAccess.open(save, FileAccess.WRITE)
	corrupt.store_string(JSON.stringify(data))
	corrupt.close()
	var balance: int = core.money
	check(core.load_game(save) == ERR_FILE_CORRUPT and core.money == balance, "Corrupt save rejected without partial mutation")
	core.current_guest = {}
	core.inventory.clear()
	core.inventory.append(core.all_items["painting"])
	core.money = 0
	check(core.recovery_available(), "Custody-only inventory does not block recovery")
	core.reset()
	core.sold_items = [{"id": "snuff", "day": 1, "buyer": "lin", "price": 2700, "discovered": false}]
	var knowledge: int = core.skills["杂项"]
	core.day = 2
	core._resolve_discoveries()
	check(core.consequences.is_empty() and core.trust_points == 0, "No punishment before actual discovery")
	core.day = 3
	core._resolve_discoveries()
	check(core.consequences.size() == 1 and core.trust_points == -1, "Qualified later discovery creates initial consequence")
	core._resolve_discoveries()
	check(core.skills["杂项"] == knowledge + 5 and core.trust_points == -1, "No duplicate learning or base punishment")
	core.day = 5
	core._resolve_discoveries()
	check(core.consequences[0]["stage"] == 1, "High value gift can reach industry circle")
	core.day = 7
	core._resolve_discoveries()
	check(core.consequences[0]["stage"] == 2, "High exposure can reach public circle")
	core.reset()
	core.day = 10
	core.phase = "closing"
	core.flags = {"consent": true, "catalogue": true}
	core.finish_chapter("sale")
	core.finish_chapter("sale")
	check(core.money == 3780 and core.ledger.size() == 1, "Consignment fee settles once")
	check(core.all_items["painting"]["location"] == "returned", "Both resolved routes respect owner's retained painting")
