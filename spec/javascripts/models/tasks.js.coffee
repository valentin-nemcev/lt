#= require backbone/models/tasks

describe 'Task', ->
  describe 'related tasks', ->
    it 'has no related task ids initially', ->
      task = new Lt.Models.Task

      expect(task.toJSON().supertask_ids).toEqual({})
      expect(task.toJSON().subtask_ids  ).toEqual({})

    it 'adds related tasks', ->
      tasks = new Lt.Collections.Tasks
      tasks.add(task = new Lt.Models.Task)

      supertasks = (new Lt.Models.Task id: id for id in [
        'supertask1', 'supertask2', 'supertask3'
      ])

      subtasks = (new Lt.Models.Task id: id for id in [
        'subtask1', 'subtask2', 'subtask3'
      ])
      tasks.add(supertasks)
      tasks.add(subtasks)

      task.addSupertask('relation_type1', tasks.get 'supertask1')
      task.addSubtask('relation_type1', tasks.get 'subtask1')

      task.addSupertask('relation_type2',
        tasks.get('supertask2'), tasks.get('supertask3'))
      task.addSubtask('relation_type2',
        tasks.get('subtask2'), tasks.get('subtask3'))

      sortedIdsOf = (collection) ->
        _(collection.sortBy (task) -> task.id).pluck('id')

      subtasks1   = task.getSubtasks('relation_type1')
      subtasks2   = task.getSubtasks('relation_type2')
      supertasks1 = task.getSupertasks('relation_type1')
      supertasks2 = task.getSupertasks('relation_type2')
      expect(sortedIdsOf subtasks1  ).toEqual(['subtask1'])
      expect(sortedIdsOf subtasks2  ).toEqual(['subtask2', 'subtask3'])
      expect(sortedIdsOf supertasks1).toEqual(['supertask1'])
      expect(sortedIdsOf supertasks2).toEqual(['supertask2', 'supertask3'])

    it 'makes new subtasks', ->
      tasks = new Lt.Collections.Tasks
      supertask = new Lt.Models.Task id: 'supertask1'
      tasks.add supertask
      subtask = supertask.newSubtask('relation', id: 'subtask1')

      expect(tasks.get('subtask1')).toBe(subtask)
      expect(tasks.getRootTasksFor('relation').get 'subtask1')
        .toBeUndefined()
      expect(supertask.getSubtasks('relation').get 'subtask1')
        .toBe(subtask)
      expect(subtask.getSupertasks('relation').get 'supertask1')
        .toBe(supertask)

describe 'Tasks', ->
  it 'has root tasks', ->
    tasks = new Lt.Collections.Tasks
    rootTasks = tasks.getRootTasksFor('composition')
    project = new Lt.Models.Task id: 'project'
    action  = new Lt.Models.Task id: 'action'
    tasks.add [project, action]

    expect(rootTasks.pluck 'id').toEqual(['project', 'action'])

    project.addSubtask  'composition', action
    action.addSupertask 'composition', project

    expect(rootTasks.pluck 'id').toEqual(['project'])
