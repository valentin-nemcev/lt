#= require_self
#= require_tree ./lib
#= require_tree ./templates
#= require_tree ./models
#= require_tree ./views
#= require_tree ./routers

window.Lt =
  Models: {}
  Collections: {}
  Routers: {}
  Views: {}


  bindTasksToTimeline: () ->
    @tasks.bindToTimeline(@timeline) if @tasks? and @timeline?


  initTimeline: (selector) ->
    @timeline = new Lt.Models.Timeline
    @bindTasksToTimeline()
    @timelineView = new Lt.Views.Tasks.Timeline
      model: @timeline
      el: $(selector)[0]

    @timelineView.render()


  initTaskView: (selector, tasks, taskViewState) ->
    @tasks = new Lt.Collections.Tasks
    @taskEvents = new Lt.TaskEvents([], tasks: @tasks)
    @taskEvents.fetch()
    # @bindTasksToTimeline()

    @taskViewState = new Lt.Models.TaskViewState taskViewState

    @taskView = new Lt.Views.Tasks.MainView
      collection: @tasks
      state: @taskViewState
      el: $(selector)[0]

    @taskView.render()



  initQuotesList: (selector, quotes) ->
    @quotes = new Lt.Collections.QuotesCollection quotes
    @quotesView = new Lt.Views.Quotes.ListView
      collection: @quotes
      el: $(selector)[0]

    @quotesView.render()


  initRandomQuote: (selector, quote) ->
    @randomQuote = new Lt.Models.RandomQuote quote
    @randomQuoteView = new Lt.Views.Quotes.RandomQuoteView
      model: @randomQuote
      el: $(selector)[0]

    @randomQuoteView.render()

