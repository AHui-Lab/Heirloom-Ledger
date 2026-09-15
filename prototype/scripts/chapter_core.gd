class_name ChapterCore
extends DemoGameCore

const CONTENT_PATH := "res://data/chapter_one.json"
var content: Dictionary = {}
var day := 1
var phase := "morning"
var contacts: Dictionary = {}
var skills: Dictionary = {}
var practice: Dictionary = {}
var flags: Dictionary = {}
var resolved_nodes: Array = []
var sold_items: Array = []
var consequences: Array = []
var outside: Dictionary = {}
var all_items: Dictionary = {}
var day_start_money := 3600
var day_ledger_start := 0
var chapter_ending := ""
var reputation_points: Dictionary = {}
var trust_points := 0
var recovery_day := 0
var auction: Dictionary = {}
var ui_state: Dictionary = {}

func reset() -> void:
	content = JSON.parse_string(FileAccess.get_file_as_string(CONTENT_PATH))
	day = 1
	phase = "morning"
	money = 3600
	knowledge = 42
	experience = 18
	global_trust = "尚无定论"
	day_start_money = money
	day_ledger_start = 0
	chapter_ending = ""
	trust_points = 0
	recovery_day = 0
	contacts = {}
	skills = {"瓷器": 36, "书画": 30, "文房": 42, "杂项": 34}
	practice = {"瓷器": 8, "书画": 6, "文房": 10, "杂项": 8}
	reputation_points = {"瓷器": 0, "书画": 0, "文房": 1, "杂项": 0}
	category_reputation = {}
	for category in skills:
		category_reputation[category] = "尚无名气"
	flags = {}
	resolved_nodes = []
	sold_items = []
	consequences = []
	outside = {}
	all_items = {}
	auction = {}
	ui_state = {}
	inventory = []
	ledger = []
	appraisal_history = []
	day_notes = []
	decisions = []
	for person in content["people"]:
		contacts[person["id"]] = {"relation": 0, "met": false, "memories": []}
	for source in content["items"]:
		var item: Dictionary = source.duplicate(true)
		item["era"] = "尚待判断"
		item["probability"] = int(source["prior"])
		item["provenance"] = source["source_claim"]
		item["public_provenance"] = ""
		item["cost"] = int(source["initial_cost"])
		item["clue_rules"] = source["clues"].duplicate(true)
		item["clues"] = []
		item["revealed_clues"] = []
		item["appraised"] = false
		item["judged_fake"] = false
		item["assessment_level"] = -1
		item["location"] = "unseen"
		all_items[item["id"]] = item
	for item_id in ["inkstone", "painting", "snuff", "brushpot"]:
		var item: Dictionary = all_items[item_id]
		item["location"] = "inventory"
		item["public_provenance"] = "旧账记录：" + str(item["source_claim"])
		inventory.append(item)
	_start_day()

func person(person_id: String) -> Dictionary:
	for entry in content["people"]:
		if entry["id"] == person_id:
			return entry
	return {}

func _start_day() -> void:
	current_index = -1
	current_guest = {}
	selected_item_id = ""
	phase = "morning"
	outside = {}
	auction = {}
	day_start_money = money
	day_ledger_start = ledger.size()
	guests = _build_guests()
	_resolve_discoveries()

func day_info() -> Dictionary:
	return content["days"][clampi(day - 1, 0, 9)]

