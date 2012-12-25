#= require models/tasks

describe 'Task', ->
  describe 'related tasks', ->
    sortedIdsOf = (collection) ->
      _(collection.sortBy (task) -> task.id).pluck('id')

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

      subtasks1   = task.getSubtasks('relation_type1')
      subtasks2   = task.getSubtasks('relation_type2')
      supertasks1 = task.getSupertasks('relation_type1')
      supertasks2 = task.getSupertasks('relation_type2')
      expect(sortedIdsOf subtasks1  ).toEqual(['subtask1'])
      expect(sortedIdsOf subtasks2  ).toEqual(['subtask2', 'subtask3'])
      expect(sortedIdsOf supertasks1).toEqual(['supertask1'])
      expect(sortedIdsOf supertasks2).toEqual(['supertask2', 'supertask3'])

    it 'removes related tasks', ->
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


      task.removeSupertask('relation_type1', tasks.get 'supertask1')
      task.removeSubtask('relation_type2', tasks.get('subtask2'))
      task.removeSupertask('relation_type2',
        tasks.get('supertask2'), tasks.get('supertask3'))

      subtasks1   = task.getSubtasks('relation_type1')
      subtasks2   = task.getSubtasks('relation_type2')
      supertasks1 = task.getSupertasks('relation_type1')
      supertasks2 = task.getSupertasks('relation_type2')
      expect(sortedIdsOf subtasks1  ).toEqual(['subtask1'])
      expect(sortedIdsOf subtasks2  ).toEqual(['subtask3'])
      expect(sortedIdsOf supertasks1).toEqual([])
      expect(sortedIdsOf supertasks2).toEqual([])


    it 'adds subtask only once', ->
      tasks = new Lt.Collections.Tasks
      rootTasks = tasks.getRootTasksFor('relation')
      rootTasks.on 'add', rootTaskAdded = sinon.spy()
      project = new Lt.Models.Task id: 'project1'
      tasks.add(project)


      project.getSubtasks('relation').on 'add', subtaskAdded = sinon.spy()
      project.newSubtask('relation', id: 'action1')
      expect(subtaskAdded).toHaveBeenCalledOnce()
      expect(rootTaskAdded).toHaveBeenCalledOnce()


    it 'makes new subtasks', ->
      Lt.Models.Task::toString = -> 'test'
      tasks = new Lt.Collections.Tasks
      supertask = new Lt.Models.Task id: 'supertask1'
      tasks.add supertask
      subtask = supertask.newSubtask('relation', id: 'subtask1')

      expect(tasks.get('subtask1').id).toBe('subtask1')
      expect(tasks.getRootTasksFor('relation').get 'subtask1')
        .toBeUndefined()
      expect(supertask.getSubtasks('relation').get('subtask1').id)
        .toBe('subtask1')
      expect(subtask.getSupertasks('relation').get('supertask1').id)
        .toBe('supertask1')

describe 'Tasks', ->
  it 'has root tasks', ->
    tasks = new Lt.Collections.Tasks
    rootTasks = tasks.getRootTasksFor('composition')
    project = new Lt.Models.Task id: 'project'
    action  = new Lt.Models.Task id: 'action'
    tasks.add [project, action]

    expect(rootTasks.pluck('id').sort()).toEqual(['action', 'project'])

    project.addSubtask  'composition', action
    action.addSupertask 'composition', project

    expect(rootTasks.pluck 'id').toEqual(['project'])
