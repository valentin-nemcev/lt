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

  initTasksList: (selector, tasks, tasks_list_state) ->
    view = new Lt.Views.Tasks.ListView
      collection: new Lt.Collections.TasksCollection tasks
      state: new Lt.Models.TasksListState tasks_list_state
      el: $(selector)[0]

    view.render()

  initQuotesList: (selector, quotes) ->
    view = new Lt.Views.Quotes.ListView
      collection: new Lt.Collections.QuotesCollection quotes
      el: $(selector)[0]

    view.render()


  initRandomQuote: (selector, quote) ->
    view = new Lt.Views.Quotes.RandomQuoteView
      model: new Lt.Models.RandomQuote quote
      el: $(selector)[0]

    view.render()

