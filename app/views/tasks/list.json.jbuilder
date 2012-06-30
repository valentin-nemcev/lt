json.array! @tasks do |json, task|
  json.id task.id

  json.parent_id task.projects.first.try(:id)

  json.body task.objective
  json.completed task.completed?
  json.actionable task.actionable?
end
