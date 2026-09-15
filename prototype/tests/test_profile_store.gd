extends SceneTree
const Store = preload("res://scripts/profile_store.gd")

func _init() -> void:
	var dummy := {"api_key": "dummy-not-a-real-key-中文", "base_url": "http://127.0.0.1", "model": "fixture", "extra_headers": "X-Dummy: dummy-value"}
	var saved := Store.operate("save", dummy, true)
	assert(saved.get("ok", false), "Protected save failed")
	var loaded := Store.operate("load", {}, true)
	assert(loaded.get("ok", false) and loaded.get("profile") == dummy, "Protected reload mismatch")
	var bytes := FileAccess.get_file_as_bytes("user://test_api_profile.dpapi")
	assert(bytes.size() > 64, "DPAPI protected payload must be present")
	var ascii := bytes.get_string_from_ascii()
	assert(not ascii.contains("dummy-not-a-real-key") and not ascii.contains("X-Dummy"), "Ciphertext must not contain plaintext fields")
	assert(Store.operate("forget", {}, true).get("ok", false), "Forget failed")
	assert(not Store.exists(true), "Dummy credential must be removed")
	print("PASS: Windows protected profile save/load/forget; dummy credential only, no real secret printed")
	quit(0)
