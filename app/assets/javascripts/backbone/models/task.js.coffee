class Lt.Models.Task extends Backbone.Model
  paramRoot: 'task'

  url: 'tasks'

  defaults:
    objective: null

  parse: (response) ->
    # TODO: Make proper sync
    return response[@paramRoot] ? response

  toJSON: ->
    attributes = {}
    for key in ['objective', 'deadline', 'parent_id', 'position']
      attributes[key] = @attributes[key]
    return attributes

  getParent: ->
    @collection.get @get('parent_id')

  isCompleted: -> !!@get('completed')

  isActionable: -> !!@get('actionable')

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


class Backbone.FilteredCollection extends Backbone.Collection
  constructor: (@sourceCollection, params)->
    super(null, params)

  initialize: ->
    @sourceCollection.bind 'add'    , @add    , @
    @sourceCollection.bind 'change' , @change    , @
    @sourceCollection.bind 'remove' , @remove , @
    @sourceCollection.bind 'reset'  , @reset  , @
    @reset @sourceCollection.models

  change: (model) ->
    included = @get model
    passes = @modelFilter model
    if not included and passes
      @add model
    else if included and not passes
      @remove model

  add: (models) ->
    models = [models] unless models.length?
    models = models.models || models
    filteredModels = _.filter(models, (model) => @modelFilter model)
    super(filteredModels)


class Lt.Collections.ActionableTasks extends Backbone.FilteredCollection

  modelFilter: (task) ->
    task.isActionable()
