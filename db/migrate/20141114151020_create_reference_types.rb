class CreateReferenceTypes < ActiveRecord::Migration
  def change
    create_table :reference_types do |t|
      t.string :name
      t.string :description
      t.string :validation
      t.string :bugzilla_format
      t.string :example
      t.string :rule_format
      t.string :url
    end
  end
end
