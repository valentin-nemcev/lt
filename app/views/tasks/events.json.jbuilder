json.task_creations @tasks do |json, task|
  json.id        task.id
  json.task_id   task.id
  json.task_type task.type
  json.date      task.created_on.httpdate
end

json.task_updates @revisions do |json, revision|
  # TODO: User revision.task_id
  json.id             "#{revision.id}-#{revision.owner.id}"
  json.task_id        revision.owner.id
  json.attribute_name revision.attribute_name
  json.updated_value  revision.updated_value
  json.date           revision.updated_on.httpdate
end

json.relation_additions @relations do |json, relation|
  json.id [relation.id, relation.subtask.id, relation.supertask.id].join('-')
  json.date relation.added_on.httpdate
end
