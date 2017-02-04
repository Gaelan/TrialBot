class CreateWikiEntries < ActiveRecord::Migration[5.0]
  def change
    create_table :wiki_entries do |t|
    	t.string 'server_id'
    	t.string 'name'
    	t.string 'text'
    end
  end
end