func _build_guests() -> Array[Dictionary]:
	var schedule := day_info()
	var result: Array[Dictionary] = []
	for slot in range(4):
		var seller := slot % 2 == 0
		var pair := slot / 2
		var actor_id: String = schedule["sellers" if seller else "buyers"][int(pair)]
		var actor := person(actor_id)
		var guest := {"id": actor_id, "name": actor["name"], "portrait": actor["name"].left(1),
			"portrait_index": actor["portrait"], "subtitle": actor["identity"], "personality": actor["personality"],
			"role": "seller" if seller else "buyer", "period": MORNING if slot < 2 else AFTERNOON,
			"role_revealed": false, "opening_reveals": [], "opening_fact": actor["opening"],
			"patience": 6 + maxi(0, int(contacts[actor_id]["relation"]) / 3),
			"revealed": {}, "asked": {}, "completed": false, "outcome": "未处理",
			"challenge": slot < int(schedule["challenge_count"]), "content_roles": ["日常经营"],
			"hidden_state": actor["motive"], "missable": [actor["hint"]], "apology_used": false,
			"offended": false, "shared": {}, "seen_items": []}
		if seller:
			var item: Dictionary = all_items[schedule["items"][int(pair)]]
			guest["item"] = item
			guest["ask_price"] = int(item["ask"])
			guest["min_price"] = int(item["minimum"])
			guest["facts"] = {"source": item["source_claim"], "repair": "我手里没有完整修护记录，您还是仔细看看。", "price": "我想要¥%d，太低就先留着。" % guest["ask_price"], "motive": actor["public_motive"]}
			guest["opening_fact"] = "你是来出售的客人，向掌柜说：带来《%s》请看看，开价¥%d。还没有谈具体来源。" % [item["title"], guest["ask_price"]]
		else:
			var budget := int(actor["budget"]) + (day - 1) * 80
			guest["need"] = {"category": actor["category"], "era": "清末至民国", "public_budget": "约¥%d上下" % (int(budget * 0.8 / 100) * 100), "max_price": budget}
			guest["facts"] = {"need": "想找%s类的物件，合适的小件先看看。" % actor["category"], "purpose": actor["public_motive"], "budget": "大概¥%d上下，得看东西。" % (int(budget * 0.8 / 100) * 100), "era": "清末到民国的风格都愿意看看，不会只凭年代买。"}
			guest["opening_fact"] = "你是来购买的客人，对掌柜说：%s。不要替店主迎客，也不提前说隐藏用途或精确预算。" % actor["opening"]
		result.append(guest)
	return result

func next_guest() -> Dictionary:
	if not current_guest.is_empty() and not current_guest.get("completed", false):
		return current_guest
	if current_index == 1 and phase == "morning":
		phase = "noon"
		current_guest = {}
		return {}
	if current_index >= 3:
		phase = "closing"
		current_guest = {}
		return {}
	current_index += 1
	selected_item_id = ""
	current_guest = guests[current_index]
	contacts[current_guest["id"]]["met"] = true
	return current_guest

func continue_afternoon() -> void:
	if phase == "noon":
		phase = "afternoon"

func next_day() -> bool:
	if phase != "closing" or day >= 10:
		return false
	day += 1
	_start_day()
	return true

func reveal_opening() -> void:
	if not current_guest.is_empty():
		current_guest["role_revealed"] = true

func process_action(action: String, payload: Dictionary = {}) -> Dictionary:
	if current_guest.is_empty() or current_guest.get("completed", false):
		return _result("当前没有待处理交易。", "", false, {"speaker": "system"})
	if not current_guest.get("role_revealed", false):
		return _result("先听客人说明来意。", "", false, {"speaker": "system"})
	# Private examination is not a conversational turn, even at zero patience.
	if action in ["inspect", "appraise"] and current_guest["role"] == "seller":
		return _inspect_item(current_guest["item"], false) if action == "inspect" else _appraise_item(current_guest["item"], "来货鉴定")
	if action == "appraise_inventory":
		return _appraise_item(get_inventory_item(selected_item_id), "库存复核")
	if action == "apologize":
		if current_guest["offended"] and not current_guest["apology_used"]:
			current_guest["apology_used"] = true
			current_guest["patience"] = mini(6, int(current_guest["patience"]) + 1)
			return _result("你缓和了刚才的语气，对方愿意再谈一句。", "接受一次道歉，稍微缓和，但不新增事实。", false)
		return _result("眼下不需要反复道歉。", "自然回应，不因寒暄恢复耐心。", false)
	if action == "accuse":
		current_guest["offended"] = true
		_consume_patience(2)
		_remember(current_guest["id"], "曾在没有出示充分证据时被掌柜指责。", -1)
		return _result("对方对指责感到不悦。你仍可说明依据或尝试道歉。", "表现被冒犯，不承认未知真相，不新增事实。", false)
	if action == "respond" and current_guest["role"] == "buyer":
		return _respond_to_buyer(payload)
	if action == "source" and current_guest["role"] == "buyer":
		return _result("可以打开物件资料核对来历，再用回答框向买家说明。", "请等待掌柜查看来源记录，不替掌柜回答。", false)
	if action == "offer" and current_guest["role"] == "seller" and not current_guest["item"]["appraised"]:
		return _result("收购前请先完成必要鉴定；这一步不消耗耐心。", "等待掌柜看过东西再决定报价。", false, {"speaker": "system"})
	if action == "offer" and current_guest["role"] == "buyer":
		var offered: Dictionary = get_inventory_item(str(current_guest.get("recommended_item_id", "")))
		if offered.get("custody", false):
			return _result("旧账标注暂存：没有原主同意，暂不能当自有库存出售。", "理解需要先核对寄存手续，不擅自同意出售。", false, {"speaker": "system"})
	var before_ledger := ledger.size()
	var trading_item: Dictionary = current_guest.get("item", {}) if current_guest["role"] == "seller" else get_inventory_item(str(current_guest.get("recommended_item_id", "")))
	var result := super.process_action(action, payload)
	if ledger.size() > before_ledger:
		var entry: Dictionary = ledger.back()
		entry["day"] = day
		entry["item_id"] = trading_item["id"]
		entry["actor"] = current_guest["id"]
		trading_item["location"] = "inventory" if current_guest["role"] == "seller" else "sold"
		_remember(current_guest["id"], "第%d日以¥%d%s《%s》。" % [day, absi(int(entry["amount"])), entry["type"], trading_item["title"]], 1)
		if current_guest["role"] == "buyer":
			sold_items.append({"id": trading_item["id"], "day": day, "buyer": current_guest["id"], "price": int(entry["amount"]), "discovered": false, "disclosed": str(current_guest["shared"].get(trading_item["id"], "")), "clues_at_sale": trading_item["revealed_clues"].duplicate()})
			var category := str(trading_item["category"])
			reputation_points[category] += 1
			_update_reputation()
	if result.get("completed", false) and ledger.size() == before_ledger:
		_remember(current_guest["id"], "第%d日没有成交。" % day, 0)
	return result

