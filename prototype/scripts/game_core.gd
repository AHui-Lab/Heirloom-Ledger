class_name DemoGameCore
extends RefCounted

const MORNING := "上午"
const AFTERNOON := "下午"

var money: int = 3600
var knowledge: int = 42
var experience: int = 18
var global_trust: String = "尚无定论"
var category_reputation: Dictionary = {
	"瓷器": "尚无名气",
	"书画": "尚无名气",
	"文房": "偶有人提起",
	"杂项": "尚无名气",
}
var inventory: Array[Dictionary] = []
var guests: Array[Dictionary] = []
var current_index: int = -1
var current_guest: Dictionary = {}
var ledger: Array[Dictionary] = []
var appraisal_history: Array[Dictionary] = []
var day_notes: Array[String] = []
var decisions: Array[Dictionary] = []
var selected_item_id: String = ""

func _init() -> void:
	reset()

func reset() -> void:
	money = 3600
	knowledge = 42
	experience = 18
	global_trust = "尚无定论"
	category_reputation = {
		"瓷器": "尚无名气",
		"书画": "尚无名气",
		"文房": "偶有人提起",
		"杂项": "尚无名气",
	}
	inventory = [
		_item("inkstone", "旧端砚", "文房", "清末至民国", true, 1180, 520,
			["石质细润，边角有自然使用痕迹。", "砚堂墨锈层次自然，并非一次做旧。"], 78,
			"爷爷留下的旧库存，来源记载较完整。"),
		_item("painting", "山水小品", "书画", "民国", true, 1760, 860,
			["纸张氧化与画心边缘状态基本一致。", "题款笔意尚可，但印章边缘略显拘谨。"], 67,
			"旧账本只记有前任藏家姓周。"),
		_item("snuff", "铜胎画珐琅鼻烟壶", "杂项", "当代仿制", false, 260, 680,
			["彩料表面过于均匀，缺少自然层次。", "口沿磨损与器身使用痕迹并不一致。"], 31,
			"爷爷旧库存中没有可靠来源记录。"),
	]
	guests = _build_guests()
	current_index = -1
	current_guest = {}
	ledger = []
	appraisal_history = []
	day_notes = []
	decisions = []
	selected_item_id = ""

func _item(id: String, title: String, category: String, era: String, authentic: bool,
		market_value: int, cost: int, clues: Array, probability: int, provenance: String) -> Dictionary:
	return {
		"id": id,
		"title": title,
		"category": category,
		"era": era,
		"authentic": authentic,
		"market_value": market_value,
		"cost": cost,
		"clues": clues.duplicate(),
		"probability": probability,
		"provenance": provenance,
		"public_provenance": provenance,
		"appraised": false,
		"revealed_clues": [],
	}

