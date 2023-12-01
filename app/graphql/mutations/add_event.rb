module Mutations
    class AddEvent < Mutations::BaseMutation
        argument :name, String, required: true
        argument :descritpin, String, required: true
        argument :cover_image, ApolloUploaderServer::Upload required: true

        type Types::EventType, null: true
        field :event, Types::EventType, null: true
        field :errors, [String], null: true    
        
        def resolve(input)
            file = input[:image]
            blob = ActiveStorage::Blob.create_and_upload!(
                io: file,
                filename: file.original_filename,
                content_type: file.content_type
            )
        
            event = Event.new(
                name: input[:name],
                start_date: input[:start_date],
                image: blob
            )
            
            if event.save 
                { event: event } 
            else 
                { errors: event.errors.full_messages }
            end
        end

    end
end