func _inspect_item(item: Dictionary, _full: bool) -> Dictionary:
	var level := int(skills[item["category"]]) + int(practice[item["category"]])
	var found: Array[String] = []
	for clue in item["clue_rules"]:
		if level >= int(clue["threshold"]) and not item["revealed_clues"].has(clue["text"]):
			item["revealed_clues"].append(clue["text"])
			found.append(clue["text"])
			break
	var description := "；".join(found) if not found.is_empty() else "暂时没有新的发现。"
	return _result(description, "以掌柜内心表达观察到：%s。未观察到的事实不得补充。" % description, false, {"speaker": "inner"})

func _appraise_item(item: Dictionary, context: String) -> Dictionary:
	if item.is_empty():
		return _result("请先选择物件。", "", false, {"speaker": "system"})
	var category := str(item["category"])
	var level := int(skills[category]) + int(practice[category])
	var score := int(item["prior"])
	var fake := false
	for clue in item["clue_rules"]:
		if level >= int(clue["threshold"]):
			if not item["revealed_clues"].has(clue["text"]):
				item["revealed_clues"].append(clue["text"])
			if clue["decisive"]:
				fake = true
			score += int(clue["weight"])
	var changed: bool = not item["appraised"] or int(item["assessment_level"]) < level
	item["appraised"] = true
	item["assessment_level"] = level
	item["judged_fake"] = fake
	item["probability"] = clampi(score, 1, 99)
	# Broad prototype quote heuristic, not authoritative market value or a guarantee.
	item["estimated_low"] = 100 if fake else int(float(item["ask"]) * 0.45)
	item["estimated_high"] = 300 if fake else int(float(item["ask"]) * 1.15)
	item["era"] = "年代存疑" if not fake else "与旧物说法矛盾"
	if changed:
		appraisal_history.append({"item_id": item["id"], "title": item["title"], "day": day, "context": context, "probability": item["probability"], "judged_fake": fake, "clues": item["revealed_clues"].duplicate()})
		if not item.get("practice_awarded", false):
			practice[category] += 2
			item["practice_awarded"] = true
	var verdict := "判定为假" if fake else "真品可能性 %d%%" % item["probability"]
	var report := "%s：%s。%s" % [item["title"], verdict, "；".join(item["revealed_clues"])]
	return _result(report, "掌柜内心判断，只能表达：%s。不补写年代和来源。" % report, false, {"speaker": "inner", "appraisal": true})

