include(Rails.application.routes.url_helpers)

module Types
  class Types::EventType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :description, String, null: false
    field :start_date, GraphQL::Types::ISO8601DateTime, null: false
    field :cover_image_url, String, null: true

    def cover_image_url
      if object.cover_image.present?
        rails_blob_path(object.cover_image, only_path: true)
      end
    end

  end
end