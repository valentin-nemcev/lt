Views = Lt.Views.Tasks ||= {}

class Views.ViewSwitcher extends Backbone.View
  template: JST['backbone/templates/tasks/view_switcher']

  initialize: ->
    super
    @state = @options.state
    @state.bind 'change:current_view', @switchView, @

    @planView = @options.planView
    @actionView = @options.actionView


  events:
    'click #task_view_switcher .tab a': (ev) ->
      ev.stopPropagation()
      current = $(ev.currentTarget).closest('.tab').attr('tab-handle')
      @state.save current_view: current


  switchView: ->
    current = @state.get('current_view')
    $active = @$('#' + current)
    $views = @$el.children('.tasks')
    $active.show()
    $views.not($active).hide()

    $tabs = @$('#task_view_switcher').children()
    $activeTab = $tabs.filter("[tab-handle=#{current}]")
    $activeTab.children('span').show()
    $activeTab.children('a').hide()

    $inactiveTabs = $tabs.not($activeTab)
    $inactiveTabs.children('span').hide()
    $inactiveTabs.children('a').show()


  render: ->
    @$el.html @template()

    @planView.setElement @$('#task_plan').hide()
    @planView.render()

    @actionView.setElement @$('#task_actions').hide()
    @actionView.render()

    @switchView()

    return this

