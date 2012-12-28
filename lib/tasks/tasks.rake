namespace :tasks do
  desc "Recomputes computed attribute values for all tasks stored in DB"
  task :recompute_attributes => :environment do
    User.all.each do |user|
      Task::Storage.new(user: user).recompute_attributes!
    end
  end
end