func _recommend_selected() -> Dictionary:
	var result := super._recommend_selected()
	if result.get("recommended", false):
		if not current_guest["seen_items"].has(selected_item_id):
			current_guest["seen_items"].append(selected_item_id)
		var kind := (day + int(current_guest["portrait_index"])) % 3
		current_guest["question"] = ["这件东西的来历，有什么记录能对得上？", "您看到哪些品相问题，修补情况有记录吗？", "您目前的判断主要依据哪些线索？有没有拿不准的地方？"][kind]
		result["llm_instruction"] += " 本次请问掌柜：%s。不要替掌柜回答。" % current_guest["question"]
	return result

func _respond_to_buyer(payload: Dictionary) -> Dictionary:
	var item := get_inventory_item(str(current_guest.get("recommended_item_id", "")))
	if item.is_empty():
		return _result("请先推荐具体物件。", "", false, {"speaker": "system"})
	var answer := str(payload.get("text", "")).strip_edges()
	if answer.is_empty():
		return _result("先写下你准备怎样回答。", "", false, {"speaker": "system"})
	current_guest["shared"][item["id"]] = answer
	return _result("你向客人作了说明。查看资料和必要回答不消耗耐心。", "客人听到掌柜的说法：%s。只能把它当掌柜的陈述，不把它确认为事实，不新增预算或真相。可表示理解，也可对尚无凭据处保留意见。" % answer, false)

func answer_suggestions() -> Array[String]:
	var item := get_inventory_item(str(current_guest.get("recommended_item_id", selected_item_id)))
	if item.is_empty():
		return []
	var source := str(item.get("public_provenance", ""))
	var first := "目前的记录是：%s。没有凭据的部分我不替它保证。" % source if not source.is_empty() else "这件还没有完整来源记录，我不能把传闻当成凭据。"
	var clues := "；".join(item["revealed_clues"])
	var second := "我目前能看到：%s。我们可以结合这些再判断。" % clues if not clues.is_empty() else "我还没仔细看过，先让我把器物检查一下再答复。"
	return [first, second, "这一点我暂时不清楚，可以先保留意见，不急着成交。"]

func get_match_level(item: Dictionary, guest: Dictionary) -> String:
	if not guest.get("revealed", {}).has("need"):
		return "unknown"
	var wanted := str(guest["need"]["category"])
	if item["category"] == wanted:
		return "exact"
	return "none"

func public_dialogue_context() -> String:
	if current_guest.is_empty(): return ""
	var parts: Array[String] = ["当前关系：" + relationship(current_guest["id"]), _patience_instruction()]
	for topic in current_guest["revealed"]:
		parts.append("本次已公开：" + str(current_guest["facts"].get(topic, "")))
	var recommended := get_inventory_item(str(current_guest.get("recommended_item_id", "")))
	if not recommended.is_empty():
		parts.append("已拿给客人看的物件：%s；确定类别%s。" % [recommended["title"], recommended["category"]])
	# Never include private appraisal, authoritative authenticity or hidden budgets.
	for memory in contacts[current_guest["id"]]["memories"].slice(-4):
		parts.append("双方往来记录：" + str(memory))
	return "\n".join(parts)

func _buyer_offer(amount: int) -> Dictionary:
	if not current_guest["revealed"].has("need"):
		return _result("还没了解买家的具体类别需求，先问清再报价。", "说明还需要谈清需求，暂不承诺购买。", false)
	return super._buyer_offer(amount)

func _remember(actor_id: String, text: String, delta: int) -> void:
	contacts[actor_id]["met"] = true
	contacts[actor_id]["relation"] = clampi(int(contacts[actor_id]["relation"]) + delta, -6, 15)
	contacts[actor_id]["memories"].append(text)

func relationship(actor_id: String) -> String:
	var value := int(contacts[actor_id]["relation"])
	if value < 0: return "防备"
	if value < 3: return "生疏"
	if value < 7: return "熟悉"
	if value < 12: return "信任"
	return "深交"

func _update_reputation() -> void:
	for category in reputation_points:
		var value := int(reputation_points[category])
		category_reputation[category] = "相关圈子有所疑虑" if value < 0 else ("在相关圈子里受到认可" if value >= 8 else ("逐渐形成口碑" if value >= 4 else ("偶有人提起" if value >= 2 else "尚无名气")))
	global_trust = "声誉受损" if trust_points < 0 else ("值得信赖" if trust_points >= 6 else ("口碑稳定" if trust_points >= 3 else "尚无定论"))

