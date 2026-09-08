class_name ImmersiveCore
extends ChapterCore

var revision_content: Dictionary = {}
var location := "shop"
var merchants: Dictionary = {}
var market_day := 0
var visit: Dictionary = {}
var dialogue_memory: Dictionary = {}
var pending_trade: Dictionary = {}
var private_notes: Array = []
var notices: Array = []
var prologue_seen := false
var visit_subject := ""
var visit_origin := ""
var meeting_memory: Dictionary = {}
var market_seed: int = 0

func reset() -> void:
	super.reset()
	revision_content = JSON.parse_string(FileAccess.get_file_as_string("res://data/immersive_content.json"))
	location = "shop"
	merchants = {}
	market_day = 0
	visit = {}
	dialogue_memory = {}
	pending_trade = {}
	private_notes = []
	notices = []
	prologue_seen = false
	visit_subject = ""
	visit_origin = ""
	meeting_memory = {}
	market_seed = randi()
	_build_market()

func _remember_meeting() -> void:
	if not visit.is_empty(): meeting_memory["%d:%s" % [day, visit["id"]]] = visit

func _build_market() -> void:
	if market_day == day: return
	market_day = day
	for merchant in merchants.values(): merchant["present"] = false
	var catalog: Array = revision_content["fixed_merchants"].duplicate(true)
	var daily_rng := RandomNumberGenerator.new()
	daily_rng.seed = market_seed + day * 7919
	var stall_count := daily_rng.randi_range(3, 5)
	var categories := ["瓷器", "书画", "文房", "杂项"]
	var names := [0, 1, 2, 3, 4]
	for index in range(stall_count):
		var name_index: int = names.pop_at(daily_rng.randi_range(0, names.size() - 1))
		catalog.append({"id": "stall_%d_%d" % [day, index], "name": revision_content["stall_names"][name_index], "owner": revision_content["stall_owners"][name_index], "category": categories[daily_rng.randi_range(0, 3)], "portrait": name_index, "description": "今日临时摆摊，货源说法需要逐件核对；明天未必还在原位。", "voice": "自然随和，只介绍眼前这批货，不保证没有凭据的来历"})
	for source in catalog:
		var id := str(source["id"])
		if not merchants.has(id):
			merchants[id] = source.duplicate(true)
			merchants[id]["stock"] = []
		var merchant: Dictionary = merchants[id]
		merchant["present"] = true
		if not contacts.has(id): contacts[id] = {"met": false, "relation": 0, "memories": []}
		var stock: Array = merchant["stock"]
		var available := 0
		for item in stock:
			if item["location"] == "unseen": available += 1
		var target := daily_rng.randi_range(5, 8)
		var candidates: Array = []
		var side_items: Array = []
		for item in content["items"]:
			if item["category"] == source["category"] and not item.get("custody", false): candidates.append(item)
			elif not item.get("custody", false): side_items.append(item)
		var pick_offset := daily_rng.randi_range(0, candidates.size() - 1)
		for index in range(maxi(0, target - available)):
			var template: Dictionary = candidates[(pick_offset + index) % candidates.size()]
			if index % 4 == 3 and not side_items.is_empty():
				template = side_items[daily_rng.randi_range(0, side_items.size() - 1)]
			var item := template.duplicate(true)
			item["id"] = "%s_%d_%d" % [id, day, stock.size()]
			item["title"] = template["title"].trim_prefix("市集")
			item["public_provenance"] = ""
			item["source_claim"] = "这件是前些日子从旧物交易中收到的，没有完整的历代流传凭据。"
			item["provenance"] = item["source_claim"]
			item["era"] = "尚待判断"
			item["clue_rules"] = item["clues"].duplicate(true)
			item["clues"] = []
			item["revealed_clues"] = []
			item["appraised"] = false
			item["judged_fake"] = false
			item["probability"] = int(item["prior"])
			item["assessment_level"] = -1
			item["cost"] = 0
			item["location"] = "unseen"
			item["ask"] = int(item["ask"]) + ((day + index) % 4) * 30
			stock.append(item)

func market_merchants() -> Array:
	_build_market()
	var result: Array = []
	for merchant in merchants.values():
		if merchant["present"]: result.append(merchant)
	return result

func merchant_stock(id: String) -> Array:
	var result: Array = []
	for item in merchants.get(id, {}).get("stock", []):
		if item["location"] == "unseen": result.append(item)
	return result

