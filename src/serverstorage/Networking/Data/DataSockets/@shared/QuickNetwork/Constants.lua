return {
    WRITE_COOLDOWN_INTERVAL = 7,
	MAX_PCALL_TRIES = 5,
    MAX_DATA_CHARACTERS = 4_000_000,
    MAX_KEY_CHARACTERS = 50,
    MAX_DATASTORE_NAME_CHARACTERS = 50,
    INVALID_ARGUMENT_TYPE = "Bad argument to #%s: expected %s, got %s",
	BACKUP_DATASTORE_NAME = "%s/Backup",
	
	DATA_ERRORLOADSIGNAL_RETURN_VALUES = {
		loadbackup = true,
		table = true,
		cancel = true
	},
	
	DATA_CORRUPTIONLOADSIGNAL_RETURN_VALUES = {
		loadbackup = true,
		table = true,
		cancel = true
	},
}