func _build_guests() -> Array[Dictionary]:
	var fake_bowl := _item(
		"blue_bowl", "青花折枝花纹碗", "瓷器", "当代仿康熙", false, 180, 0,
		["底足磨痕过于均匀，像是为了做旧而形成。", "青花发色浮在釉面，层次与康熙常见特征不合。"],
		23, "卖家称是老宅橱柜中发现，但拿不出更早的流传记录。")
	var tea_caddy := _item(
		"tea_caddy", "竹纹锡茶叶罐", "杂项", "民国", true, 920, 0,
		["包浆集中在经常触碰的位置。", "底部錾刻与器身磨损方向能够对应。"],
		81, "卖家父亲早年经营茶庄，来源说法与器物用途相符。")
	# A source claim becomes a player record only after it is actually disclosed.
	fake_bowl["public_provenance"] = ""
	tea_caddy["public_provenance"] = "父亲茶庄留下的茶叶罐。（卖家入店时的说法，尚未独立核实。）"
	return [
		{
			"id": "zhao_seller", "name": "赵庆生", "period": MORNING, "role": "seller",
			"content_roles": ["判断挑战"], "challenge": true,
			"role_revealed": false, "opening_reveals": [],
			"portrait": "赵", "subtitle": "抱着一只旧木盒，话说得很笃定",
			"personality": "五十多岁，务实而好面子。他真心相信家里传下来的碗是老物件，被直接质疑时会防备。",
			"hidden_state": "真诚但认知错误；并不知道器物是现代仿品。因近期装修需要现金，最低可接受 650。",
			"opening_fact": "先寒暄，随后说家里收拾老宅，带了一件东西请掌柜看看。不要一开始说明真假或最低价。",
			"item": fake_bowl, "ask_price": 1800, "min_price": 650, "patience": 5,
			"revealed": {}, "asked": {}, "completed": false, "outcome": "未处理",
			"facts": {
				"source": "这是老宅橱柜里翻出来的，家里老人一直说是祖上传下来的；更早的票据确实没有。",
				"repair": "我没修过，家里也没人提过修补。木盒倒是后来配的。",
				"price": "我打听过类似的老碗，原本想要一千八。装修正用钱，但太低我不会出。",
				"motive": "老房子要重新装修，最近确实需要一笔现钱。",
			},
			"missable": ["追问木盒是否与器物同年代", "将老宅传闻与缺少流传记录分开判断", "正式鉴定底足与青花发色"],
		},
		{
			"id": "lin_buyer", "name": "林若岚", "period": MORNING, "role": "buyer",
			"content_roles": ["判断挑战"], "challenge": true,
			"role_revealed": false, "opening_reveals": [],
			"portrait": "林", "subtitle": "衣着利落，只说想随便看看",
			"personality": "三十多岁，做事谨慎，不愿过早暴露预算。她要给懂文房的长辈准备寿礼，怕被看出不懂行。",
			"hidden_state": "实际寻找体面而有可靠来历的文房或书画寿礼；预算上限 2200，偏爱来源可靠胜过年代更早。",
			"opening_fact": "说自己路过随便看看，可以含蓄提到想找一件拿得出手的旧物，但先不说送礼和真实预算。",
			"need": {"category": "文房", "era": "清末至民国", "public_budget": "一两千左右", "max_price": 2200},
			"patience": 5, "revealed": {}, "asked": {}, "completed": false, "outcome": "未处理",
			"facts": {
				"need": "想找一件体面、能摆得住的旧物，文房最好，合适的书画也可以。",
				"purpose": "是给一位很懂文房的长辈做寿礼，所以来历和品相比单纯年代更重要。",
				"budget": "合适的话两千左右能接受，特别稳妥可以再添一点，但上限不会超过两千二。",
				"era": "清末到民国都可以，不必非追求更早。",
			},
			"missable": ["从“拿得出手”追问真实用途", "发现她更重视来源而非绝对年代", "在报价前探明预算弹性"],
		},
		{
			"id": "sun_seller", "name": "孙玉梅", "period": AFTERNOON, "role": "seller",
			"content_roles": ["常规经营"], "challenge": false,
			"role_revealed": false, "opening_reveals": [],
			"portrait": "孙", "subtitle": "带来一只旧茶叶罐，态度坦率",
			"personality": "退休职工，说话直接。她了解器物的家庭来源，但不熟悉市场行情。",
			"hidden_state": "对器物来源基本了解，没有刻意隐瞒；希望清理闲置，最低可接受 420。",
			"opening_fact": "直接说明带来父亲茶庄留下的茶叶罐，想问问店里收不收。",
			"item": tea_caddy, "ask_price": 650, "min_price": 420, "patience": 6,
			"revealed": {}, "asked": {}, "completed": false, "outcome": "未处理",
			"facts": {
				"source": "父亲年轻时开过茶庄，这只罐一直放在家里。旧照片里似乎见过它。",
				"repair": "没有修过，盖子一直有点松，家里也没有重新配过。",
				"price": "我不懂行情，想着六百五左右；合适就出，不合适我再带回去。",
				"motive": "家里清理旧物，不急着用钱，只是不想继续占地方。",
			},
			"missable": ["询问茶庄来源", "观察包浆是否符合使用位置"],
		},
		{
			"id": "wu_buyer", "name": "吴致远", "period": AFTERNOON, "role": "buyer",
			"content_roles": ["常规经营"], "challenge": false,
			"role_revealed": false, "opening_reveals": ["need", "era"],
			"portrait": "吴", "subtitle": "熟客介绍来的年轻买家",
			"personality": "年轻设计师，表达直接，喜欢民国书画，预算有限但愿意为喜欢的作品加一点。",
			"hidden_state": "明确寻找民国小幅书画装饰新家；舒适预算 1500，上限 1850。",
			"opening_fact": "直接说是朋友介绍来的，想找一幅民国前后、尺寸不大的书画。",
			"need": {"category": "书画", "era": "民国", "public_budget": "一千五上下", "max_price": 1850},
			"patience": 6, "revealed": {}, "asked": {}, "completed": false, "outcome": "未处理",
			"facts": {
				"need": "想找一幅民国前后的小幅书画，挂在新家书房。",
				"purpose": "主要是自己欣赏和装饰，不是送礼。",
				"budget": "一千五上下最舒服，真喜欢的话可以到一千八左右。",
				"era": "民国最好，晚一些但气韵合适也愿意看。",
			},
			"missable": ["确认悬挂用途和尺寸偏好", "在报价前确认上限"],
		},
	]

