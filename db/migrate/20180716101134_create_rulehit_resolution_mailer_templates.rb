class CreateRulehitResolutionMailerTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :rulehit_resolution_mailer_templates do |t|
      t.string :mnemonic
      t.string :to
      t.string :cc
      t.string :subject
      t.string :body

      t.timestamps
    end
  end
end
