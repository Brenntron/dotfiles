class CreateReferencesAndRules < ActiveRecord::Migration[4.2]
  def change
    create_table :references do |t|
      t.string :reference_data
      t.belongs_to :reference_type, index: true
      t.timestamps
    end
    # add_reference :references, :rule, index: true
    # add_reference :references, :bug, index: true

    create_table :references_rules, id: false do |t|
      t.belongs_to :reference, index: true
      t.belongs_to :rule, index: true
    end

  end

end
