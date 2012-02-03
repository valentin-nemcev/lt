class Lt.Models.Task extends Backbone.Model
  paramRoot: 'task'

  defaults:
    body: null

class Lt.Collections.TasksCollection extends Backbone.Collection
  model: Lt.Models.Task
  url: '/tasks'
