extends SceneTree

const Store = preload("res://scripts/profile_store.gd")
const Client = preload("res://scripts/llm_client.gd")
const World = preload("res://scripts/immersive_core.gd")

var client: DemoLLMClient
var world: ImmersiveCore
var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var saved := Store.operate("load")
	if not saved.get("ok", false):
		push_error("Saved profile could not be decrypted")
		quit(1)
		return
	var profile: Dictionary = saved["profile"]
	if not profile.get("allow_development_tests", false):
		push_error("Live development testing is disabled in the saved profile")
		quit(1)
		return
	client = Client.new()
	root.add_child(client)
	await process_frame
	var temperature := -1.0 if str(profile.get("temperature", "")).strip_edges().is_empty() else float(profile["temperature"])
	# Keep a per-call cap for this quality sample; this does not change the saved setting.
	client.configure(str(profile.get("api_key", "")), str(profile.get("model", "")), str(profile.get("base_url", "")), str(profile.get("endpoint", "")), "chat_completions" if int(profile.get("protocol", 0)) == 1 else "responses", temperature, 4000, float(profile.get("timeout", "45")), str(profile.get("organization", "")), str(profile.get("extra_headers", "")), false, "max_completion_tokens" if int(profile.get("chat_token", 0)) == 1 else "max_tokens")
	world = World.new()
	world.next_guest()
	world.reveal_opening()
	await ask("客人刚刚进店。", str(world.current_guest["opening_fact"]), "卖家开场")
	var words := "我先看看这件东西的来历和修补情况。"
	world.remember_line("player", words)
	var result := world.dispatch("source")
	await ask(words, str(result["llm_instruction"]), "卖家来源追问")
	result = world.dispatch("appraise")
	await ask("我再仔细看看器物。", str(result["llm_instruction"]), "掌柜内心鉴定", "inner")
	var amount := int(world.current_guest["min_price"])
	var money_before := world.money
	world.remember_line("player", "我出%d元。" % amount)
	result = world.dispatch("offer", {"amount": amount})
	await ask("我出%d元。" % amount, str(result["llm_instruction"]), "卖家议价")
	result = world.dispatch("confirm_trade")
	if not world.pending_trade.is_empty() or world.money != money_before - amount:
		failures.append("Confirm should settle through Core without another NPC claim")
	# The same actor remains available in memory for a revisit-style continuity sample.
	var context := world.dialogue_context()
	world.remember_line("player", "你刚才提到的老宅，是哪一处？")
	result = world.dispatch("source")
	await ask("你刚才提到的老宅，是哪一处？", str(result["llm_instruction"]), "同一人物连续追问")
	if not context.contains("来历") and not world.dialogue_context().contains("老宅"):
		failures.append("Dialogue memory did not retain prior seller context")
	world.next_guest()
	world.reveal_opening()
	await ask("客人刚刚进店。", str(world.current_guest["opening_fact"]), "买家开场")
	result = world.dispatch("need")
	await ask("您想找什么类别、预算大概多少？", str(result["llm_instruction"]), "买家需求")
	world.select_item("inkstone")
	result = world.dispatch("recommend")
	await ask("您看看这方旧端砚。", str(result["llm_instruction"]), "买家看货")
	world.phase = "closing"
	world.current_guest = {}
	world.flags["ledger"] = true
	world.meet_at_night("zhou")
	result = world.dispatch("social", {"topic": "story"})
	await ask("晚上好，我想问问爷爷留下的旧账。", str(result["llm_instruction"]), "夜间故事交流")
	if not failures.is_empty():
		for failure in failures: push_error(failure)
		quit(1)
		return
	print("PASS: live dialogue quality sample completed; outputs above are from the saved profile with DeepSeek thinking disabled and capped at 4000 tokens per call")
	quit(0)

func ask(player_text: String, instruction: String, label: String, speaker := "npc") -> void:
	var actor := world.active_actor()
	var voice := str(actor.get("personality", ""))
	var person := world.person(str(actor.get("id", "")))
	if not person.is_empty(): voice = str(person.get("voice", voice))
	client.request_npc_reply(str(actor.get("name", "客人")), voice, player_text, instruction + "\n场景：" + world.location + "\n" + world.dialogue_context(), [], speaker)
	var response: Array = await client.response_ready
	if not response[0]:
		push_error("%s failed: %s" % [label, response[2]])
		failures.append(label)
		return
	var text := str(response[1]).strip_edges()
	print("\n[%s]\n%s" % [label, text])
	if text.is_empty(): failures.append(label + " returned empty text")
	if speaker == "npc": world.remember_line("npc", text)
