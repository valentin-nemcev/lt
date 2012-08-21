json.id        task.id
json.type      task.class.name.demodulize.underscore
json.objective task.objective
json.state     task.state
json.valid_next_states ['considered', 'completed', 'underway', 'canceled']

json.project_id task.project.try :id
