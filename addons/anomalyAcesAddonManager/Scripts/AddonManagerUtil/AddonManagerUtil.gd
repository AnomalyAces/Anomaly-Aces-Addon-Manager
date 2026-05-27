@tool
class_name AddonManagerUtil extends Object


static func convert_utc_string_to_local_datetime_string(utc_datetime_string: String) -> String:
	AceLog.printLog(["Converting UTC datetime string to local datetime string. Input UTC datetime string: %s" % utc_datetime_string], AceLog.LOG_LEVEL.DEBUG)
	# 1. Parse the input string (assumed UTC for this example) into a dictionary.
	# Note: Godot methods for converting from string assume "the same timezone".
	# The input should be a raw datetime string in a common format. Examples:
	# - ISO 8601: 2024-03-15T14:30:00Z or 2024-03-15 14:30:00
	# - Short date + time: 2024-03-15 14:30
	# - Textual month: 15 Mar 2024 2:30pm or Mar 15 2024 14:30:00
	# - Compact: 20240315T143000Z
	# If present, remove trailing timezone markers like "Z" or "UTC" before parsing.
	var datetime_dict = Time.get_datetime_dict_from_datetime_string(
		utc_datetime_string
			.replace("Z", "")
			.replace("UTC", "")
		, false)
	AceLog.printLog(["Parsed datetime dictionary: %s" % datetime_dict], AceLog.LOG_LEVEL.DEBUG)

	# Check for parsing errors
	if datetime_dict.is_empty() or "year" not in datetime_dict:
		AceLog.printLog(["Error: Could not parse input datetime string"], AceLog.LOG_LEVEL.ERROR)
		return ""

	# 2. Convert the dictionary to a Unix timestamp (seconds since epoch).
	var unix_time = Time.get_unix_time_from_datetime_dict(datetime_dict)

	# 3. Get Bias between UTC and local time in seconds
	AceLog.printLog(["Time Zone %s Bias from UTC in hours: %d" % [Time.get_time_zone_from_system()["name"], Time.get_time_zone_from_system()["bias"] / 60]], AceLog.LOG_LEVEL.DEBUG)
	var bias_seconds = Time.get_time_zone_from_system()["bias"] * 60

	# 4. Adjust the Unix timestamp by the bias to get local time
	var local_datetime_string = Time.get_datetime_string_from_unix_time(unix_time + bias_seconds)

	return local_datetime_string


static func convert_utc_string_to_local_formatted_string(utc_datetime_string: String) -> String:
	var local_datetime_string = convert_utc_string_to_local_datetime_string(utc_datetime_string)
	
	# Format the local datetime string to a more user-friendly format
	# Assuming the input is in ISO 8601 format, we can parse it again to extract components
	var datetime_dict = Time.get_datetime_dict_from_datetime_string(local_datetime_string, false)
	
	if datetime_dict.is_empty() or "year" not in datetime_dict:
		AceLog.printLog(["Error: Could not parse local datetime string"], AceLog.LOG_LEVEL.ERROR)
		return ""

	# Format the date and time components into a readable string
	var formatted_string = "%04d-%02d-%02d %02d:%02d:%02d %s" % [
		datetime_dict["year"],
		datetime_dict["month"],
		datetime_dict["day"],
		datetime_dict["hour"],
		datetime_dict["minute"],
		datetime_dict["second"],
		Time.get_time_zone_from_system()["name"]
	]

	return formatted_string