func next_guest() -> Dictionary:
	current_index += 1
	selected_item_id = ""
	if current_index >= guests.size():
		current_guest = {}
		return {}
	current_guest = guests[current_index]
	return current_guest

func current_period() -> String:
	if current_index < 0:
		return MORNING
	if current_index < 2:
		return MORNING
	return AFTERNOON

func classify_free_text(text: String) -> Dictionary:
	var normalized := text.strip_edges()
	var amount := _extract_number(normalized)
	if amount > 0 and _contains_any(normalized, ["报价", "出价", "我出", "给你", "卖", "买", "元", "块"]):
		return {"action": "offer", "amount": amount}
	if _contains_any(normalized, ["鉴定", "真假", "真品", "仿", "断代"]):
		return {"action": "appraise"}
	if _contains_any(normalized, ["观察", "看看", "细看", "底足", "釉", "包浆", "磨损"]):
		return {"action": "inspect"}
	if _contains_any(normalized, ["来源", "哪来", "来历", "祖传", "传承"]):
		return {"action": "source"}
	if _contains_any(normalized, ["修", "补", "磕", "残", "动过"]):
		return {"action": "repair"}
	if _contains_any(normalized, ["预算", "多少钱", "价位", "心理价", "最低", "价格", "便宜", "少点"]):
		return {"action": "budget" if current_guest.get("role") == "buyer" else "price"}
	if _contains_any(normalized, ["用途", "送人", "自己用", "为什么买", "做什么"]):
		return {"action": "purpose"}
	if _contains_any(normalized, ["年代", "时期", "朝代"]):
		return {"action": "era"}
	if _contains_any(normalized, ["想找", "需要", "要求", "喜欢什么", "具体"]):
		return {"action": "need"}
	if _contains_any(normalized, ["不要", "算了", "放弃", "不收", "不卖", "请回"]):
		return {"action": "decline"}
	return {"action": "smalltalk"}

func _extract_number(text: String) -> int:
	var regex := RegEx.new()
	regex.compile("[0-9]+")
	var result := regex.search(text)
	return int(result.get_string()) if result else 0

func _contains_any(text: String, terms: Array) -> bool:
	for term in terms:
		if text.contains(str(term)):
			return true
	return false

