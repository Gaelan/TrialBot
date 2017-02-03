class CreateChannelConfig < ActiveRecord::Migration[5.0]
  def change
    create_table :channel_configs do |t|
    	t.string :channel_id
    	t.boolean :short_reports, default: false
    	t.boolean :tr_update, default: false
    end
  end
end
