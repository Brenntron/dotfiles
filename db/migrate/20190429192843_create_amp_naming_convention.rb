class CreateAmpNamingConvention < ActiveRecord::Migration[5.2]
  def change
    create_table :amp_naming_conventions do |t|
      t.string :pattern
      t.string :example
      t.string :engine
      t.text :engine_description
      t.text :notes
      t.text :public_notes
      t.string :contact
    end
  end
end
