namespace :db do
  desc "Dumps current development database to db/dumps"
  task :dump => :environment do
    config   = Rails.configuration.database_configuration
    database = config[Rails.env]["database"]

    file = "db/dumps/#{Time.now.strftime('%FT%R')}_#{database}.sql"

    %x(mkdir -p db/dumps && mysqldump #{database} > #{file})
  end

end
