class CreateEmailTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :email_templates do |t|
      t.string       :template_name
      t.text         :description
      t.text         :body
      t.timestamps
    end
  end
end
