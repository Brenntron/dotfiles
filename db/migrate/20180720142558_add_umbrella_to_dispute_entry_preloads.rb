class AddUmbrellaToDisputeEntryPreloads < ActiveRecord::Migration[5.1]
  def change
    add_column :dispute_entry_preloads, :umbrella, :longtext
  end
end
