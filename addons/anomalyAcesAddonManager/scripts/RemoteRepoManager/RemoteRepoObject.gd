class_name RemoteRepoObject extends Object


var owner: String
var repo: String
var isRelease: bool
var version: String
var branch: String
var branch_last_commit: String
var dependencies: Array[RemoteRepoObject]
var dict: Dictionary[String, RemoteRepoObject]



func _to_string() -> String:
    return "RemoteRepoObject[owner: %s, repo: %s, isRelease: %s, version: %s, branch: %s, branch_last_commit: %s, dependencies: %s"  \
        % [owner, repo, isRelease, version, branch, branch_last_commit, str(dependencies)]





