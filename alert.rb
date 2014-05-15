class Alert < Sequel::Model
  DB.create_table? :alerts do
    primary_key :id
    Text        :payload
    Timestamp   :created_at
  end
  plugin :serialization, :json, :payload
end
