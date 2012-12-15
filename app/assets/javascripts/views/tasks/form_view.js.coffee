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
    @model.bind 'change'     , @change     , @
    @model.bind 'changeState', @changeState, @
    @projectControlView = new Views.FormProjectControlView model: @model

  cancel: ->
    if @model.isNew()
      @model.destroy()
    else
      @trigger 'close'
      @change()

    return

  delete: ($button)->
    if confirm($button.attr('confirmation'))
      @model.destroy()

  save: ->
    $f = _.bind($.fn.find, @$('form'))
    attrs =
      state:     $f('[input=state] :checked').val(),
      objective: $f('[input=objective]').val(),

    @model.setCurrentProject($f('[input=project]').val())
    @model.save(attrs)
    @trigger('close')

    return this

  changeState: ->
    isNew = @model.getState() is 'new'
    @$('form').attr form: if isNew then 'new-task' else 'update-task'

    return this

  change: ->
    $f = _.bind($.fn.find, @$('form'))
    $f("[input=state] [value=#{@model.get('state')}]").prop(checked: true)
    $f('[input=objective]').val(@model.get('objective'))

    $f('[input=state] input').each (i, el)=>
      $(el).closest('[item]').toggle @model.isValidNextState($(el).val())

    return this

  render : ->
    $(@el).html @template()
    @projectControlView.setElement(@$('[view=project-control]')).render()
    @change()
    @changeState()

    return this