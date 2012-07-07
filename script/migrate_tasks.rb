include ActionView::Helpers::TextHelper

deleted = Task::Records::Relation.delete_all
puts "Deleted #{pluralize(deleted, 'relation')} from DB"

deleted = Task::Records::Task.delete_all
puts "Deleted #{pluralize(deleted, 'task')} from DB"

User.all.each do |user|
  puts "\nMigrating tasks for user #{user.login}"

  legacy_mapper = Task::LegacyMapper.new.for_user user
  tasks = legacy_mapper.fetch_all dont_persist: true

  puts "Fetched #{pluralize(tasks.length, 'task')} with legacy mapper"

  mapper = Task::Mapper.new user: user

  puts "Storing tasks with new mapper..."
  stats = mapper.store_all tasks
  puts "Stored. Stats:"
  stats.each_pair do |f, v|
    puts "#{f}: #{v}"
  end

end
puts "Stored task records:"
Task::Records::Task.all.each { |t| p t; p t.objective_revisions }

puts "Stored task relation records:"
Task::Records::Relation.all.each { |t| p t }


