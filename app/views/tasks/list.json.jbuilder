json.array! @tasks do |json, task|
  json.(task, :id, :parent_id, :position, :body)
  json.completed task.completed?
  json.actionable task.actionable?
end
