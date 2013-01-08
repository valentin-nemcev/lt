Views = Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.FormProjectControlView extends Backbone.View

  initialize: ->
    @allProjects = @model.collection

  changeCurrentProject: ->
    @currentProjects = @model.getSupertasks('composition')
    @currentProject = @currentProjects.at(0)
    @$projectsControl?.val(@currentProject?.cid)

  resetProjects: ->
    @$projectsControl.empty()
    $('<option/>', value: null, text: 'Нет проекта')
      .appendTo(@$projectsControl)
    _.chain(@allProjects.models)
      .without(@model)
      .map((project) -> value: project.cid, text: project.get 'objective')
      .sortBy('text')
      .each (project) =>
        $('<option/>', project).appendTo(@$projectsControl)

  render: ->
    @$projectsControl = @$('[input=project]')
    @resetProjects()
    @changeCurrentProject()