func travel(destination: String) -> bool:
	if not pending_trade.is_empty(): return false
	_remember_meeting()
	if destination == "shop":
		visit = {}
		location = "shop"
		visit_subject = ""
		visit_origin = ""
		# Items shown to someone outside are put back on the shelf when the
		# shopkeeper returns; they must not reappear on the counter by themselves.
		selected_item_id = ""
		return true
	if not can_go_out(): return false
	if destination == "tea" and phase != "closing": return false
	if destination not in ["market", "tea", "visits", "auction"]: return false
	visit = {}
	location = destination
	visit_subject = ""
	return true

func enter_merchant(id: String) -> bool:
	if not can_go_out() or not pending_trade.is_empty() or not merchants.has(id) or not merchants[id]["present"]: return false
	_remember_meeting()
	var merchant: Dictionary = merchants[id]
	location = "merchant:" + id
	contacts[id]["met"] = true
	visit_subject = id
	var remembered := "%d:%s" % [day, id]
	if meeting_memory.has(remembered):
		visit = meeting_memory[remembered]
		return true
	visit = {"id": id, "name": merchant["owner"], "portrait_index": merchant["portrait"], "role": "social", "role_revealed": true, "completed": false, "patience": 8, "facts": {}, "revealed": {}, "asked": {}, "shared": {}, "seen_items": [], "offended": false, "apology_used": false, "personality": merchant["voice"], "outcome": "看店"}
	return true

func view_merchant_item(id: String) -> bool:
	if not location.begins_with("merchant:") or not pending_trade.is_empty(): return false
	for item in merchant_stock(visit_subject):
		if item["id"] != id: continue
		if visit.get("item", {}).get("id") == id: return true
		if not visit.has("item_sessions"): visit["item_sessions"] = {}
		if visit.has("item"):
			visit["item_sessions"][visit["item"]["id"]] = {"revealed": visit["revealed"], "asked": visit["asked"], "ask_price": visit["ask_price"], "completed": visit["completed"]}
		visit["role"] = "seller"
		visit["item"] = item
		visit["completed"] = false
		visit["ask_price"] = int(item["ask"])
		visit["min_price"] = int(item["minimum"])
		visit["facts"] = {"source": item["source_claim"], "repair": "没有完整修护记录，您可以先检查实物。", "price": "这件要价¥%d。" % int(item["ask"]), "motive": merchants[visit_subject]["description"]}
		visit["revealed"] = {}
		visit["asked"] = {}
		if visit["item_sessions"].has(id):
			for key in visit["item_sessions"][id]: visit[key] = visit["item_sessions"][id][key]
		return true
	return false

func night_people() -> Array:
	var result: Array = []
	if phase != "closing": return result
	for id in ["zhou", "sun", "xu", "he", "chen"]:
		if contacts[id]["met"] or (id == "zhou" and flags.has("ledger")):
			result.append(person(id))
	return result

# The teahouse and private visits are different places now: whoever sits in the
# teahouse tonight is data-driven, everyone else must be visited at home.
func teahouse_people() -> Array:
	var result: Array = []
	var schedule: Dictionary = revision_content.get("teahouse_schedule", {})
	for actor in night_people():
		var days: Array = schedule.get(str(actor["id"]), [])
		if days.has(day): result.append(actor)
	return result

func visit_people() -> Array:
	var result: Array = []
	var at_tea: Array[String] = []
	for actor in teahouse_people(): at_tea.append(str(actor["id"]))
	for actor in night_people():
		if str(actor["id"]) not in at_tea: result.append(actor)
	return result

func teahouse_event() -> String:
	for event in revision_content.get("teahouse_events", []):
		if int(event.get("day", -1)) == day: return str(event.get("text", ""))
	return ""

func story_actor_ids() -> Array[String]:
	var result: Array[String] = []
	for node in content.get("story_nodes", []):
		var actor_id := str(node.get("actor", ""))
		if not actor_id.is_empty() and actor_id not in result: result.append(actor_id)
	return result

# "Has a storyline" means the person is attached to any story node, whether or
# not a node is currently actionable. Story people get a real conversation;
# anyone else gets a short canned visit and the evening ends there.
func has_story_for(actor_id: String) -> bool:
	return actor_id in story_actor_ids()

func story_nodes_for(actor_id: String) -> Array:
	var result: Array = []
	for node in available_story():
		if str(node.get("actor", "")) == actor_id: result.append(node)
	return result

func casual_visit_line(actor_id: String) -> String:
	var lines: Dictionary = revision_content.get("visit_lines", {})
	return str(lines.get(actor_id, lines.get("default", "对方招呼你坐下喝了盏茶，说了些街坊近况，没有谈及旧账。")))