func available_story() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in content["story_nodes"]:
		if int(node["day"]) > day or resolved_nodes.has(node["id"]): continue
		if outside.has("defer_" + str(node["id"])): continue
		var ready := true
		for requirement in node["requires"]:
			if not flags.has(requirement): ready = false
		if ready: result.append(node)
	return result

func choose_story(node_id: String, choice_id: String) -> bool:
	if not can_go_out(): return false
	for node in available_story():
		if node["id"] != node_id: continue
		for choice in node["choices"]:
			if choice["id"] != choice_id: continue
			if choice.get("defer", false):
				outside["defer_" + node_id] = true
				return true
			flags[node_id + "_seen"] = true
			if choice.has("flag"): flags[choice["flag"]] = true
			resolved_nodes.append(node_id)
			_remember(node["actor"], "第%d日：%s；掌柜选择%s。" % [day, node["title"], choice["label"]], int(choice.get("relation", 0)))
			day_notes.append("%s：%s" % [node["title"], node["text"]])
			return true
	return false

func finish_chapter(route: String) -> Dictionary:
	if day != 10 or phase != "closing": return {}
	if not chapter_ending.is_empty(): return content["endings"][chapter_ending]
	if route == "return" and flags.has("consent") and not get_inventory_item("painting").is_empty():
		inventory.erase(all_items["painting"])
		all_items["painting"]["location"] = "returned"
		_remember("sun", "寄存的画已归还，手续补齐。", 3)
		chapter_ending = "return"
	elif route == "sale" and flags.has("consent") and flags.has("catalogue"):
		if not get_inventory_item("painting").is_empty():
			inventory.erase(all_items["painting"])
			all_items["painting"]["location"] = "returned"
		money += 180
		ledger.append({"day": day, "type": "授权委托服务费", "amount": 180, "item": "孙家茶器（非店铺自有库存）", "guest": "孙玉梅 / 陈素琴", "gross": 1800, "owner_payment": 1620})
		flags["consignment_settled"] = true
		_remember("sun", "画已归还；另一件授权茶器成交¥1800，收到¥1620，店铺服务费¥180。", 2)
		chapter_ending = "sale"
		_remember("chen", "提供了有授权并说明保留意见的清单。", 2)
	else:
		chapter_ending = "open"
	return content["endings"][chapter_ending]

func ending_requirement(route: String) -> String:
	if route == "return":
		if not flags.has("consent"): return "尚缺交接存根、旧照与原主意愿的完整核对。"
		if get_inventory_item("painting").is_empty(): return "画已不在库存，无法完成此项交接。"
	if route == "sale" and not (flags.has("consent") and flags.has("catalogue")):
		return "尚缺原主授权或经核对的如实清单。"
	return ""

func _resolve_discoveries() -> void:
	for sale in sold_items:
		if sale["discovered"] or day < int(sale["day"]) + 2: continue
		var item: Dictionary = all_items[sale["id"]]
		if item["authentic"]: continue
		# A specific later inspection, not the sale, exposes a qualified clue.
		# Some private collectors do not seek a second opinion during this chapter.
		if sale["buyer"] == "wu" and (int(item["art"]) + int(sale["day"])) % 3 == 0: continue
		var flaw := ""
		for clue in item["clue_rules"]:
			if clue["decisive"] and int(clue["threshold"]) <= 75: flaw = str(clue["text"])
		if flaw.is_empty(): continue
		sale["discovered"] = true
		var ceiling := 0
		if int(sale["price"]) >= 1000 or sale["buyer"] in ["xu", "chen"]: ceiling = 1
		if int(sale["price"]) >= 2500 and sale["buyer"] in ["lin", "chen"]: ceiling = 2
		consequences.append({"id": item["id"], "buyer": sale["buyer"], "price": sale["price"], "stage": 0, "ceiling": ceiling, "next_day": day + 2, "interventions": [], "contained": false, "disclosed": sale.get("disclosed", ""), "text": "买家在再次看货时请业内人士检查《%s》，发现：%s。消息已传回店里。" % [item["title"], flaw]})
		skills[item["category"]] += 5
		reputation_points[item["category"]] -= 2
		trust_points -= 1
		day_notes.append("第%d日收到《%s》的看货反馈：%s；记录新增观察方法，原交易保留。" % [day, item["title"], flaw])
		_remember(sale["buyer"], "售后看货发现物件有问题；原交易未撤销。", -2)
	for event in consequences:
		if not event["contained"] and day >= int(event["next_day"]) and int(event["stage"]) < int(event.get("ceiling", 2)):
			event["stage"] += 1
			event["next_day"] = day + 2
			trust_points -= 1 if int(event["price"]) < 1500 else 2
	_update_reputation()

