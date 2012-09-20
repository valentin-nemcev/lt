class Lt.Models.Task extends Backbone.Model

class Lt.Collections.Tasks extends Backbone.Collection
  url: '/tasks'
  model: Lt.Models.Task
