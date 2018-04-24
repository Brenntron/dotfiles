class CreateEmailTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :email_templates do |t|
      t.integer      :user_id
      t.string       :template_name
      t.text         :body
      t.timestamps
    end
  end
end
