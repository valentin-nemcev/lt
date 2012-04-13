class Lt.Models.Timeline extends Backbone.Model
  initialize: ->
    @set 'current_date', new Date()

  defaults:
    current_date: null

