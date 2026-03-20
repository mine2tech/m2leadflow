class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.get(key, default = nil)
    find_by(key: key)&.value || default
  end

  def self.set(key, value)
    setting = find_or_initialize_by(key: key)
    setting.update!(value: value.to_s)
  end

  def self.followup_delay_days
    get("followup_delay_days", ENV.fetch("DEFAULT_FOLLOWUP_DELAY_DAYS", "3")).to_i
  end

  def self.max_followups
    get("max_followups", ENV.fetch("DEFAULT_MAX_FOLLOWUPS", "3")).to_i
  end

  def self.auto_send_followups?
    get("auto_send_followups", "false") == "true"
  end

  def self.followup_use_ai?
    get("followup_use_ai", "true") == "true"
  end
end
