class EnbiggenReferenceData < ActiveRecord::Migration[5.1]
  def change
    change_column :references, :reference_data, :text
  end
end
