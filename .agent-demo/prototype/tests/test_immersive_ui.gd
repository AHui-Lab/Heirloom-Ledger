extends SceneTree

class LocalReply extends DemoLLMClient:
	func request_npc_reply(_name: String, _personality: String, _player: String,
			_instruction: String, _history: Array[String], speaker: String = "npc") -> Error:
		response_ready.emit.call_deferred(true, "我再仔细看看。" if speaker == "inner" else "好的，这件我们慢慢说。", "")
		return OK

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://immersive.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.is_test_mode = true
	scene.sound_enabled = false
	scene.motion_enabled = false
	scene.llm.queue_free()
	var stub := LocalReply.new()
	scene.add_child(stub)
	scene.llm = stub
	stub.response_ready.connect(scene._on_llm_response)
	scene._begin_day()
	await process_frame
	await process_frame
	if scene.chat_toggle == null or scene.meeting_panel == null or scene.history_toggle == null:
		push_error("Immersive conversation must expose collapse, meeting summary and history controls")
		quit(1)
		return
	if scene.price_spin.step != 1:
		push_error("Trade price input must support exact integer values")
		quit(1)
		return
	scene.chat_toggle.pressed.emit()
	await process_frame
	if scene.conversation_panel.visible:
		push_error("Dialogue panel collapse toggle must hide the conversation panel")
		quit(1)
		return
	scene.chat_toggle.pressed.emit()
	scene.history_toggle.pressed.emit()
	if scene.history_visible:
		push_error("History toggle must switch to the compact conversation view")
		quit(1)
		return
	scene.history_toggle.pressed.emit()
	scene._perform_action("appraise", {}, "看看。")
	await process_frame
	var before: int = scene.world.money
	var amount: int = scene.world.current_guest["min_price"]
	scene._perform_action("offer", {"amount": amount}, "我出%d元。" % amount)
	await process_frame
	if scene.world.money != before or not scene.confirming_button.visible:
		push_error("Offer must show confirmation without transferring money")
		quit(1)
		return
	scene.confirming_button.pressed.emit()
	await process_frame
	if scene.world.money != before - amount:
		push_error("Confirmation button must settle the agreed price")
		quit(1)
		return
	var count := 0
	while scene.world.day <= 10 and count < 100:
		count += 1
		if scene.world.current_guest.is_empty():
			if not scene.continue_button.is_visible_in_tree():
				push_error("Day progression must remain visible when there is no conversation")
				quit(1)
				return
			if scene.world.day == 10 and scene.world.phase == "closing": break
			if scene.world.phase == "noon":
				scene._go("market")
				scene._go("shop")
				if not scene.continue_button.is_visible_in_tree():
					push_error("Returning from market must restore afternoon continuation")
					quit(1)
					return
			scene.continue_button.pressed.emit()
		elif scene.world.current_guest.get("completed", false):
			scene.continue_button.pressed.emit()
		else:
			scene._perform_action("decline", {}, "今天先不成交。")
		await process_frame
		await process_frame
	if scene.world.day != 10 or scene.world.phase != "closing":
		push_error("Immersive scene did not reach day 10 closing")
		quit(1)
		return
	scene.world.reset()
	scene.world.phase = "noon"
	scene._go("market")
	var market_entries := 0
	var shop_entry: Button
	for child in scene.stage.get_children():
		if child.has_meta("merchant_id"):
			market_entries += 1
			if child.get_meta("merchant_id") == "qingshan": shop_entry = child
	if market_entries != scene.world.market_merchants().size() or shop_entry == null:
		push_error("Every present shop/stall must have a scene entrance")
		quit(1)
		return
	shop_entry.pressed.emit()
	await process_frame
	if scene.stock_grid.columns != 3 or scene.scene_scroll.anchor_top > .3:
		push_error("Merchant inventory must use a large three-column grid")
		quit(1)
		return
	var item: Dictionary = scene.world.merchant_stock("qingshan")[0]
	scene.world.view_merchant_item(item["id"])
	scene._item_modal(item)
	var bid := find_button(scene.modal_body, "向店家出价 / 还价")
	if bid == null or not bid.disabled:
		push_error("Merchant detail must show bidding, disabled until appraisal")
		quit(1)
		return
	find_button(scene.modal_body, "查看实物 · 形成私人判断").pressed.emit()
	await process_frame
	await process_frame
	scene._item_modal(item)
	var before_rejected_bid: int = scene.world.money
	for child in scene.modal_body.get_children():
		if child is SpinBox: child.get_line_edit().text = str(int(item["minimum"]) - 1)
	find_button(scene.modal_body, "向店家出价 / 还价").pressed.emit()
	await process_frame
	await process_frame
	if not scene.world.pending_trade.is_empty() or scene.world.money != before_rejected_bid:
		push_error("A rejected low offer must leave funds unchanged and permit further bargaining")
		quit(1)
		return
	scene._item_modal(item)
	var exact_amount := int(item["minimum"]) + 1
	for child in scene.modal_body.get_children():
		if child is SpinBox: child.get_line_edit().text = str(exact_amount)
	var market_before: int = scene.world.money
	find_button(scene.modal_body, "向店家出价 / 还价").pressed.emit()
	await process_frame
	await process_frame
	if not scene.confirming_button.is_visible_in_tree() or scene.world.money != market_before:
		push_error("Merchant bid must reveal an accessible confirmation without paying yet")
		quit(1)
		return
	scene.confirming_button.pressed.emit()
	await process_frame
	await process_frame
	if scene.world.money != market_before - exact_amount or scene.world.get_inventory_item(item["id"]).is_empty():
		print("Market diagnostic: before=", market_before, " after=", scene.world.money, " expected_quote=", exact_amount, " item_owned=", not scene.world.get_inventory_item(item["id"]).is_empty())
		push_error("Merchant confirmation must settle exact integer price and transfer the item")
		quit(1)
		return
	var settings = preload("res://scripts/profile_settings.gd")
	var dummy := settings.capture(scene)
	dummy["api_key"] = "dummy-a"
	dummy["base_url"] = "http://127.0.0.1:1"
	var alternate: Dictionary = dummy.duplicate(true)
	alternate["api_key"] = "dummy-b"
	alternate["model"] = "dummy-model-b"
	scene.set_meta("named_profiles", {"A": dummy, "B": alternate})
	if not settings.switch_to(scene, "B", true) or scene.api_key_edit.text != "dummy-b" or scene.model_edit.text != "dummy-model-b":
		push_error("Named profile switch must restore the selected model and credential")
		quit(1)
		return
	scene.awaiting_llm = true
	if settings.switch_to(scene, "A", true):
		push_error("An in-flight dialogue must not switch credentials")
		quit(1)
		return
	scene.awaiting_llm = false
	preload("res://scripts/profile_store.gd").operate("forget", {}, true)
	print("PASS: visible ten-day progression, collapse/history, market grid appraisal/bid/confirmed purchase, named protected profiles; no external requests")
	scene.queue_free()
	await process_frame
	quit(0)

func find_button(node: Node, caption: String) -> Button:
	if node is Button and node.text == caption: return node
	for child in node.get_children():
		var found := find_button(child, caption)
		if found != null: return found
	return null
