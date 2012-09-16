json.task_creations @tasks do |json, task|
  json.(task, :id, :type)
  json.created_on task.created_on.httpdate
end

json.task_updates @revisions do |json, revision|
  # TODO: User revision.task_id
  json.task_id revision.owner.id
  json.(revision, :attribute_name, :updated_value)
  json.updated_on revision.updated_on.httpdate
end
