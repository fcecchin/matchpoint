class Tournament < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :registrations, dependent: :destroy
  has_many :players, through: :registrations, source: :player
  has_many :matches, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :start_at, presence: { message: "is blank or invalid" }
  validates :end_at, presence: { message: "is blank or invalid" }
  validates :owner, presence: true

  validate :validate_date_order

  scope :upcoming, -> { where("end_at >= ?", DateTime.now) }
  scope :past, -> { where("end_at < ?", DateTime.now) }

  scope :for_player_or_host, -> (user) {
    left_outer_joins(:registrations).where("registrations.player_id = ? OR owner_id = ?", user.id, user.id)
  }

  def hosted_by?(user)
    user == owner
  end

  def registration_open?
    start_at >= DateTime.now
  end

  def ready_for_match_generation_by?(user)
    hosted_by?(user) && players.count > 1
  end

  private

  def validate_date_order
    if start_at && end_at && start_at >= end_at
      errors[:start_at] << "must be earlier than end date"
    end
  end
end
