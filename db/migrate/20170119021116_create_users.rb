class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
    	t.boolean :verified
    	t.string :discord_id
    	t.string :tos_name
    end
  end
end
