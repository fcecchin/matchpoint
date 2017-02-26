class Tournament < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :registrations

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :start_at, presence: { message: "is blank or invalid" }
  validates :end_at, presence: { message: "is blank or invalid" }
  validates :owner, presence: true

  validate :validate_date_order

  scope :current_and_upcoming, -> { where("end_at >= ?", DateTime.now) }
  scope :past, -> { where("end_at < ?", DateTime.now) }

  def owned_by(user)
    user == owner
  end

  private

  def validate_date_order
    if start_at && end_at && start_at >= end_at
      errors[:start_at] << "must be earlier than end date"
    end
  end
end
