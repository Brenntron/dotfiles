class DigitalSigners < ActiveRecord::Migration[5.2]
  def change
    create_table :digital_signers do |t|
      t.string :issuer
      t.string :subject
      t.datetime :valid_from
      t.datetime :valid_to
      t.integer :file_reputation_dispute_id

      t.timestamps
    end
  end
end
