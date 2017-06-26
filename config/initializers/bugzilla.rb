
case
  when Rails.env.production?
    Rails.configuration.bugzilla_host = 'bugzilla.vrt.sourcefire.com'
  else
    Rails.configuration.bugzilla_host = 'bugzillaTest02.vrt.sourcefire.com'
end
Rails.configuration.bugzilla_username = ENV['Bugzilla_login']
Rails.configuration.bugzilla_password = ENV['Bugzilla_secret']
