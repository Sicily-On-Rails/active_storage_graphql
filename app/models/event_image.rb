class EventImage < ApplicationRecord
  belongs_to :event
  has_one_attached :img
end