func process_action(action: String, payload: Dictionary = {}) -> Dictionary:
	if current_guest.is_empty() or current_guest.get("completed", false):
		return _result("当前没有可以继续处理的客人。", "客人已经离店。", false)
	if int(current_guest.get("patience", 0)) <= 0 and action not in ["offer", "decline"]:
		return _result("客人的耐心已经耗尽。现在只能给出最后报价，或结束本次交易。", "拒绝继续提供信息或查看新的物件，明确要求掌柜现在给出最后报价，否则就结束交易。不得新增事实。", false)
	if action == "appraise_inventory":
		if selected_item_id.is_empty():
			return _result("请先从右侧库存中选择一件物品。", "掌柜还没有选择要复核的库存物件。", false)
		return _appraise_item(get_inventory_item(selected_item_id), "库存复核")
	if current_guest.get("role") == "seller":
		return _process_seller(action, payload)
	return _process_buyer(action, payload)

func _process_seller(action: String, payload: Dictionary) -> Dictionary:
	match action:
		"source", "repair", "price", "motive":
			return _reveal_topic(action)
		"budget":
			return _reveal_topic("price")
		"inspect":
			return _inspect_item(current_guest["item"], false)
		"appraise":
			return _appraise_item(current_guest["item"], "来货鉴定")
		"offer":
			return _seller_offer(int(payload.get("amount", 0)))
		"decline":
			current_guest["completed"] = true
			current_guest["outcome"] = "玩家放弃收购"
			decisions.append({"guest": current_guest["name"], "decision": "放弃收购", "amount": 0})
			return _result("你决定不收这件物品。", "接受玩家放弃，保持人物性格，自然结束交谈并离店。", true)
		_:
			return _smalltalk_result()

func _process_buyer(action: String, payload: Dictionary) -> Dictionary:
	match action:
		"need", "purpose", "budget", "era":
			return _reveal_topic(action)
		"source":
			return _reveal_topic("purpose")
		"inspect":
			if selected_item_id.is_empty():
				return _result("请先从右侧库存中选择一件物品。", "掌柜还没有拿出具体物件，请自然等待推荐。", false)
			return _inspect_item(get_inventory_item(selected_item_id), false)
		"appraise":
			if selected_item_id.is_empty():
				return _result("请先从右侧库存中选择一件物品。", "掌柜还没有拿出具体物件，请自然等待推荐。", false)
			return _appraise_item(get_inventory_item(selected_item_id), "推荐前复核")
		"recommend":
			return _recommend_selected()
		"offer":
			return _buyer_offer(int(payload.get("amount", 0)))
		"decline":
			current_guest["completed"] = true
			current_guest["outcome"] = "玩家结束接待，未出售"
			decisions.append({"guest": current_guest["name"], "decision": "拒绝出售", "amount": 0})
			return _result("你决定结束这次出售机会。", "尊重玩家结束交易，简短告别并离店。", true)
		_:
			return _smalltalk_result()

func _reveal_topic(topic: String) -> Dictionary:
	var facts: Dictionary = current_guest.get("facts", {})
	if not facts.has(topic):
		return _smalltalk_result()
	var repeated: bool = current_guest["asked"].has(topic)
	current_guest["asked"][topic] = true
	current_guest["revealed"][topic] = true
	_consume_patience(2 if repeated else 1)
	var fact := str(facts[topic])
	if topic == "source" and current_guest.get("role") == "seller":
		current_guest["item"]["public_provenance"] = "卖家陈述（尚未独立核实）：%s" % fact
	var system := "获得信息：%s" % fact
	var instruction := "回答玩家的问题。只可表达以下已授权事实：%s。%s" % [fact, _patience_instruction()]
	if repeated:
		system += "（重复追问使客人更加不耐。）"
		instruction += " 玩家已经问过这件事，请表现出不耐烦，但不要新增事实。"
	return _result(system, instruction, false)

