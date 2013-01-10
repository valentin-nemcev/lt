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

  initialize: ->
    @projectControlView = new Views.FormProjectControlView 
      model: @model
      mainView: @options.mainView

  cancel: ->
    @projectControlView.cancelProjects()

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

    @model.setCurrentProject($f('[input=projects]').val())
    @model.save(attrs)
    @trigger('close')

    return this

  updateFields: ->
    $f = _.bind($.fn.find, @$('form'))
    $f("[input=state] [value=#{@model.get('state')}]").prop(checked: true)
    $f('[input=objective]').val(@model.get('objective'))

    $f('[input=state] input').each (i, el) =>
      $(el).closest('[item]').toggle @model.isValidNextState($(el).val())

    projectIds = @model.getSupertasks('composition').pluck('id')
    $f('[input=projects]').val(projectIds.join(','))

    form = if @model.isNew() then 'new-task' else 'update-task'
    @$('form').attr form: form

    return this

  render : ->
    $(@el).html @template()
    @updateFields()
    @projectControlView.setElement(@$('[view=project-control]')).render()

    return this
