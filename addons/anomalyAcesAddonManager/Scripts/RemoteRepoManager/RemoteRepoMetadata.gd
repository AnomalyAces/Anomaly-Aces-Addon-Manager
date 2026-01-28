class_name RemoteRepoMetadata extends Object

var addon_file: String
var branch_last_commit: String
var download_url: String



func _to_string() -> String:
	return "RemoteRepoMetadata[addon_file: %s, branch_last_commit: %s, download_url: %s]"  % [addon_file, branch_last_commit, download_url]