func _inspect_item(item: Dictionary, full: bool) -> Dictionary:
	var revealed: Array = item.get("revealed_clues", [])
	var clues: Array = item.get("clues", [])
	var newly_revealed: Array[String] = []
	var limit: int = clues.size() if full else mini(1, clues.size())
	for i in range(limit):
		var clue := str(clues[i])
		if not revealed.has(clue):
			revealed.append(clue)
			newly_revealed.append(clue)
	item["revealed_clues"] = revealed
	if newly_revealed.is_empty():
		return _result("没有发现新的表面线索。", "以掌柜内心独白说明暂时没有新发现，不新增线索。", false, {"speaker": "inner"})
	var joined := "；".join(newly_revealed)
	day_notes.append("%s：%s" % [item["title"], joined])
	return _result("观察线索：%s" % joined, "以掌柜第一人称内心独白分析这些可见线索：%s。客人听不到这些想法，不确认未知真相。" % joined, false, {"speaker": "inner"})

func _appraise_item(item: Dictionary, context: String) -> Dictionary:
	if item.is_empty():
		return _result("没有可鉴定的物件。", "自然提醒玩家先选择物件。", false)
	var was_appraised := bool(item.get("appraised", false))
	item["appraised"] = true
	var revealed: Array = item.get("revealed_clues", [])
	for clue in item.get("clues", []):
		if not revealed.has(clue):
			revealed.append(clue)
	item["revealed_clues"] = revealed
	var probability := int(item.get("probability", 50))
	var clue_text := "；".join(revealed)
	var record := {
		"item_id": item["id"], "title": item["title"], "context": context,
		"probability": probability, "clues": revealed.duplicate(), "knowledge": knowledge,
		"experience": experience,
	}
	if not was_appraised:
		appraisal_history.append(record)
		experience += 1
		day_notes.append("完成%s：%s，真品可能性 %d%%" % [context, item["title"], probability])
	var report := "鉴定记录｜%s\n类别：%s｜推测年代：%s｜真品可能性：%d%%\n线索：%s" % [item["title"], item["category"], _player_visible_era(item), probability, clue_text]
	var instruction := "玩家刚完成鉴定。请生成第一人称内心独白式的简短判断，只能使用：类别%s；推测年代%s；真品可能性%d%%；线索%s。不得揭示权威真假，不得把概率说成确定结论。" % [item["category"], _player_visible_era(item), probability, clue_text]
	return _result(report, instruction, false, {"appraisal": true})

func _player_visible_era(item: Dictionary) -> String:
	if item["id"] == "blue_bowl":
		return "康熙风格，年代存疑"
	if item["id"] == "snuff":
		return "清晚期风格，年代存疑"
	return str(item["era"])

func _seller_offer(amount: int) -> Dictionary:
	if amount <= 0:
		return _result("请输入有效的收购报价。", "提醒玩家给出具体报价。", false)
	if amount > money:
		return _result("资金不足：当前只有 ¥%d，无法完成 ¥%d 的报价。" % [money, amount], "玩家报价超过了可用资金。请表示即使谈妥也无法成交，不改变最低价。", false)
	if amount >= int(current_guest["min_price"]):
		var item: Dictionary = current_guest["item"]
		item["cost"] = amount
		inventory.append(item)
		money -= amount
		ledger.append({"type": "收购", "item": item["title"], "amount": -amount, "guest": current_guest["name"]})
		current_guest["completed"] = true
		current_guest["outcome"] = "以 ¥%d 成交，玩家收购了%s" % [amount, item["title"]]
		decisions.append({"guest": current_guest["name"], "decision": "收购", "amount": amount, "item": item["title"]})
		return _result("成交：支付 ¥%d，%s进入库存。" % [amount, item["title"]], "接受玩家的¥%d报价，钱货两清。自然表现成交和离店，不透露物件权威真假。" % amount, true)
	_consume_patience(1)
	if int(current_guest["patience"]) <= 0:
		current_guest["completed"] = true
		current_guest["outcome"] = "报价过低且耐心耗尽，卖家离店"
		decisions.append({"guest": current_guest["name"], "decision": "低价谈崩", "amount": amount})
		return _result("对方拒绝 ¥%d 的报价，并结束了交易。" % amount, "拒绝报价，明确表示耐心已经耗尽并带着物件离店。", true)
	return _result("对方拒绝 ¥%d 的报价。" % amount, "拒绝¥%d报价。可以依据人物动机暗示还有商量空间，但不能说出隐藏最低价。%s" % [amount, _patience_instruction()], false)