func intervene(event_id: String, method: String) -> String:
	for event in consequences:
		if event["id"] != event_id: continue
		var stage := int(event["stage"])
		if event["interventions"].has(stage) or event["contained"]: return "这一传播阶段已经沟通过。"
		if method not in ["explain", "evidence"]: return "请选择解释或补充证据。"
		event["interventions"].append(stage)
		var disclosed := str(event.get("disclosed", ""))
		var supported := method == "evidence" and _contains_any(disclosed, ["不保证", "不替", "拿不准", "保留意见", "不清楚"])
		if supported or int(contacts[event["buyer"]]["relation"]) >= 3:
			event["contained"] = true
			_remember(event["buyer"], "掌柜主动沟通并补充了信息，暂不继续传播。", 1)
			return "对方同意暂缓进一步传播；已经发生的影响和原交易保留。"
		event["next_day"] += 1
		return "对方听了说明，但仍有疑虑。进一步传播被延缓一个营业日。"
	return "当前没有这项已知事件。"

func can_go_out() -> bool:
	return phase in ["noon", "closing"] and current_guest.is_empty() and chapter_ending.is_empty()

func market_item() -> Dictionary:
	var id := "marketbowl" if day % 2 == 1 else "marketseal"
	var item: Dictionary = all_items[id]
	return {} if item["location"] != "unseen" else item

func inspect_outside(item_id: String) -> Dictionary:
	if not can_go_out(): return {}
	var item: Dictionary = all_items.get(item_id, {})
	if item.is_empty(): return {}
	var permitted: Array[String] = []
	var market := market_item()
	if not market.is_empty(): permitted.append(str(market["id"]))
	if not auction.is_empty() and not auction["done"]: permitted.append(str(auction["item_id"]))
	if item_id not in permitted: return {}
	item["public_provenance"] = "外部卖方说明（未独立核实）：%s" % item["source_claim"]
	return _appraise_item(item, "店外看货")

func market_buy(amount: int) -> String:
	if not can_go_out(): return "当前不能外出交易。"
	var item := market_item()
	if item.is_empty(): return "这批摊货已不在了。"
	if not item["appraised"]: return "先看过货再决定。"
	if amount < int(item["minimum"]): return "摊主摇头：这个价还不行。"
	if amount > money: return "资金不足，无法成交。"
	_acquire(item, amount, "古玩街")
	return "收下《%s》，支付¥%d。" % [item["title"], amount]

func consult(item_id: String) -> String:
	if not can_go_out(): return "请在午间或闭店后拜访。"
	if outside.has("consult"): return "今天的看货已经完成，许闻溪请你下次带着新问题再来。"
	var item := get_inventory_item(item_id)
	if item.is_empty(): return "先选择一件自己的库存。"
	if money < 100: return "看货费¥100，当前资金不足。"
	var expertise := {"瓷器": 75, "书画": 65, "文房": 55, "杂项": 48}
	var category := str(item["category"])
	var headroom := int(expertise[category]) - int(skills[category]) - int(practice[category])
	if headroom <= 0: return "许闻溪坦言：这类问题超出了我能继续帮助你的范围，今天不收费。"
	money -= 100
	ledger.append({"day": day, "type": "看货费", "amount": -100, "item": item["title"], "guest": "许闻溪"})
	outside["consult"] = true
	skills[category] += mini(6, headroom)
	var result := _appraise_item(item, "与许闻溪复核")
	_remember("xu", "一起复核过《%s》，提醒用证据说话。" % item["title"], 1)
	return "支付看货费¥100，相关知识增长。%s" % result["system_text"]

