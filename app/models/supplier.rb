class Supplier < ApplicationRecord
  has_many :parts, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
