# TODO: Remove this
# TODO: Reorganize and isolate namespaces

class Lt.Models.Task extends Backbone.Model
  paramRoot: 'task'

  defaults:
    objective: null

  initialize: ->
    @on 'change:id', @onChangeId, @
    @onChangeId(this, @id, silent: true)

    @on 'destroy', @onDestroy, @

    @on 'add', @onAdd, @
    @onAdd(this, @collection)

  getState: ->
    @state

  onAdd: (model, collection, options = {}) ->
    return unless collection?
    model.subtasksCollection ?=
      new Lt.Collections.Subtasks collection, project: model

  onDestroy: (model, collection, options = {}) ->
    @setState 'deleted', options

  onChangeId: (model, value, options = {})->
    state = if @id then 'persisted' else 'new'
    @setState state, options

  setState: (state, options = {}) ->
    @state = state
    @trigger 'changeState', this, state, options

  parse: (response) ->
    # TODO: Make proper sync
    return response[@paramRoot] ? response

  getParent: ->
    @collection.get @get('parent_id')

  isValidNextState: (state) ->
    _(@get('valid_next_states')).include(state)

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

  initialize: ->
    @rootTasksCollection = new Lt.Collections.RootTasks(this)

  parse: (response) ->
    @model.prototype.defaults['valid_next_states'] = response.valid_new_task_states
    response.tasks

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
    super(@sourceCollection.models, params)
    @sourceCollection.bind 'add'    , @add    , @
    @sourceCollection.bind 'change' , @change , @
    @sourceCollection.bind 'remove' , @remove , @
    @sourceCollection.bind 'reset'  , @reset  , @

  initialize: ->

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

class Lt.Collections.Subtasks extends Backbone.FilteredCollection

  initialize: (models, options) ->
    @project = options.project

  modelFilter: (task) ->
    task.has('project_id') and task.get('project_id') == @project.id


