class Company < ApplicationRecord
  has_many :contacts, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :activities, as: :trackable, dependent: :destroy

  enum :status, { new_company: 0, processing: 1, enriched: 2, completed: 3 }

  validates :name, presence: true
  validates :domain, presence: true, uniqueness: true

  after_create :create_enrich_task

  private

  def create_enrich_task
    Task.create!(
      task_type: "enrich_company",
      payload: { company_id: id, domain: domain }
    )
  end
end
