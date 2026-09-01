class User < ApplicationRecord
  has_secure_password

  ROLES = %w[admin member].freeze

  has_many :owned_projects, class_name: "Project", foreign_key: :owner_id

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :role, inclusion: { in: ROLES }

  scope :admins, -> { where(role: "admin") }

  def admin?
    role == "admin"
  end
end
