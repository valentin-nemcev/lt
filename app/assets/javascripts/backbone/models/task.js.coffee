class Lt.Models.Task extends Backbone.Model
  paramRoot: 'task'

  defaults:
    body: null

  toJSON: ->
    attributes = {}
    for key in ['body', 'deadline', 'parent_id', 'position']
      attributes[key] = @attributes[key]
    return attributes

  getParent: ->
    @collection.get @get('parent_id')

  isCompleted: -> !!@get('completed?')

  postAction: (action, options) ->
    success = (resp, status, jqXHR) =>
      @set(@parse(resp, jqXHR))
      options.success() if options.success

    $.post @url() + '/' + action, success

  undoComplete: (options) -> @postAction 'undo_complete', options
  complete:     (options) -> @postAction 'complete'     , options


class Lt.Collections.TasksCollection extends Backbone.Collection
  model: Lt.Models.Task
  url: '/tasks'

  sortable: yes

  addChild: (model, parent) ->
    if parent = @getByCid parent
      return false if parent?.isNew()
      model.set parent_id: parent.id
    return @add model

  move: (model, position) ->
    model = @getByCid model
    position.of = @getByCid(position.of)?.id
    model.save position: position


  bindToTimeline: (timeline) ->
    timeline.bind 'change:current_date', (tl, current_date) =>
      @fetchForDate current_date

  fetchForDate: (date, options = {}) ->
    date_opts = data: {current_date: date.toISOString()}
    @fetch _.extend({}, date_opts, options)
