Views = Lt.Views.Tasks ||= {}

class Views.ListView extends Lt.Views.List.ListView
  Views: Views

  itemName: 'task'

  initialize: ->
    super
    @showDone yes

  events: ->
    _.extend super,
      'change .show-done input' : (ev) =>
        @showDone $(ev.currentTarget).prop('checked')

  buildItem: (model) ->
    @toggleDoneVisibility(model, super)

  showDone: (showingDone) ->
    @showingDone = showingDone
    @$('.show-done input').prop('checked', showingDone)
    @toggleDoneVisibility(task, @getItem(task)) for task in @collection.models

  toggleDoneVisibility: (model, item) ->
    item.toggle(not model.get('done') or @showingDone)


