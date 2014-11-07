namespace :db do
  task :wipe => :environment do
    desc 'Drops db and sets everything back up'
    puts "Dropping db..."
    Rake::Task["db:drop"].invoke
    puts "Creating db..."
    Rake::Task["db:create"].invoke
    puts "Migrating db..."
    Rake::Task["db:migrate"].invoke
    puts "Seeding db..."
    Rake::Task["db:seed"].invoke
  end
end