Views = Lt.Views.Tasks ||= {}

class Views.Timeline extends Backbone.View
  template: JST['backbone/templates/tasks/timeline']

  initialize: ->
    @model.bind 'change', @updateView, @

  updateModel: ->
    @model.set('current_date', @current_date.clone().toDate())

  updateView: ->
    @current_date = moment(@model.get('current_date')).clone()
    @$('input[name=current_date]').val @current_date.format('YYYY-MM-DD HH:mm')

  events:
    'click .change_current_date': (ev) ->
      ev.stopPropagation()
      @changeCurrentDate($(ev.currentTarget).attr('change'))

  changeCurrentDate: (change) ->
    [dir, unit] = change.split(' ')
    units = unit + 's'
    diff = {next: +1, prev: -1}[dir]
    @current_date.add(units, diff)
    @updateModel()

  render: ->
    @$el.html @template(@model)
    @updateView()
    return this
