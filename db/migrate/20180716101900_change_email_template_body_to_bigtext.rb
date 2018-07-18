class ChangeEmailTemplateBodyToBigtext < ActiveRecord::Migration[5.1]
  def change
    change_column :rulehit_resolution_mailer_templates, :body, :longtext
  end
end
