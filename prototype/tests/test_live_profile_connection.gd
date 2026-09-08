extends SceneTree

const Store = preload("res://scripts/profile_store.gd")
const Client = preload("res://scripts/llm_client.gd")

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
		push_error("Development live testing is not enabled in the saved profile")
		quit(1)
		return
	var client := Client.new()
	root.add_child(client)
	await process_frame
	var temperature := -1.0 if str(profile.get("temperature", "")).strip_edges().is_empty() else float(profile["temperature"])
	client.configure(str(profile.get("api_key", "")), str(profile.get("model", "")), str(profile.get("base_url", "")), str(profile.get("endpoint", "")), "chat_completions" if int(profile.get("protocol", 0)) == 1 else "responses", temperature, int(profile.get("tokens", "2048")), float(profile.get("timeout", "45")), str(profile.get("organization", "")), str(profile.get("extra_headers", "")), false, "max_completion_tokens" if int(profile.get("chat_token", 0)) == 1 else "max_tokens")
	var request_error := client.test_connection()
	if request_error != OK:
		push_error("Could not start live connection test: %d" % request_error)
		quit(1)
		return
	var result: Array = await client.response_ready
	var ok: bool = result[0]
	if ok:
		print("PASS: saved DeepSeek profile live connection; response length=%d; no secret or response text printed" % str(result[1]).length())
	else:
		push_error("Saved profile live connection failed: " + str(result[2]))
	quit(0 if ok else 1)
