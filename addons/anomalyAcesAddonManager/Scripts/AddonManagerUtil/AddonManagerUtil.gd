@tool
class_name AddonManagerUtil extends Object

static func get_github_pat() -> GithubPATInfo:
    var pat_info: GithubPATInfo = GithubPATInfo.new()
    if AceFileUtil.File.file_exists(AcePluginGithubPATView.GITHUB_PAT_FILE_PATH):
        var file: FileAccess = AceFileUtil.File.create_file(AcePluginGithubPATView.GITHUB_PAT_FILE_PATH, FileAccess.READ)
        var content: String = file.get_as_text()
        file.close()

        var pat_res: AceDeserializeResult = AceSerialize.deserialize(content, GithubPATInfo)

        if pat_res.error != OK:
            AceLog.printLog(["Failed to deserialize PAT info from file. Error code: ", pat_res.error], AceLog.LOG_LEVEL.ERROR)
            return pat_info
        
        pat_info = pat_res.data

        if pat_info != null:
            AceLog.printLog(["Loaded Personal Access Token from file. Expiration Date: ", pat_info.expiration_date], AceLog.LOG_LEVEL.INFO)
            return pat_info
        else:
            AceLog.printLog(["Failed to deserialize Personal Access Token info from file."], AceLog.LOG_LEVEL.ERROR)
            return GithubPATInfo.new()
    else:
        AceFileUtil.File.create_file(AcePluginGithubPATView.GITHUB_PAT_FILE_PATH, FileAccess.WRITE) # Create an empty file if it doesn't exist.
        AceLog.printLog(["No existing Personal Access Token found. Please enter a token and click 'Check Token'."], AceLog.LOG_LEVEL.INFO)
        return pat_info