class CreateEventImages < ActiveRecord::Migration[7.0]
  def change
    create_table :event_images do |t|
      t.string :title
      t.string :alt
      t.references :event, null: false, foreign_key: true

      t.timestamps
    end
  end
end