func meet_at_night(id: String, origin := "visits") -> bool:
	if not can_go_out() or phase != "closing" or not pending_trade.is_empty(): return false
	var permitted := false
	for actor in night_people():
		if actor["id"] == id: permitted = true
	if not permitted: return false
	_remember_meeting()
	var actor := person(id)
	location = "night:" + id
	visit_subject = id
	visit_origin = origin
	contacts[id]["met"] = true
	var remembered := "%d:%s" % [day, id]
	if meeting_memory.has(remembered):
		visit = meeting_memory[remembered]
		return true
	visit = {"id": id, "name": actor["name"], "portrait_index": actor["portrait"], "role": "social", "role_revealed": true, "completed": false, "patience": 8, "facts": {}, "revealed": {}, "asked": {}, "shared": {}, "seen_items": [], "personality": actor["voice"], "offended": false, "apology_used": false, "outcome": "夜间交流"}
	return true

func active_actor() -> Dictionary:
	return visit if not visit.is_empty() else current_guest

func active_item() -> Dictionary:
	var actor := active_actor()
	if actor.get("role") == "seller": return actor.get("item", {})
	return get_inventory_item(str(actor.get("recommended_item_id", selected_item_id)))

func remember_line(role: String, text: String) -> void:
	var actor := active_actor()
	if actor.is_empty() or role not in ["player", "npc"]: return
	var id := str(actor["id"])
	if not dialogue_memory.has(id): dialogue_memory[id] = []
	dialogue_memory[id].append({"day": day, "location": location, "role": role, "text": text, "item_id": str(active_item().get("id", ""))})
	if role == "npc" and (text.contains("？") or text.contains("?")):
		actor["last_question"] = text

func interpret_utterance(words: String, is_answer := false) -> Dictionary:
	var actor := active_actor()
	if words in ["不买", "不收", "不卖", "不卖了", "不买了", "算了", "下次再聊", "先不看了", "不成交"]:
		return {"action": "decline"}
	if actor.get("role") == "social":
		var topic := "greeting"
		if _contains_any(words, ["上次", "今天", "交易", "记得"]): topic = "trade"
		if _contains_any(words, ["爷爷", "旧账", "照片", "存根", "寄存"]): topic = "story"
		if _contains_any(words, ["鉴定", "怎么判断", "工艺", "年代", "看货"]): topic = "method"
		return {"action": "social", "topic": topic}
	var amount := _extract_number(words)
	if amount > 0 and _contains_any(words, ["我出", "报价", "出价", "卖你", "卖给", "给您", "收下", "元", "块"]):
		# Historical prices and provenance numbers are not current offers.
		if not _contains_any(words, ["以前", "上次", "去年", "买来", "购入", "成本", "记录"]):
			return {"action": "offer", "amount": amount}
	var question := words.ends_with("？") or words.ends_with("?") or words.begins_with("请问") or words.begins_with("您") or words.begins_with("你")
	if actor.get("role") == "buyer" and actor.has("recommended_item_id") and (is_answer or not question):
		return {"action": "respond", "text": words}
	if _contains_any(words, ["为什么卖", "急着卖", "出手", "动机"]): return {"action": "motive"}
	var original := current_guest
	current_guest = actor
	var action := classify_free_text(words)
	current_guest = original
	return action

func contextual_answers() -> Array[String]:
	var actor := active_actor()
	var item := active_item()
	if item.is_empty(): return []
	var question := str(actor.get("last_question", actor.get("question", "")))
	var source := str(item.get("public_provenance", ""))
	var clues: Array = item.get("revealed_clues", [])
	if _contains_any(question, ["来历", "来源", "记录", "哪来"]):
		var answer := "我手上的记录是“%s”。再早的来历，我还没有核实。" % source if not source.is_empty() else "这件的来历我还没有核实，不能给您编一个传承故事。"
		return [answer, "您最想确认的是从哪里收来的，还是以前谁用过？我按已有记录给您找。", "这部分凭据还不齐，您可以先不急着决定。"]
	if _contains_any(question, ["品相", "修", "磕", "缺", "伤"]):
		return ["我目前看到的是：%s。没看清的部位，还得再核对。" % ("；".join(clues) if not clues.is_empty() else "还没有完整检查记录"), "您在意哪一处？我把那一面拿近些，我们一起看。", "我不能保证它从没修过，现有记录没有把这件事说清。"]
	var assessment := "我还没有完成这件的判断，不急着给您下结论。"
	if item["appraised"]:
		assessment = "我发现了与原说法矛盾的关键痕迹，所以不再按真品介绍。" if item["judged_fake"] else "我的把握大约是%d%%，依据是%s；这还不是保证。" % [int(item["probability"]), "；".join(clues)]
	return [assessment, "我可以把已经看到的线索逐项讲清，没依据的部分先留着。", "您更关心年代、品相还是来源？我分别说，不混在一起保证。"]

