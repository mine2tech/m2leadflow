class Task < ApplicationRecord
  VALID_TYPES = %w[enrich_company draft_email company_research classify_reply].freeze

  belongs_to :user, optional: true

  enum :status, { pending: 0, claimed: 1, in_progress: 2, completed: 3, failed: 4 }

  validates :task_type, presence: true, inclusion: { in: VALID_TYPES }
  validates :payload, presence: true

  scope :next_pending, -> { pending.order(:created_at).limit(1) }

  def claim!
    update!(status: :claimed)
  end

  def start!
    update!(status: :in_progress)
  end

  def complete!(result_data)
    update!(status: :completed, result: result_data)
  end

  def fail!(error_message)
    with_lock do
      self.attempts += 1
      self.error = error_message
      self.status = attempts < max_attempts ? :pending : :failed
      save!
    end
  end
end
