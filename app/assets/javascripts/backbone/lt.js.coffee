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
    @tasks = new Lt.Collections.TasksCollection tasks
    @tasks.fetch() if tasks.length == 0
    @bindTasksToTimeline()
    @actionableTasks = new Lt.Collections.ActionableTasks @tasks

    @taskViewState = new Lt.Models.TaskViewState taskViewState

    @taskActionView = new Lt.Views.ActionableTasks.ListView
      collection: @actionableTasks
      state: @taskViewState

    @taskPlanView = new Lt.Views.Tasks.ListView
      collection: @tasks
      state: @taskViewState

    @taskViewSwitcher = new Lt.Views.Tasks.PlanActionsTabsView
      el: $(selector)[0]
      state: @taskViewState
      tabs:
        plan: @taskPlanView
        actions: @taskActionView

    @taskViewSwitcher.render()



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

