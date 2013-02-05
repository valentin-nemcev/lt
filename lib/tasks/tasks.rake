namespace :tasks do
  desc "Recomputes computed attribute values for all tasks stored in DB"
  task :recompute_attributes => :environment do
    user = User
    if ENV['user']
      user = user.where :login => ENV['user']
    end
    user.all.each do |user|
      storage = Task::Storage.new(user: user)
      revs = storage.fetch_all.tasks.collect_concat(&:all_computed_attribute_revisions)
      puts "Recomputing #{revs.size} task revisions for #{user.login}"
      storage.recompute_attributes!
      revs = storage.graph.tasks.collect_concat(&:all_computed_attribute_revisions)
      puts "Recomputed #{revs.size} revisions"
    end
  end

  desc "Sets completion status and date for all tasks (one time)"
  task :complete => :environment do
    user = User
    if ENV['user']
      user = user.where :login => ENV['user']
    end
    user.all.each do |user|
      puts "Completing tasks for #{user.login}"
      storage = Task::Storage.new(user: user)
      graph = storage.fetch_all
      graph.tasks.each do |task|
        subtasks_done = false
        task.attribute_revisions(:for => :computed_state).reverse.find do |rev|
           rev.updated_value == :subtasks_done
        end.try do |rev|
          revs = task.update_attributes({:state => :done}, :on => rev.update_date)
          unless revs.empty?
            puts "#{task.inspect} completed on #{rev.update_date}"
          end
        end
        task.attribute_revisions(:for => :state).last.try do |rev|
           next unless rev.updated_value.in? [:done, :canceled]
           next if task.completed?
           task.completion_date = rev.update_date
           puts "#{task.inspect} #{rev.updated_value} on #{rev.update_date}"
        end
      end
      storage.store_graph
    end
  end
end
