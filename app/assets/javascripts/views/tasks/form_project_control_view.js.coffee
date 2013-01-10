# encoding: utf-8

Views = Lt.Views.Tasks ||= {}

class ProjectView extends Backbone.View
  tagName: 'li'

  toggleChange: (toggled = not @changeToggled) ->
    @changeToggled = toggled

    @$change.toggle(not toggled)
    @$cancel.toggle(toggled)

    @$el.toggleClass('changed', toggled)

  render: ->
    $('<span/>',
      field : 'objective',
      text  : @model.get('objective')
    ).appendTo(@$el)

    @$change = $('<button/>',
      class   : 'link'
      control : 'change'
      text    : 'Изменить'
      click   : => @onChange(); false
    ).appendTo(@$el)

    @$cancel = $('<button/>',
      class   : 'link'
      control : 'cancel'
      text    : 'Отменить'
      click   : => @onCancel(); false
    ).appendTo(@$el)

    @$remove = $('<button/>',
      class   : 'link'
      control : 'remove'
      text    : 'Удалить'
      click   : => @onRemove(); false
    ).appendTo(@$el)

    return this

class AddProjectView extends Backbone.View
  tagName: 'li'

  toggleAdd: (toggled = not @addToggled) ->
    @addToggled = toggled

    @$add.toggle(not toggled)
    @$cancel.toggle(toggled)

    @$el.toggleClass('added', toggled)

  render: ->
    @$add = $('<button/>',
      class   : 'link'
      control : 'add'
      text    : 'Добавить'
      click   : => @onAdd(); false
    ).appendTo(@$el)

    @$cancel = $('<button/>',
      class   : 'link'
      control : 'cancel'
      text    : 'Отменить'
      click   : => @onCancel(); false
    ).appendTo(@$el)

    return this


class Lt.Views.Tasks.FormProjectControlView extends Backbone.View

  initialize: ->
    @currentProjects = []
    @projectViews = {}

  render: ->
    @$currentProjects = @$('[input=projects]')
    currentProjectIds = @$currentProjects.val()?.split(',') ? []

    @currentProjects = _.chain(currentProjectIds)
     .map( (id) => @model.collection.get(id) )
     .compact()
     .value()

    @rebuildProjects()

  rebuildProjects: ->
    $projectsList = @$('.task-projects').empty()
    view.remove() for cid, view of @projectViews
    @addProjectView?.remove()

    for project in @currentProjects
      view = @projectViews[project.cid] = @buildProjectView(project)
      view.$el.appendTo($projectsList)

    view = @addProjectView = new AddProjectView
    view.render()
    view.onAdd = => view.toggleAdd on; @addProject()
    view.onCancel = => @cancelProjects()
    view.toggleAdd off
    unless @currentProjects.length
      view.$el.appendTo($projectsList)

    @$currentProjects.val(_.pluck(@currentProjects, 'id').join(','))
    return this

  buildProjectView: (project) ->
    view = new ProjectView model: project
    view.onChange = => view.toggleChange on; @changeProject(project)
    view.onRemove = => @removeProject(project)
    view.onCancel = => @cancelProjects()
    view.render().toggleChange off

    return view

  addProject: ->
    @options.mainView.selectTask (newProject) =>
      @currentProjects.push newProject
      @rebuildProjects()

    return this

  changeProject: (oldProject) ->
    @options.mainView.selectTask (newProject) =>
      index = _.indexOf(@currentProjects, oldProject)
      @currentProjects[index] = newProject
      @rebuildProjects()

    return this

  removeProject: (project) ->
    index = _.indexOf(@currentProjects, project)
    @currentProjects.splice(index, 1)
    @rebuildProjects()

    return this

  cancelProjects: () ->
    @options.mainView.cancelSelectTask()
    @addProjectView.toggleAdd off
    for cid, view of @projectViews
      view.toggleChange off

    return this
