extends SceneTree

const Store = preload("res://scripts/profile_store.gd")

func _init() -> void:
	var result := Store.operate("load")
	if not result.get("ok", false):
		push_error(str(result.get("error", "无法读取保护配置")))
		quit(1)
		return
	var profile: Dictionary = result["profile"]
	print(JSON.stringify({
		"base_url": profile.get("base_url", ""),
		"endpoint": profile.get("endpoint", ""),
		"protocol": profile.get("protocol", 0),
		"model": profile.get("model", ""),
		"temperature": profile.get("temperature", ""),
		"tokens": profile.get("tokens", ""),
		"timeout": profile.get("timeout", ""),
		"has_api_key": not str(profile.get("api_key", "")).is_empty(),
		"allow_development_tests": profile.get("allow_development_tests", false),
		"development_budget_cny": profile.get("development_budget_cny", 0)
	}))
	quit(0)
