json.task_creations @tasks do |json, task|
  json.id        task.id
  json.task_id   task.id
  json.date      task.created_on.httpdate
end

json.task_updates @revisions do |json, revision|
  json.id             "#{revision.id}-#{revision.task_id}"
  json.task_id        revision.task_id
  json.attribute_name revision.attribute_name
  json.updated_value  revision.updated_value
  json.date           revision.updated_on.httpdate
end

json.relation_additions @relations do |json, relation|
  json.id [
    relation.id,
    relation.subtask.id,
    relation.supertask.id,
    'a'
  ].join('-')
  json.date          relation.added_on.httpdate
  json.relation_type relation.type
  json.supertask_id  relation.supertask.id
  json.subtask_id    relation.subtask.id
end

removed_relations = @relations.select{ |r| r.removed? }
json.relation_removals removed_relations do |json, relation|
  json.id [
    relation.id,
    relation.subtask.id,
    relation.supertask.id,
    'r'
  ].join('-')
  json.date          relation.removed_on.httpdate
  json.relation_type relation.type
  json.supertask_id  relation.supertask.id
  json.subtask_id    relation.subtask.id
end
