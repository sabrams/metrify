ActiveRecord::Schema.define(:version => 0) do
  create_table :metrics, :force => true do |t|
    t.datetime :finish_time
    t.integer :number_of_hours
    t.string :stat_hash
  end
  
  create_table :invalid_metrics, :force => true do |t|
    t.datetime :finish_time
    t.integer :number_of_hours
    t.string :stat_hash
  end
end