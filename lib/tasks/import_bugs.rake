require 'pry'
namespace :bugs do

  task :import_all, [:current_user, :xmlrpc] do |t, args|

    desc "imports all bugs that were updated in the last 24 hours"
    Rails.logger.info "Importing bugs..."

    current_user = args[:current_user]

    bug_ids_to_update = Bug.where("updated_at > ? ",(Time.now - 24.hours)).map{|a| a.id}
    import_type = "import"
    xmlrpc = args[:xmlrpc]
    xmlrpc_token = xmlrpc.token


    bug_ids_to_update.each do |id|
      puts "importing bug #{id}"
      xmlrpc_bug = Bugzilla::Bug.new(xmlrpc)
      new_bug = xmlrpc_bug.get(id)
      bug = Bug.bugzilla_import(current_user, xmlrpc_bug, xmlrpc_token, new_bug).first
    end
  end



end
