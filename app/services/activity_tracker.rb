class ActivityTracker
  def self.track(trackable, action:, user: nil, metadata: {})
    Activity.create!(
      trackable: trackable,
      user: user,
      action: action,
      metadata: metadata
    )
  end
end
