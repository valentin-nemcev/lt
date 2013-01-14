namespace :tasks do
  desc "Recomputes computed attribute values for all tasks stored in DB"
  task :recompute_attributes => :environment do
    user = User
    if ENV['user']
      user = user.where :login => ENV['user']
    end
    user.all.each do |user|
      puts "Recomputing tasks for #{user.login}"
      storage = Task::Storage.new(user: user)
      storage.recompute_attributes!
      revs = storage.graph.tasks.collect_concat(&:all_computed_attribute_revisions)
      puts "Recomputed #{revs.size} revisions"
    end
  end
end