func _recommend_selected() -> Dictionary:
	if selected_item_id.is_empty():
		return _result("请先选择一件库存物品。", "请掌柜先拿一件具体物品来看。", false)
	var item := get_inventory_item(selected_item_id)
	if item.is_empty():
		return _result("所选物品已不在库存。", "这件物品目前无法查看，请玩家重新选择。", false)
	var match_level := get_match_level(item, current_guest)
	current_guest["recommended_item_id"] = selected_item_id
	current_guest["match_level"] = match_level
	var category_fact := "掌柜拿出《%s》。确定类别：%s。与买家公开需求的匹配：%s。" % [item["title"], item["category"], _match_label(match_level)]
	var instruction := "玩家向你推荐《%s》，确定类别为%s，与已公开需求属于%s。依据你已经透露的需求自然回应；不要因为系统匹配就承诺购买，也不要知道物件权威真假。%s" % [item["title"], item["category"], _match_label(match_level), _patience_instruction()]
	return _result(category_fact, instruction, false, {"recommended": true})

func _buyer_offer(amount: int) -> Dictionary:
	if amount <= 0:
		return _result("请输入有效的出售报价。", "提醒玩家给出具体售价。", false)
	var item_id := str(current_guest.get("recommended_item_id", ""))
	if item_id.is_empty():
		return _result("请先从库存中选择并推荐一件物品。", "掌柜还没有正式推荐物品，暂时不能谈成交价。", false)
	var item := get_inventory_item(item_id)
	if item.is_empty():
		return _result("该物品已不在库存。", "物品无法成交，请玩家重新选择。", false)
	var match_level := get_match_level(item, current_guest)
	var max_price := int(current_guest["need"]["max_price"])
	if match_level == "weak":
		max_price = int(max_price * 0.72)
	elif match_level == "none":
		max_price = 0
	if amount <= max_price and max_price > 0:
		money += amount
		inventory.erase(item)
		ledger.append({"type": "出售", "item": item["title"], "amount": amount, "guest": current_guest["name"]})
		current_guest["completed"] = true
		current_guest["outcome"] = "以 ¥%d 成交，玩家售出%s" % [amount, item["title"]]
		decisions.append({"guest": current_guest["name"], "decision": "出售", "amount": amount, "item": item["title"], "authentic": item["authentic"]})
		return _result("成交：收到 ¥%d，《%s》离开库存。" % [amount, item["title"]], "接受¥%d售价并完成交易。自然表达成交，遵守钱货两清；不要鉴定物件或揭示任何隐藏问题。" % amount, true)
	_consume_patience(1)
	if int(current_guest["patience"]) <= 0:
		current_guest["completed"] = true
		current_guest["outcome"] = "售价超出接受范围且耐心耗尽，买家离店"
		decisions.append({"guest": current_guest["name"], "decision": "高价谈崩", "amount": amount, "item": item["title"]})
		return _result("买家拒绝 ¥%d 的售价并离店。" % amount, "拒绝售价，明确结束交易并离店。不要说出精确隐藏预算。", true)
	return _result("买家没有接受 ¥%d 的售价。" % amount, "拒绝¥%d售价，依据需求与预算表现犹豫或还价意愿，但不要直接泄露未授权预算上限。%s" % [amount, _patience_instruction()], false)

func _smalltalk_result() -> Dictionary:
	return _result("这段交谈没有直接解锁新的权威信息。", "自然回应玩家，但不能新增来源、预算、年代、真假、动机或其他未授权事实。可以把话题轻轻引回当前交易。%s" % _patience_instruction(), false)