func auction_preview() -> Dictionary:
	if not can_go_out() or day < 3: return {}
	if not auction.is_empty(): return auction
	var id := "auctionfan" if day % 2 == 1 else "auctionvase"
	if all_items[id]["location"] != "unseen": return {}
	auction = {"item_id": id, "price": 300, "rival_limit": 900 + day * 40, "done": false, "outcome": "预展", "fee_percent": 5}
	return auction

func bid(amount: int) -> String:
	if not can_go_out() or auction.is_empty() or auction["done"]: return "当前没有进行中的拍卖。"
	var item: Dictionary = all_items[auction["item_id"]]
	if not item["appraised"]: return "先查看预展物件再决定是否举牌。"
	if amount <= int(auction["price"]): return "新报价必须高于当前价。"
	var total := amount + int(ceil(amount * 0.05))
	if total > money: return "含5%费用共¥%d，资金不足。" % total
	if amount <= int(auction["rival_limit"]):
		auction["price"] = amount + 100
		return "另一位买家跟到¥%d。你可以继续或退出。" % auction["price"]
	auction["done"] = true
	auction["price"] = amount
	auction["outcome"] = "成交"
	_acquire(item, total, "小型拍卖")
	_remember("chen", "第%d日参与小拍并完成结算。" % day, 1)
	return "落槌¥%d，加5%%费用共¥%d。《%s》进入库存。" % [amount, total, item["title"]]

func leave_auction() -> void:
	if not auction.is_empty() and not auction["done"]:
		auction["done"] = true
		auction["outcome"] = "退出，未扣款"

func _acquire(item: Dictionary, amount: int, source: String) -> void:
	if item["location"] != "unseen" or amount < 0 or amount > money: return
	money -= amount
	item["cost"] = amount
	item["location"] = "inventory"
	inventory.append(item)
	ledger.append({"day": day, "type": "收购", "amount": -amount, "item": item["title"], "item_id": item["id"], "guest": source})

func recovery_available() -> bool:
	var saleable := false
	for item in inventory:
		if not item.get("custody", false): saleable = true
	return money < 250 and not saleable and recovery_day != day and current_guest.is_empty()

func complete_recovery() -> String:
	if not recovery_available(): return "目前不需要经营恢复委托。"
	recovery_day = day
	money += 500
	ledger.append({"day": day, "type": "基础看货委托", "amount": 500, "item": "只看货，不转移物权", "guest": "街坊"})
	return "帮助街坊记录可见品相，不保证真伪；收到基础看货服务费¥500，可重新经营。"

func save_game(path: String = "user://chapter_save.json") -> Error:
	var data := {"version": 2, "day": day, "phase": phase, "money": money,
		"contacts": contacts, "skills": skills, "practice": practice, "flags": flags,
		"resolved_nodes": resolved_nodes, "sold_items": sold_items, "consequences": consequences,
		"outside": outside, "all_items": all_items, "ledger": ledger, "appraisal_history": appraisal_history,
		"day_notes": day_notes, "decisions": decisions, "reputation_points": reputation_points,
		"trust_points": trust_points, "recovery_day": recovery_day, "auction": auction,
		"day_start_money": day_start_money, "day_ledger_start": day_ledger_start,
		"chapter_ending": chapter_ending, "current_index": current_index, "guests": guests,
		"selected_item_id": selected_item_id, "has_current_guest": not current_guest.is_empty(), "ui_state": ui_state}
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK: return write_error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))

