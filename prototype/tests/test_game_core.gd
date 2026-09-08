extends SceneTree

const GameCoreScript = preload("res://scripts/game_core.gd")
const LLMClientScript = preload("res://scripts/llm_client.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_day_composition()
	_test_seller_resolution()
	_test_buyer_resolution()
	_test_appraisal_history()
	_test_patience_boundary()
	_test_response_parser()
	if failures.is_empty():
		print("PASS: all Heirloom Ledger prototype tests passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_day_composition() -> void:
	var core = GameCoreScript.new()
	_expect(core.guests.size() == 4, "day must contain exactly four guests")
	var sellers := 0
	var buyers := 0
	var challenges := 0
	for guest in core.guests:
		if guest["role"] == "seller": sellers += 1
		if guest["role"] == "buyer": buyers += 1
		if guest["challenge"]: challenges += 1
		if guest["challenge"]:
			_expect(not guest["missable"].is_empty(), "challenge guest must have discoverable clues")
	_expect(sellers == 2, "day must contain two sellers")
	_expect(buyers == 2, "day must contain two buyers")
	_expect(challenges == 2, "standard demo day must contain two challenge guests")
	_expect(core.guests[0]["role"] != core.guests[1]["role"], "morning should alternate guest roles")
	_expect(core.guests[2]["role"] != core.guests[3]["role"], "afternoon should alternate guest roles")

func _test_seller_resolution() -> void:
	var core = GameCoreScript.new()
	core.next_guest()
	var before_money: int = core.money
	var before_inventory: int = core.inventory.size()
	var low = core.process_action("offer", {"amount": 300})
	_expect(not low["completed"], "low seller offer should be rejected without immediate completion")
	var accepted = core.process_action("offer", {"amount": 700})
	_expect(accepted["completed"], "offer above seller minimum should complete")
	_expect(core.money == before_money - 700, "accepted seller offer must reduce money")
	_expect(core.inventory.size() == before_inventory + 1, "accepted seller offer must add inventory")

func _test_buyer_resolution() -> void:
	var core = GameCoreScript.new()
	core.next_guest()
	core.process_action("decline")
	core.next_guest()
	core.select_item("inkstone")
	core.process_action("recommend")
	var before_money: int = core.money
	var before_inventory: int = core.inventory.size()
	var sale = core.process_action("offer", {"amount": 1900})
	_expect(sale["completed"], "exact-match item within buyer budget should sell")
	_expect(core.money == before_money + 1900, "sale must increase money")
	_expect(core.inventory.size() == before_inventory - 1, "sale must remove inventory")

func _test_appraisal_history() -> void:
	var core = GameCoreScript.new()
	core.next_guest()
	var first = core.process_action("appraise")
	_expect(first.has("appraisal"), "appraisal action should be marked")
	_expect(core.appraisal_history.size() == 1, "first appraisal should create history")
	core.process_action("appraise")
	_expect(core.appraisal_history.size() == 1, "repeating same appraisal should not overwrite or duplicate history")
	_expect(int(core.current_guest["item"]["probability"]) > 0 and int(core.current_guest["item"]["probability"]) < 100, "probability mode must exclude 0 and 100")

func _test_patience_boundary() -> void:
	var core = GameCoreScript.new()
	core.next_guest()
	for i in range(5):
		core.process_action("source")
	_expect(int(core.current_guest["patience"]) == 0, "repeated investigation should exhaust patience")
	var blocked = core.process_action("repair")
	_expect(str(blocked["system_text"]).contains("最后报价"), "exhausted guest must stop new investigation")
	var final_offer = core.process_action("offer", {"amount": 700})
	_expect(final_offer["completed"], "final offer must remain available after patience is exhausted")

func _test_response_parser() -> void:
	var fixture := {
		"output": [{"type": "message", "content": [{"type": "output_text", "text": "连接成功"}]}]
	}
	_expect(LLMClientScript.extract_output_text(fixture) == "连接成功", "Responses API output parser should extract output_text")
