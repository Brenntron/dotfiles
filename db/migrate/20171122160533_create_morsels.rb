class CreateMorsels < ActiveRecord::Migration[5.1]
  def change
    create_table :morsels do |t|
      t.text        :output
      t.timestamps
    end
  end
end
