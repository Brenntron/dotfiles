class AddOnOffToRules < ActiveRecord::Migration[5.1]
  def change
    add_column :rules, :snort_on_off, :string, default: 'on'
  end
end
