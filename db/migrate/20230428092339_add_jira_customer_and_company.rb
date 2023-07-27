class AddJiraCustomerAndCompany < ActiveRecord::Migration[6.1]
  def up
    company = Company.create(name: 'ACE JIRA IMPORTS', created_at: Time.now, updated_at: Time.now)
    Customer.create(company_id: company.id, email: 'ace-jira.gen@cisco.com', name: 'ACE JIRA IMPORTS', created_at: Time.now, updated_at: Time.now)
  end

  def down
    company = Company.where(name: 'ACE JIRA IMPORTS').first
    Customer.where(company_id: company.id).destroy_all
    company.destroy
  end
end
