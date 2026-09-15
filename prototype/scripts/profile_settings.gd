class_name ProfileSettings
extends RefCounted
const Store = preload("res://scripts/profile_store.gd")

static func capture(view: Control) -> Dictionary:
	return {"api_key": view.api_key_edit.text, "model": view.model_edit.text,
		"base_url": view.base_url_edit.text, "endpoint": view.endpoint_edit.text,
		"protocol": view.protocol_option.selected, "temperature": view.temperature_edit.text,
		"tokens": view.max_tokens_edit.text, "timeout": view.timeout_edit.text,
		"organization": view.organization_edit.text, "extra_headers": view.extra_headers_edit.text,
		"store_false": view.store_check.button_pressed, "chat_token": view.chat_token_option.selected,
		"allow_development_tests": view.get_meta("allow_development_tests", false), "development_budget_cny": 10}

static func restore(view: Control, data: Dictionary) -> void:
	for entry in [["api_key", "api_key_edit"], ["model", "model_edit"], ["base_url", "base_url_edit"], ["endpoint", "endpoint_edit"], ["temperature", "temperature_edit"], ["tokens", "max_tokens_edit"], ["timeout", "timeout_edit"], ["organization", "organization_edit"], ["extra_headers", "extra_headers_edit"]]:
		if data.get(entry[0]) is String: view.get(entry[1]).text = data[entry[0]]
	view.protocol_option.select(clampi(int(data.get("protocol", 0)), 0, 1))
	view.chat_token_option.select(clampi(int(data.get("chat_token", 0)), 0, 1))
	view.store_check.button_pressed = data.get("store_false", false) == true
	view.set_meta("allow_development_tests", data.get("allow_development_tests", false) == true)
	if view.has_meta("development_control"):
		view.get_meta("development_control").set_pressed_no_signal(view.get_meta("allow_development_tests", false))

static func add_controls(view: Control) -> void:
	var box: Control = view.start_button.get_parent().get_parent()
	view.set_meta("named_profiles", {})
	var profile_name := LineEdit.new()
	profile_name.placeholder_text = "配置名称，例如 DeepSeek / Kimi Code"
	profile_name.text = "默认配置"
	box.add_child(profile_name)
	view.set_meta("profile_name_control", profile_name)
	var kimi_template: Button = view._make_button("填写 Kimi Code 参数模板（需另填对应Key）", false)
	box.add_child(kimi_template)
	kimi_template.pressed.connect(func():
		profile_name.text = "Kimi Code"
		restore(view, {"api_key": "", "base_url": "https://api.kimi.com/coding/v1", "endpoint": "/chat/completions", "protocol": 1, "model": "kimi-for-coding", "temperature": "", "organization": "", "extra_headers": "", "tokens": "2048", "timeout": "60", "allow_development_tests": false})
		view.setup_status.text = "已填写Kimi Code模板，尚未保存或请求。Kimi Code为编程服务；游戏产品调用请核对账户用途，Kimi开放平台使用独立Key。")
	view.set_meta("allow_development_tests", true)
	var row := HBoxContainer.new()
	box.add_child(row)
	var save_button: Button = view._make_button("加密保存此接入配置", true)
	row.add_child(save_button)
	save_button.pressed.connect(func():
		var name_value := profile_name.text.strip_edges()
		if name_value.is_empty():
			view.setup_status.text = "请先给配置命名。"
			return
		var profiles: Dictionary = view.get_meta("named_profiles", {}).duplicate(true)
		profiles[name_value] = capture(view)
		var data := capture(view)
		data["named_profiles"] = profiles
		data["active_profile"] = name_value
		var result := Store.operate("save", data)
		if result.get("ok", false):
			view.set_meta("named_profiles", profiles)
			view.set_meta("active_profile", name_value)
		view.setup_status.text = "已使用当前Windows用户保护保存，重启可恢复。" if result.get("ok", false) else "保存失败，未回退为明文。")
	var forget: Button = view._make_button("删除本机已保存凭据", false)
	row.add_child(forget)
	forget.pressed.connect(func():
		var result := Store.operate("forget")
		if result.get("ok", false):
			view.api_key_edit.clear()
			view.set_meta("named_profiles", {})
			view.set_meta("active_profile", "")
		view.setup_status.text = "已删除本机保存的配置和Key。删除不可撤销，请需要时重新填写。" if result.get("ok", false) else "删除失败，请检查本机权限。")
	var note := Label.new()
	note.text = "配置只在本机受保护保存，不进入游戏存档。开发联调累计上限¥10；玩家手动游玩的调用另由服务商计费。"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	if Store.exists():
		var result := Store.operate("load")
		if result.get("ok", false) and result.get("profile") is Dictionary:
			restore(view, result["profile"])
			var data: Dictionary = result["profile"]
			var profiles: Dictionary = data.get("named_profiles", {})
			var active := str(data.get("active_profile", "原有配置"))
			if profiles.is_empty(): profiles[active] = capture(view)
			view.set_meta("named_profiles", profiles)
			view.set_meta("active_profile", active)
			profile_name.text = active
			view.setup_status.text = "已恢复本机接入配置。尚未发起任何模型请求。"
		else: view.setup_status.text = "已有保护文件，但当前Windows用户未能解密，请重新填写。"
	var development := CheckButton.new()
	view.set_meta("development_control", development)
	development.text = "允许使用已存配置进行开发联调（累计上限¥10）"
	development.button_pressed = view.get_meta("allow_development_tests", false)
	development.toggled.connect(func(value): view.set_meta("allow_development_tests", value))
	box.add_child(development)
	var explanation := Label.new()
	explanation.text = "仅记录联调许可，不会自动发起测试。修改后请点击加密保存；取消后不再允许使用此配置联调。"
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(explanation)

static func switch_to(view: Control, profile_name: String, testing := false) -> bool:
	if view.awaiting_llm: return false
	var profiles: Dictionary = view.get_meta("named_profiles", {})
	if not profiles.has(profile_name): return false
	var data: Dictionary = profiles[profile_name].duplicate(true)
	data["named_profiles"] = profiles
	data["active_profile"] = profile_name
	var result := Store.operate("save", data, testing)
	if not result.get("ok", false): return false
	restore(view, profiles[profile_name])
	view.set_meta("active_profile", profile_name)
	view.get_meta("profile_name_control").text = profile_name
	view._configure_llm()
	return true

static func add_switcher(view: Control) -> void:
	view._paragraph("模型配置 · 当前：" + str(view.get_meta("active_profile", "未命名")), 20)
	var profiles: Dictionary = view.get_meta("named_profiles", {})
	for name_value in profiles:
		var target := str(name_value)
		var button: Button = view._modal_button("切换到 " + target, func():
			var ok := switch_to(view, target)
			view._paragraph("已切换到 %s，下一句使用该配置。" % target if ok else "切换未完成，请等当前回复结束，或检查配置保存权限。"))
		button.disabled = view.awaiting_llm
	view._paragraph("新增配置：返回API配置页，填写另一服务的参数与Key，使用新名称加密保存。以后可在这里直接切换。", 14)
