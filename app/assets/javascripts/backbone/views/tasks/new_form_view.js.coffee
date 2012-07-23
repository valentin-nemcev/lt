Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.NewFormView extends Backbone.View
  template: JST['backbone/templates/tasks/new_form']

  tagName: 'div'
  className: 'new task form'

  events:
    'submit form': (ev) -> ev.preventDefault(); @save()

  save: ->
    attrs = {}
    for {name: name, value: value} in @$('form').serializeArray()
      attrs[name] = value
    @model.save(attrs)
    return this


  render : ->
    $(@el).html @template(this)
    return this
