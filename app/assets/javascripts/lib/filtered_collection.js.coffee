class Backbone.FilteredCollection extends Backbone.Collection
  constructor: (@sourceCollection, params = {})->
    @modelFilter ?= params.modelFilter
    super(@sourceCollection.models, params)
    @sourceCollection.bind 'add'    , @add    , @
    @sourceCollection.bind 'change' , @change , @
    @sourceCollection.bind 'remove' , @remove , @
    @sourceCollection.bind 'reset'  , @reset  , @

  initialize: ->

  change: (model) ->
    included = @getByCid model
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


