Rails.application.config.active_record.encryption.primary_key = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY", "rYaUsUcRI06pMSRUa5WeIzglw9eeId4r")
Rails.application.config.active_record.encryption.deterministic_key = ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY", "lWNAnSjkt8o20ZsHAIYxpkirPhi0pqOr")
Rails.application.config.active_record.encryption.key_derivation_salt = ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT", "0N9AakjkksI4ag3BlOPXeJQ6dyPkaiK6")