func _consume_patience(amount: int) -> void:
	current_guest["patience"] = max(0, int(current_guest.get("patience", 5)) - amount)

func _patience_instruction() -> String:
	var patience := int(current_guest.get("patience", 5))
	if patience >= 4:
		return "当前态度从容。"
	if patience >= 2:
		return "当前态度谨慎，回答应稍短。"
	return "当前已经不耐烦，回答应简短直接。"

func _result(system_text: String, llm_instruction: String, completed: bool, extra: Dictionary = {}) -> Dictionary:
	var result := {"system_text": system_text, "llm_instruction": llm_instruction, "completed": completed}
	result.merge(extra, true)
	return result

func select_item(item_id: String) -> void:
	selected_item_id = item_id

func get_inventory_item(item_id: String) -> Dictionary:
	for item in inventory:
		if item.get("id") == item_id:
			return item
	return {}

func visible_item_record(item_id: String) -> Dictionary:
	var item := get_inventory_item(item_id)
	if item.is_empty() and current_guest.get("role") == "seller" and current_guest.get("role_revealed", false):
		var guest_item: Dictionary = current_guest.get("item", {})
		if guest_item.get("id") == item_id:
			item = guest_item
	if item.is_empty():
		return {}
	var record := {
		"title": str(item["title"]), "category": str(item["category"]),
		"provenance": str(item.get("public_provenance", "")),
		"clues": item.get("revealed_clues", []).duplicate(),
		"appraisals": [],
	}
	for entry in appraisal_history:
		if entry.get("item_id") == item_id:
			record["appraisals"].append({"context": entry["context"], "probability": entry["probability"], "clues": entry["clues"].duplicate()})
	return record

func get_match_level(item: Dictionary, guest: Dictionary) -> String:
	if guest.get("role") != "buyer":
		return "none"
	var wanted := str(guest["need"]["category"])
	if str(item["category"]) == wanted:
		return "exact"
	if wanted == "文房" and str(item["category"]) == "书画":
		return "weak"
	if wanted == "书画" and str(item["category"]) == "文房":
		return "weak"
	return "none"

func _match_label(level: String) -> String:
	match level:
		"exact": return "较高匹配"
		"weak": return "弱匹配"
		_: return "明显不匹配"

func visible_guest_role() -> String:
	if current_guest.is_empty():
		return ""
	if not current_guest.get("role_revealed", false):
		return "尚未说明"
	if current_guest.get("role") == "seller":
		return "来店出售"
	return "来店购买"

func patience_label() -> String:
	if current_guest.is_empty():
		return "—"
	var patience := int(current_guest.get("patience", 5))
	if patience >= 4:
		return "从容"
	if patience >= 2:
		return "谨慎"
	return "不耐"

func closing_summary() -> Dictionary:
	var spent := 0
	var earned := 0
	for entry in ledger:
		var amount := int(entry["amount"])
		if amount < 0:
			spent += -amount
		else:
			earned += amount
	return {
		"money": money,
		"spent": spent,
		"earned": earned,
		"net": earned - spent,
		"inventory_count": inventory.size(),
		"appraisals": appraisal_history.size(),
		"decisions": decisions.duplicate(true),
	}

func design_review_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for guest in guests:
		var truth := str(guest.get("hidden_state", "常规来客"))
		if guest.get("role") == "seller":
			var item: Dictionary = guest["item"]
			truth += "｜器物权威状态：%s，市场参考 ¥%d。" % ["真品" if item["authentic"] else "非真品", item["market_value"]]
		else:
			truth += "｜真实预算上限 ¥%d。" % int(guest["need"]["max_price"])
		rows.append({
			"name": guest["name"],
			"role": "判断挑战" if guest.get("challenge", false) else "常规经营",
			"truth": truth,
			"missable": "；".join(guest.get("missable", [])),
			"outcome": guest.get("outcome", "未处理"),
		})
	return rows
