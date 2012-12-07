Views = Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.FormProjectControlView extends Backbone.View

  initialize: ->
    @currentProjects = @model.getSupertasks('composition')

    @currentProjects.on 'add'   , @changeCurrentProject, @
    @currentProjects.on 'remove', @changeCurrentProject, @

  changeCurrentProject: ->
    @currentProject = @currentProjects.at(0)
    @$('[input=project]').val(@currentProject?.get('objective'))

  render: ->
    @changeCurrentProject()
