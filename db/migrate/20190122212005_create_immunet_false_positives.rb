class CreateImmunetFalsePositives < ActiveRecord::Migration[5.2]
  def change
    create_table :immunet_false_positives do |t|
      t.string :version
    end
  end
end

