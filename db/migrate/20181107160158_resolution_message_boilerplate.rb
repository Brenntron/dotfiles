class ResolutionMessageBoilerplate < ActiveRecord::Migration[5.1]
  def change
    create_table :resolution_message_templates do |t|
      t.string :name
      t.text :description, limit: 65535
      t.text :body, limit: 65535

      t.timestamps
    end
  end
end
