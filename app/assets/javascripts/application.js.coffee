# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
# WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
# GO AFTER THE REQUIRES BELOW.
#
#= require jquery
#= require jquery-ui
#= require jquery.ui.nestedSortable
#= require jquery_ujs
#= require moment
#= require underscore
#= require backbone
#= require backbone_rails_sync
#= require_self
#= require_tree ./lib
#= require_tree ./templates
#= require_tree ./models
#= require_tree ./views
#= require_tree ./routers
#= require_tree .

window.Lt =
  Models: {}
  Collections: {}
  Routers: {}
  Views: {}

  initTaskView: (selector, tasks, taskViewState) ->
    @tasks = new Lt.Collections.Tasks
    @taskEvents = new Lt.TaskEvents([], tasks: @tasks)
    @tasks.events = @taskEvents

    @taskViewState = new Lt.Models.TaskViewState taskViewState

    @taskEvents.fetch success: =>
      @taskView = new Lt.Views.Tasks.MainView
        collection: @tasks
        state: @taskViewState
        el: $(selector)[0]
      @taskView.render()
