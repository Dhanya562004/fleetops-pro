class User < ApplicationRecord
  has_secure_password

  enum :role, { admin: "admin", ops_manager: "ops_manager", technician: "technician" }

  has_many :assigned_tickets, class_name: "MaintenanceTicket", foreign_key: :technician_id, dependent: :nullify
  has_many :ticket_comments, dependent: :restrict_with_error
  has_many :ticket_status_events, dependent: :nullify
  has_many :moves, foreign_key: :moved_by_id, dependent: :nullify

  validates :name, :email, presence: true
  validates :email, uniqueness: { case_sensitive: false }
  validates :role, inclusion: { in: roles.keys }
  before_validation { self.email = email.to_s.downcase.strip }
end
