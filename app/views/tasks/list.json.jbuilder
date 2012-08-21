json.valid_new_task_states valid_new_task_states
json.tasks @tasks do |json, task|
  json.partial! 'task', task: task
end
