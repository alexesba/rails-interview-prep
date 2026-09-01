class Comment < ApplicationRecord
  belongs_to :author, class_name: "User"
  belongs_to :task

  validates :body, presence: true, length: { minimum: 1, maximum: 5000 }
end