func dialogue_context() -> String:
	var actor := active_actor()
	if actor.is_empty(): return ""
	var lines: Array[String] = []
	for entry in dialogue_memory.get(actor["id"], []).slice(-30):
		lines.append("第%d日 %s %s：%s" % [int(entry["day"]), entry["location"], "掌柜原话" if entry["role"] == "player" else "你的原话", entry["text"]])
	lines.append("过往原话是说法记录，不自动等于客观真相。只延续本人的记忆，不访问其他人物私聊。")
	var original := current_guest
	current_guest = actor
	var public_state := public_dialogue_context()
	current_guest = original
	return "\n".join(lines) + "\n" + public_state

func dispatch(action: String, payload: Dictionary = {}) -> Dictionary:
	var actor := active_actor()
	if actor.is_empty(): return _result("当前没有交谈对象。", "", false, {"speaker": "system"})
	if not pending_trade.is_empty() and action not in ["confirm_trade", "cancel_trade"]:
		return _result("请先确认或取消当前钱货交割。", "", false, {"speaker": "system"})
	if action == "cancel_trade":
		pending_trade = {}
		return _result("已取消交割，没有扣款或转移物件。", "掌柜取消这笔交割，尚未成交。", false)
	if action == "offer":
		var amount := int(payload.get("amount", 0))
		if amount <= 0: return _result("请给出具体金额。", "", false, {"speaker": "system"})
		if actor["role"] == "seller":
			if not actor["item"]["appraised"]: return _result("先鉴定再提出收购。", "", false, {"speaker": "system"})
			if amount > money: return _result("资金不足，无法交割。", "", false, {"speaker": "system"})
			if amount >= int(actor["min_price"]):
				pending_trade = {"actor": actor["id"], "item": actor["item"]["id"], "amount": amount}
		elif actor["role"] == "buyer":
			var item := active_item()
			if not item.is_empty() and not item.get("custody", false) and actor["revealed"].has("need") and get_match_level(item, actor) == "exact" and amount <= int(actor["need"]["max_price"]):
				pending_trade = {"actor": actor["id"], "item": item["id"], "amount": amount}
		if not pending_trade.is_empty():
			return _result("双方价格已谈妥，尚未交割。", "可以接受¥%d。自然确认这个价格，等待掌柜最终确认钱货交割，不能说已经付款或离店。" % amount, false, {"trade_pending": true})
	if action == "confirm_trade":
		if pending_trade.is_empty() or pending_trade["actor"] != actor["id"] or pending_trade["item"] != active_item().get("id"):
			return _result("已无有效的待确认交割。", "", false, {"speaker": "system"})
		payload = {"amount": int(pending_trade["amount"])}
		pending_trade = {}
		action = "offer"
	if action == "story_prompt":
		var prompt := str(payload.get("prompt", "我想把已经取得的剧情记录再核对一遍。"))
		var node_id := str(payload.get("node_id", ""))
		var node_title := ""
		for node in content.get("story_nodes", []):
			if str(node.get("id", "")) == node_id:
				node_title = str(node.get("title", ""))
		var focus := ""
		if not node_title.is_empty(): focus = "当前聚焦节点：%s。" % node_title
		return _result("本轮交谈聚焦：%s" % (node_title if not node_title.is_empty() else "已取得的记录"), revision_content["night_topics"]["story"] + "\n" + focus + "\n玩家的具体问题是：" + prompt + "\n只回答已经授权的记录，不替玩家完成剧情选择，不凭空补写新事实。", false)
	if actor["role"] == "social":
		if action == "decline":
			actor["completed"] = true
			return _result("本次交谈结束。", "回应道别，今晚先聊到这里。", true)
		if action == "show_item":
			var item := get_inventory_item(str(payload.get("item_id", "")))
			if item.is_empty(): return _result("请先选择自己库存里的物件。", "", false, {"speaker": "system"})
			actor["recommended_item_id"] = item["id"]
			if item["id"] not in actor["seen_items"]: actor["seen_items"].append(item["id"])
			actor["shared"][item["id"]] = {"description": item["description"]}
			return _result("已把实物拿给对方看，私人鉴定没有自动告知。", "掌柜拿出《%s》，类别%s，眼前外观：%s。回应共同看货邀请，仅讨论这些可见特征，不编造鉴定结论。" % [item["title"], item["category"], item["description"]], false)
		if action == "appraise_inventory":
			return _appraise_item(get_inventory_item(selected_item_id), "夜间自行验货")
		var topic := str(payload.get("topic", "greeting"))
		var instruction: String = revision_content["night_topics"].get(topic, revision_content["night_topics"]["greeting"])
		return _result("", instruction + "根据掌柜刚才的话真正回应；若不知道就说不知道，不要每次重置为打招呼。", false)
	var original := current_guest
	current_guest = actor
	if actor["role"] == "seller" and action == "offer": all_items[actor["item"]["id"]] = actor["item"]
	var result := super.process_action(action, payload)
	current_guest = original
	return result

