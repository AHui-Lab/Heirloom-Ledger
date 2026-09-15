extends SceneTree

class StubClient extends DemoLLMClient:
	var calls := 0
	func request_npc_reply(_name: String, _personality: String, _player: String,
			_instruction: String, _history: Array[String], _speaker: String = "npc") -> Error:
		calls += 1
		return OK

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	var client := DemoLLMClient.new()
	client.configure("test-secret", "test-model", "https://example.invalid/v1", "/responses", "responses", 0.7, 4096)
	check(client.build_request_body("system", "input")["max_output_tokens"] == 4096, "Responses must honor user budget")
	client.configure("test-secret", "test-model", "https://example.invalid/v1", "/chat/completions", "chat_completions", 0.7, 4096)
	check(client.build_request_body("system", "input")["max_tokens"] == 4096, "Chat must honor user budget")
	client.configure("test-secret", "deepseek-v4-flash", "https://api.deepseek.com", "/responses", "responses", -1.0, 4096)
	check(client.build_request_body("system", "input").get("reasoning", {}).get("effort") == "none", "DeepSeek Responses dialogue disables hidden thinking")
	client.configure("test-secret", "deepseek-v4-flash", "https://api.deepseek.com", "/chat/completions", "chat_completions", -1.0, 4096)
	check(client.build_request_body("system", "input").get("thinking", {}).get("type") == "disabled", "DeepSeek Chat dialogue disables hidden thinking")
	var diagnosis := DemoLLMClient.response_diagnosis({"status": "incomplete", "incomplete_details": {"reason": "max_output_tokens"}})
	check(diagnosis["truncated"], "Responses truncation must be diagnosed")
	diagnosis = DemoLLMClient.response_diagnosis({"choices": [{"finish_reason": "length", "message": {"content": null}}]})
	check(diagnosis["truncated"], "Chat truncation must be diagnosed")
	var prompt := DemoLLMClient.build_dialogue_prompt("赵庆生", "谨慎", "客人刚刚进店。", "带来旧物", [], "npc")
	check(prompt["input"].contains("不是掌柜台词"), "Opening must be a scene event")
	prompt = DemoLLMClient.build_dialogue_prompt("赵庆生", "谨慎", "观察", "磨损", [], "inner")
	check(prompt["instructions"].contains("客人听不到"), "Inner voice must have its own role")
	client.free()
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.llm.queue_free()
	var stub := StubClient.new()
	scene.add_child(stub)
	scene.llm = stub
	scene.core.next_guest()
	check(scene.core.visible_item_record("blue_bowl").is_empty(), "Unintroduced seller item must stay hidden")
	scene.core.current_guest["role_revealed"] = true
	var record: Dictionary = scene.core.visible_item_record("blue_bowl")
	check(record["provenance"].is_empty() and record["clues"].is_empty(), "Record must not reveal unknown source or clues")
	check(not record.has("authentic") and not record.has("era") and not record.has("market_value"), "Record must exclude hidden reality")
	var patience_before: int = scene.core.current_guest["patience"]
	scene._show_item_record()
	check(scene.core.current_guest["patience"] == patience_before, "Reading must not consume patience")
	scene.item_record_dialog.hide()
	scene.core.process_action("source")
	record = scene.core.visible_item_record("blue_bowl")
	check(record["provenance"].contains("未独立核实"), "Disclosed source must remain a claim, not confirmed history")
	var observation: Dictionary = scene.core.process_action("inspect")
	check(observation.get("speaker") == "inner", "Observation must not be spoken by NPC")
	var price: Dictionary = scene.core.process_action("offer", {"amount": 700})
	var money_before: int = scene.core.money
	var ledger_before: int = scene.core.ledger.size()
	check(scene.core.visible_item_record("blue_bowl")["provenance"] == record["provenance"], "Buying must preserve the disclosed source record")
	scene.pending_mode = "npc"
	scene.pending_player_text = "报价700"
	scene.pending_instruction = price["llm_instruction"]
	scene.pending_completed = true
	scene._on_llm_response(false, "", "Test: no visible text")
	check(scene.offer_button.disabled and scene.awaiting_llm, "Failure must block new transactions")
	scene._continue_flow()
	scene._on_llm_response(false, "", "Test: timeout")
	scene._continue_flow()
	scene._on_llm_response(true, "成交。", "")
	check(stub.calls == 2, "Each retry must dispatch only once")
	check(scene.core.money == money_before and scene.core.ledger.size() == ledger_before, "Retry must never repeat settlement")
	check(not scene.reply_needs_retry and not scene.awaiting_llm, "Successful retry must clear blocked state")
	check(scene.continue_button.visible and scene.offer_button.disabled, "Completed trade must offer continuation without reopening trade")
	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: dialogue role, token budget, diagnosis and repeated retry regressions")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
