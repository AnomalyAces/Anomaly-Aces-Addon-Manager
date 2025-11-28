class_name RemoteRepoMetadata extends Object

var branch_last_commit: String
var download_url: String



func _to_string() -> String:
	return "RemoteRepoMetadata[branch_last_commit: %s, download_url: %s"  % [branch_last_commit, download_url]