func load_game(path: String = "user://chapter_save.json") -> Error:
	if not FileAccess.file_exists(path): return ERR_FILE_NOT_FOUND
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return ERR_FILE_CORRUPT
	var parsed = parser.data
	if not parsed is Dictionary: return ERR_FILE_CORRUPT
	if not (parsed.get("version") is float or parsed.get("version") is int): return ERR_FILE_CORRUPT
	if int(parsed["version"]) != 2: return ERR_FILE_CORRUPT
	for key in ["day", "phase", "money", "contacts", "skills", "practice", "flags", "resolved_nodes", "sold_items", "consequences", "outside", "all_items", "ledger", "appraisal_history", "day_notes", "decisions", "reputation_points", "trust_points", "recovery_day", "auction", "day_start_money", "day_ledger_start", "chapter_ending", "current_index", "guests", "selected_item_id"]:
		if not parsed.has(key): return ERR_FILE_CORRUPT
	if not _valid_save(parsed): return ERR_FILE_CORRUPT
	if int(parsed["day"]) < 1 or int(parsed["day"]) > 10 or int(parsed["money"]) < 0: return ERR_FILE_CORRUPT
	# Explicit allowlist, never set arbitrary properties from a save file.
	for key in ["day", "phase", "money", "contacts", "skills", "practice", "flags", "resolved_nodes", "sold_items", "consequences", "outside", "all_items", "reputation_points", "trust_points", "recovery_day", "auction", "day_start_money", "day_ledger_start", "chapter_ending", "current_index", "selected_item_id"]:
		set(key, parsed[key])
	ui_state = parsed.get("ui_state", {})
	guests.assign(parsed["guests"])
	ledger.assign(parsed["ledger"])
	appraisal_history.assign(parsed["appraisal_history"])
	decisions.assign(parsed["decisions"])
	day_notes.assign(parsed["day_notes"])
	inventory = []
	for item in all_items.values():
		if item["location"] == "inventory": inventory.append(item)
	for guest in guests:
		if guest.get("role") == "seller": guest["item"] = all_items[guest["item"]["id"]]
	current_guest = guests[current_index] if parsed["has_current_guest"] and current_index >= 0 and current_index < guests.size() else {}
	_update_reputation()
	return OK

func _valid_save(data: Dictionary) -> bool:
	for key in ["contacts", "skills", "practice", "flags", "outside", "all_items", "reputation_points", "auction"]:
		if not data[key] is Dictionary: return false
	for key in ["resolved_nodes", "sold_items", "consequences", "ledger", "appraisal_history", "day_notes", "decisions", "guests"]:
		if not data[key] is Array: return false
	for key in ["day", "money", "trust_points", "recovery_day", "day_start_money", "day_ledger_start", "current_index"]:
		if not (data[key] is float or data[key] is int): return false
	if not data.get("has_current_guest") is bool or not data.get("ui_state", {}) is Dictionary: return false
	if data["phase"] not in ["morning", "noon", "afternoon", "closing"]: return false
	if data["chapter_ending"] not in ["", "return", "sale", "open"]: return false
	if not data["selected_item_id"] is String: return false
	if data["guests"].size() != 4 or int(data["current_index"]) < -1 or int(data["current_index"]) > 3: return false
	if data["has_current_guest"] and (int(data["current_index"]) < 0 or data["phase"] in ["noon", "closing"]): return false
	for category in skills:
		for key in ["skills", "practice", "reputation_points"]:
			if not data[key].get(category) is float and not data[key].get(category) is int: return false
	for actor in contacts:
		var contact = data["contacts"].get(actor)
		if not contact is Dictionary or not contact.get("memories") is Array or not contact.get("met") is bool: return false
		if not (contact.get("relation") is int or contact.get("relation") is float): return false
		for memory in contact["memories"]:
			if not memory is String: return false
	for id in all_items:
		var item = data["all_items"].get(id)
		if not item is Dictionary: return false
		for key in all_items[id]:
			if key in ["practice_awarded", "estimated_low", "estimated_high"]: continue
			if not item.has(key): return false
		if item["id"] != id or item["category"] not in skills: return false
		if item["location"] not in ["unseen", "inventory", "sold", "returned"]: return false
		if not item["revealed_clues"] is Array or not item["clue_rules"] is Array: return false
	for guest in data["guests"]:
		if not guest is Dictionary or guest.get("id") not in contacts or guest.get("role") not in ["seller", "buyer"]: return false
		for key in ["revealed", "asked", "facts", "shared"]:
			if not guest.get(key) is Dictionary: return false
		for key in ["role_revealed", "completed", "offended", "apology_used"]:
			if not guest.get(key) is bool: return false
		if not guest.get("seen_items") is Array: return false
		if guest["role"] == "seller":
			if not guest.get("item") is Dictionary or guest["item"].get("id") not in all_items: return false
		else:
			if not guest.get("need") is Dictionary or not guest["need"].has("max_price"): return false
	for key in ["ledger", "appraisal_history", "decisions", "sold_items", "consequences"]:
		for entry in data[key]:
			if not entry is Dictionary: return false
	for note in data["day_notes"]:
		if not note is String: return false
	return true
