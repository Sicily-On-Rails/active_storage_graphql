```ruby
create_table :active_storage_blobs do |t|
  t.string   :key,        null: false
  t.string   :filename,   null: false
  t.string   :content_type
  t.text     :metadata
  t.string   :service_name, null: false
  t.bigint   :byte_size,  null: false
  t.string   :checksum,   null: false

  ...
end
```

```ruby
create_table :active_storage_attachments do |t|
  t.string     :name,     null: false
  t.references :record,   null: false, polymorphic: true, index: false
  t.references :blob,     null: false

  ...
end
```

```ruby
t.references :record, null: false, polymorphic: true, index: false
```

```ruby
def acceptable_image
  return unless main_image.attached?

  unless main_image.blob.byte_size <= 1.megabyte
    errors.add(:main_image, "is too big")
  end
end
```

```ruby
def acceptable_image
  return unless main_image.attached?

  unless main_image.blob.byte_size <= 1.megabyte
    errors.add(:main_image, "is too big")
  end

  acceptable_types = ["image/jpeg", "image/png"]
  unless acceptable_types.include?(main_image.content_type)
    errors.add(:main_image, "must be a JPEG or PNG")
  end
end
```