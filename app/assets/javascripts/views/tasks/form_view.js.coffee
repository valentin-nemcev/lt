Views = Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.FormView extends Backbone.View
  template  : JST['templates/tasks/form']

  tagName   : 'div'
  className : 'form'

  events:
    'submit form'            : -> @save()   ; false
    'click [control=save]'   : -> @save()   ; false
    'click [control=cancel]' : -> @cancel() ; false
    'click [control=delete]' : (ev) -> @delete($(ev.currentTarget)) ; false

  relatedControls: [
    ['supertasks', 'composition', yes],
    ['supertasks', 'dependency'],
    ['subtasks',   'dependency'],
  ]

  initialize: ->
    @relatedControlViews = for [rel, type, singular] in @relatedControls
      view = new Views.FormRelatedTasksView
        model: @model
        mainView: @options.mainView
        singular: singular
      [rel, type, view]

  cancel: ->
    for [rel, type, view] in @relatedControlViews
      view.cancelTaskSelection()

    if @model.isNew()
      @model.destroy()
    else
      @trigger 'close'

    return

  delete: ($button)->
    if confirm($button.attr('confirmation'))
      @model.destroy()

  save: ->
    $f = _.bind($.fn.find, @$('form'))
    attrs =
      state:     $f('[input=state] :checked').val(),
      objective: $f('[input=objective]').val(),

    for [rel, type, view] in @relatedControlViews
      @model.setRelated(rel, type, view.currentTasks)

    @model.save(attrs)
    @trigger('close')

    return this

  updateFields: ->
    $f = _.bind($.fn.find, @$('form'))
    $f("[input=state] [value=#{@model.get('state')}]").prop(checked: true)
    $f('[input=objective]').val(@model.get('objective'))

    $f('[input=state] input').each (i, el) =>
      $(el).closest('[item]').toggle @model.isValidNextState($(el).val())

    form = if @model.isNew() then 'new-task' else 'update-task'
    @$('form').attr form: form

    return this

  render : ->
    $(@el).html @template()
    @updateFields()
    for [rel, type, view] in @relatedControlViews
      view.currentTasks = @model.getRelated(rel, type).models
      view.setElement(@$("[view=related-#{rel}-#{type}]")).render()

    return this
