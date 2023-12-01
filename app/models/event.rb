class Event < ApplicationRecord
    has_one_attached :cover_image
    has_many :event_images

    validates :name, presence: true


    validate :accetable_image

    def accetable_image
        return unless cover_image.attached?

        unless cover_image.blob.byte_size <= 1.megabyte
            errors.add(:cover_image, "is too big")
        end

        accetable_type = ["image/jpeg", "image/png"]
        unless accetable_type.include?(cover_image.content_type)
            errors.add(:cover_image, "must be a JPEG or PNG")
        end

    end


end