func investigation_rows() -> Array:
	var result: Array = []
	for source in revision_content["investigation"]:
		var ready := true
		for flag in source["requires"]:
			if not flags.has(flag): ready = false
		if ready:
			var row: Dictionary = source.duplicate(true)
			row["done"] = flags.has(source["resolved_by"])
			result.append(row)
	return result

func story_prompt_actions(actor_id: String) -> Array:
	"""Return optional, data-backed prompts for every story-relevant NPC.

	These prompts only point at an already available question. They do not
	resolve a node or reveal its answer; the normal story choice remains under
	the player's control in the investigation view.
	"""
	var result: Array = []
	var prompts: Dictionary = revision_content.get("story_prompts", {})
	for node in content.get("story_nodes", []):
		if str(node.get("actor", "")) != actor_id: continue
		if int(node.get("day", 1)) > day or resolved_nodes.has(node.get("id", "")): continue
		if outside.has("defer_" + str(node.get("id", ""))): continue
		var ready := true
		for requirement in node.get("requires", []):
			if not flags.has(requirement): ready = false
		if not ready: continue
		var node_id := str(node["id"])
		var prompt_text := str(prompts.get(node_id, "我想谈谈这件旧账线索，请你把已知的部分说明白。"))
		result.append({"node_id": node_id, "label": "剧情 · " + str(node["title"]), "text": prompt_text})
	if result.is_empty() and actor_id in ["zhou", "sun", "xu", "he", "chen"] and contacts.get(actor_id, {}).get("met", false):
		result.append({"node_id": "", "label": "回顾已取得的剧情记录", "text": "我想把我们之前谈过的旧账线索再捋一遍，只说已经确认的部分。"})
	return result

func save_game(path: String = "user://chapter_save.json") -> Error:
	_remember_meeting()
	ui_state["meeting_memory"] = meeting_memory
	ui_state["market_seed"] = market_seed
	ui_state["immersive"] = {"location": location, "merchants": merchants, "market_day": market_day, "visit": visit, "visit_subject": visit_subject, "visit_origin": visit_origin, "dialogue_memory": dialogue_memory, "pending_trade": pending_trade, "private_notes": private_notes, "notices": notices, "prologue_seen": prologue_seen}
	return super.save_game(path)

func load_game(path: String = "user://chapter_save.json") -> Error:
	# Validate base save against its canonical original schema, not later runtime additions.
	var previous_items := all_items
	var previous_contacts := contacts
	var baseline := ChapterCore.new()
	all_items = baseline.all_items
	contacts = baseline.contacts
	var error := super.load_game(path)
	if error != OK:
		all_items = previous_items
		contacts = previous_contacts
		return error
	var extra: Dictionary = ui_state.get("immersive", {})
	meeting_memory = ui_state.get("meeting_memory", {})
	market_seed = int(ui_state.get("market_seed", market_seed))
	if extra.is_empty():
		location = "shop"
		visit = {}
		market_day = 0
		_build_market()
		return OK
	for key in ["location", "merchants", "market_day", "visit", "visit_subject", "visit_origin", "dialogue_memory", "pending_trade", "private_notes", "notices", "prologue_seen"]:
		if extra.has(key): set(key, extra[key])
	for merchant in merchants.values():
		for index in range(merchant["stock"].size()):
			var item: Dictionary = merchant["stock"][index]
			if all_items.has(item["id"]): merchant["stock"][index] = all_items[item["id"]]
	if visit.has("item"):
		for merchant in merchants.values():
			for item in merchant["stock"]:
				if item["id"] == visit["item"]["id"]: visit["item"] = item
	for meeting in meeting_memory.values():
		if not meeting.has("item"): continue
		for merchant in merchants.values():
			for item in merchant["stock"]:
				if item["id"] == meeting["item"]["id"]: meeting["item"] = item
	return OK
