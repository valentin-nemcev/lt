#= require_self
#= require_tree ./templates
#= require_tree ./models
#= require_tree ./views
#= require_tree ./routers

window.Lt =
  Models: {}
  Collections: {}
  Routers: {}
  Views: {}

  initTimeline: (selector) ->
    @timeline = new Lt.Models.Timeline
    @bindTasksToTimeline()
    view = new Lt.Views.Tasks.Timeline
      model: @timeline
      el: $(selector)[0]

    view.render()

  initTasksList: (selector, tasks, tasks_list_state) ->
    @tasks = new Lt.Collections.TasksCollection tasks
    @bindTasksToTimeline()
    view = new Lt.Views.Tasks.ListView
      collection: @tasks
      state: new Lt.Models.TasksListState tasks_list_state
      el: $(selector)[0]

    view.render()

  bindTasksToTimeline: () ->
    @tasks.bindToTimeline(@timeline) if @tasks? and @timeline?


  initQuotesList: (selector, quotes) ->
    @quotes = new Lt.Collections.QuotesCollection quotes
    view = new Lt.Views.Quotes.ListView
      collection: @quotes
      el: $(selector)[0]

    view.render()


  initRandomQuote: (selector, quote) ->
    view = new Lt.Views.Quotes.RandomQuoteView
      model: new Lt.Models.RandomQuote quote
      el: $(selector)[0]

    view.render()

