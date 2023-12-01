=begin
query {
    events{
        id
        name
        description
        imageUrl
    }
}
=end
include(Rails.application.routes.url_helpers)

module Types
    class Types::EventType < Type::BaseObject
        field :id, ID, null: false
        field :name, String, null: false
        field :description, String, null: false
        field :image_url, String, null: true

        def image_url
            if object.image.present?
                rails_blob_path(object.image, only_path: true)
            end
        end
    end
end