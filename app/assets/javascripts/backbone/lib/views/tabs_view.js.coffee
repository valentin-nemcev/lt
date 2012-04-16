class Lt.Views.TabsView extends Backbone.View
  template: null

  stateAttr: null

  initialize: ->
    super
    @state = @options.state
    @state.bind 'change:' + @stateAttr, @switchCurrentTab, @

  getCurrentTab: -> @state.get @stateAttr

  saveCurrentTab: (tab) -> @state.set(@stateAttr, tab).save()


  initTabs: ->
    @handleLink = $('<a href="#"/>').click (ev) =>
      ev.preventDefault()
      @saveCurrentTab $(ev.currentTarget).parent().attr('tab-handle')

    @handleTitle = $('<span/>', class: 'current')

    @handles = {}; @panes = {}
    $handles = @$el.children('.tab-handles')

    $handles.children('[tab-handle]').each (index, handle) =>
      tab = $(handle).attr('tab-handle')

      @handles[tab] = $(handle).contents()
      @handles[tab].wrapAll(@handleLink)

      @panes[tab] = $('<div/>', 'tab-pane': tab).hide().insertAfter($handles)
      @options.tabs[tab]?.setElement(@panes[tab]).render()


  switchCurrentTab: () ->
    newTab = @getCurrentTab()

    @handles[@prevTab]?.unwrap()
      .parent().removeClass('current').end()
      .wrapAll(@handleLink)
    @panes[@prevTab]?.hide()

    @handles[newTab].unwrap()
      .parent().addClass('current').end()
      .wrapAll(@handleTitle)
    @panes[newTab]?.show()

    @prevTab = newTab


  render: ->
    @$el.html @template()
    @initTabs()
    @switchCurrentTab()
    return this

