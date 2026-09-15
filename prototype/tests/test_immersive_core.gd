extends SceneTree
const World = preload("res://scripts/immersive_core.gd")
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
	if not value: failures.append(label)

func _init() -> void:
	var world = World.new()
	var merchants: Array = world.market_merchants()
	check(merchants.size() >= 7 and merchants.size() <= 9, "Four fixed shops plus 3-5 stalls")
	var ids := {}
	for merchant in merchants:
		var stock: Array = world.merchant_stock(merchant["id"])
		check(stock.size() >= 5 and stock.size() <= 8, "5-8 listings per merchant")
		for item in stock:
			check(not ids.has(item["id"]), "Unique physical object id across market")
			ids[item["id"]] = true
	world.phase = "noon"
	check(world.travel("market"), "Can go to market in safe phase")
	check(world.enter_merchant("qingshan"), "Enter fixed merchant")
	var item: Dictionary = world.merchant_stock("qingshan")[0]
	check(world.view_merchant_item(item["id"]), "Select actual merchant item")
	world.visit["patience"] = 5
	world.dispatch("source")
	var remaining: int = world.visit["patience"]
	world.travel("market")
	world.enter_merchant("qingshan")
	world.view_merchant_item(item["id"])
	check(world.visit["patience"] == remaining and world.visit["revealed"].has("source"), "Reentry preserves patience and disclosed source")
	world.remember_line("player", "我上次谈过这件的修补情况，想再核实来源。")
	world.dispatch("appraise")
	var money: int = world.money
	var count: int = world.inventory.size()
	world.dispatch("offer", {"amount": item["minimum"]})
	check(not world.pending_trade.is_empty() and world.money == money and world.inventory.size() == count, "Negotiated price does not transfer money/property")
	check(not world.travel("shop"), "Cannot hide pending transfer by switching scenes")
	world.dispatch("confirm_trade")
	check(world.money == money - int(item["minimum"]) and world.inventory.size() == count + 1, "Explicit confirm settles once")
	world.dispatch("confirm_trade")
	check(world.inventory.size() == count + 1, "Duplicate confirm cannot duplicate item")
	var after: int = world.merchant_stock("qingshan").size()
	world.travel("market")
	world.enter_merchant("qingshan")
	check(world.merchant_stock("qingshan").size() == after, "Reentry does not refresh stock")
	check(world.dialogue_context().contains("修补情况"), "Merchant remembers prior utterance on revisit")
	var old_meeting_key := world.active_meeting_key()
	world.save_game("user://test_immersive_save.json")
	var loaded = World.new()
	check(loaded.load_game("user://test_immersive_save.json") == OK, "Reload world with market stock")
	check(loaded.money == world.money and loaded.merchant_stock("qingshan").size() == after, "Stock and money consistent after reload")
	check(loaded.dialogue_context().contains("修补情况"), "Conversation memory survives reload")
	loaded.day += 1
	check(not loaded.dialogue_context().contains("修补情况"), "Raw dialogue from an earlier meeting cannot leak into a new day")
	loaded.day -= 1
	check(loaded.active_meeting_key() == old_meeting_key, "Meeting identity remains deterministic across save/load")
	world.travel("shop")
	world.phase = "closing"
	world.flags["ledger"] = true
	check(world.meet_at_night("zhou"), "Known ledger enables Zhou nighttime visit")
	var result: Dictionary = world.dispatch("social", {"topic": "story"})
	check(not result["llm_instruction"].is_empty(), "Nighttime supplies actual authorized dialogue")
	world.selected_item_id = "inkstone"
	check(world.dispatch("appraise_inventory").get("speaker") == "inner", "Night viewing remains private")
	check(not world.dialogue_context().contains("真品可能性"), "Private appraisal is not shared with NPC")
	var shown: Dictionary = world.dispatch("show_item", {"item_id": "inkstone"})
	check(shown.get("speaker", "npc") != "system" and world.visit["seen_items"].has("inkstone"), "Night companion receives explicitly shown item")
	check(not shown["llm_instruction"].contains("真品可能性"), "Shared viewing does not disclose private probability")
	check(world.investigation_rows().size() >= 3, "Evidence creates next visible investigation questions")
	world.reset()
	world.next_guest()
	check(world.trade_role_contract(world.current_guest, "offer").contains("掌柜是买方"), "Seller contract fixes money and property direction")
	world.reveal_opening()
	world.dispatch("decline")
	world.next_guest()
	check(world.trade_role_contract(world.current_guest, "offer").contains("掌柜是卖方") or world.trade_role_contract(world.current_guest, "offer").contains("掌柜是店主"), "Buyer contract keeps the player as shop owner")
	world.reveal_opening()
	world.dispatch("need")
	world.select_item("inkstone")
	var opening_before := world.recommendation_opening(world.get_inventory_item("inkstone"))
	world.dispatch("recommend")
	world.dispatch("appraise_inventory")
	var opening_after := world.recommendation_opening(world.get_inventory_item("inkstone"))
	check(opening_before != opening_after, "Buyer introduction refreshes when the player's current judgement changes")
	check(not opening_after.contains("%"), "Buyer introduction translates private probability into natural uncertainty")
	world.current_guest["last_question"] = "这件东西的修补和品相怎么说？"
	var drafts: Array = world.contextual_answers()
	check(drafts.size() == 3 and str(drafts[2]).contains("修"), "Condition question yields condition-oriented answers")
	for draft in drafts:
		check(not str(draft).contains("%"), "Buyer-facing suggestions keep private appraisal probability private")
	world.current_guest["last_question"] = "来历有记录吗？"
	check(str(world.contextual_answers()[0]).contains("记录"), "Source question yields source-oriented answer")
	var story_prompt_data: Dictionary = world.revision_content.get("story_prompts", {})
	var story_actors := {}
	for node in world.content.get("story_nodes", []):
		var node_id := str(node.get("id", ""))
		var actor_id := str(node.get("actor", ""))
		check(story_prompt_data.has(node_id), "Every story node has a conversational prompt")
		story_actors[actor_id] = true
	for actor_id in story_actors.keys():
		world.contacts[actor_id]["met"] = true
		check(not world.story_prompt_actions(str(actor_id)).is_empty(), "Every story NPC has a prompt shortcut")
	var auction_world = World.new()
	auction_world.day = 3
	auction_world.phase = "noon"
	var sale: Dictionary = auction_world.auction_preview()
	check(sale.get("lots", []).size() >= 6 and sale.get("lots", []).size() <= 8, "Auction preview contains 6-8 lots")
	for lot in sale.get("lots", []):
		check(lot.get("rivals", []).size() >= 2 and lot.get("rivals", []).size() <= 4, "Each lot exposes 2-4 observable rivals")
	var first_lot: Dictionary = sale["lots"][0]
	check(auction_world.mark_auction_lot(first_lot["item_id"]), "Preview lot can be marked")
	check(auction_world.inspect_outside(first_lot["item_id"]).get("speaker") == "inner", "Preview lot supports private inspection")
	check(auction_world.start_auction() and auction_world.current_auction_lot()["item_id"] == first_lot["item_id"], "Auction starts from first catalogue lot")
	var rival_limit := int(auction_world.current_auction_lot()["rival_limit"])
	var inventory_before: int = auction_world.inventory.size()
	auction_world.bid(rival_limit + 1)
	check(auction_world.inventory.size() == inventory_before + 1 and int(auction_world.auction["current_index"]) == 1, "Winning one lot settles once and advances")
	if failures.is_empty(): print("PASS: immersive merchant breadth, unique stock, confirm-only settlement, scene memory, save/load, night discussion and question-aware drafts")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
