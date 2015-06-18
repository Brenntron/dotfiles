class RunImportRulesWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    xmlrpc = Bugzilla::Bug.new(bugzilla_session)
    last_updated = Bug.get_last_import_all()
    new_bugs = xmlrpc.search(last_change_time: last_updated) #then we need to go over all new bugs and import them
    Bug.import(xmlrpc,new_bugs)
  end
end