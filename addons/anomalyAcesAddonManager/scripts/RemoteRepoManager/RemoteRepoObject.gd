class_name RemoteRepoObject extends Object


var owner: String
var repo: String
var isRelease: bool
var version: String
var branch: String
var dependencies: Array[RemoteRepoObject]
var dict: Dictionary[String, RemoteRepoObject]



func _to_string() -> String:
    return "RemoteRepoObject[owner: %s, repo: %s, isRelease: %s, version: %s, branch: %s, dependencies: %s"  \
        % [owner, repo, isRelease, version, branch, str(dependencies)]





