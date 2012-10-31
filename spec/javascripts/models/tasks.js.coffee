#= require backbone/models/tasks

describe 'Task', ->
  describe 'related tasks', ->
    it 'has no related task ids initially', ->
      task = new Lt.Models.Task

      expect(task.get('supertaskIds')).toEqual([])
      expect(task.get('subtaskIds')).toEqual([])

    it 'adds related tasks', ->
      tasks = new Lt.Collections.Tasks
      tasks.add(task = new Lt.Models.Task)
      projects = (new Lt.Models.Task id: id for id in [
        'project1', 'project2', 'project3'
      ])

      actions = (new Lt.Models.Task id: id for id in [
        'action1', 'action2', 'action3'
      ])
      tasks.add(projects)
      tasks.add(actions)

      task.addSupertask(tasks.get 'project1')
      task.addSubtask(tasks.get 'action1')

      task.addSupertask(tasks.get('project2'), tasks.get('project3'))
      task.addSubtask(tasks.get('action2'), tasks.get('action3'))

      expect(task.get('supertaskIds')).toEqual(
        ['project1', 'project2', 'project3']
      )
      expect(task.get('subtaskIds')).toEqual(
        ['action1', 'action2', 'action3']
      )

      idComparator = (task) -> task.id

      subtasks   = task.subtaskCollection.sortBy(idComparator)
      supertasks = task.supertaskCollection.sortBy(idComparator)
      expect(_.pluck(subtasks, 'id')).toEqual(_.pluck(actions, 'id'))
      expect(_.pluck(supertasks, 'id')).toEqual(_.pluck(projects, 'id'))

    it 'makes new subtasks', ->
      tasks = new Lt.Collections.Tasks
      project = new Lt.Models.Task id: 'project1'
      tasks.add project
      action = project.newSubtask(id: 'action1')

      expect(tasks.getByCid action).not.toBeNull()
      expect(tasks.rootTasks.getByCid action).toBeUndefined()
      expect(project.subtaskCollection.getByCid action).not.toBeNull()
      expect(action.get 'supertaskIds').toEqual(['project1'])
      expect(project.get 'subtaskIds').toEqual(['action1'])

describe 'Tasks', ->
  it 'has root tasks', ->
    tasks = new Lt.Collections.Tasks
    rootTasks = tasks.rootTasks
    project = new Lt.Models.Task id: 'project'
    action  = new Lt.Models.Task id: 'action'
    tasks.add [project, action]

    expect(rootTasks.pluck 'id').toEqual(['project', 'action'])

    project.addSubtask action
    action.addSupertask project

    expect(rootTasks.pluck 'id').toEqual(['project'])
