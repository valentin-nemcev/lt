#= require backbone/models/task_events
#= require backbone/models/tasks

describe 'Tasks', ->
  parser = null
  tasks = null
  taskCreations = null
  taskUpdates = null
  taskEvents = null

  server = null

  beforeEach ->
    tasks = new Lt.Collections.Tasks
    taskEvents = new Lt.TaskEvents([], tasks: tasks)

    server = sinon.fakeServer.create()

  afterEach ->
    server.restore()

  jsonResponse = (obj, status = 200) ->
    [status, {"Content-Type": "application/json"}, JSON.stringify(obj)]

  describe 'Get', ->
    it "with no events", ->
      server.respondWith 'GET', '/tasks', (request) ->
        request.respond jsonResponse({})...
      taskEvents.fetch()
      server.respond()

      expect(taskEvents.length).toBe(0)
      expect(tasks.length).toBe(0)

    it 'with unordered events for multiple tasks with updates', ->
      # TODO: Add sequence numbers
      taskEventsJSON =
        task_creations: [
          id         : '1'
          task_id    : 'action1'
          task_type  : 'action'
          date       : 'Tue, 18 Sep 2012 16:00:00 GMT'
        ,
          id         : '2'
          task_id    : 'project1'
          task_type  : 'project'
          date       : 'Thu, 20 Sep 2012 17:00:00 GMT'
        ]
        task_updates: [
          id             : 'update1'
          task_id        : 'action1'
          date           : 'Tue, 18 Sep 2012 16:00:00 GMT'
          attribute_name : 'state'
          updated_value  : 'considered'
        ,
          id             : 'update2'
          task_id        : 'action1'
          date           : 'Tue, 18 Sep 2012 16:00:00 GMT'
          attribute_name : 'objective'
          updated_value  : 'New objective'
        ,
          id             : 'update3'
          task_id        : 'project1'
          date           : 'Thu, 20 Sep 2012 17:00:00 GMT'
          attribute_name : 'state'
          updated_value  : 'underway'
        ,
          id             : 'update4'
          task_id        : 'project1'
          date           : 'Thu, 20 Sep 2012 17:00:00 GMT'
          attribute_name : 'objective'
          updated_value  : 'Project objective'
        ,
          id             : 'update5'
          task_id        : 'project1'
          date           : 'Thu, 20 Sep 2012 18:00:00 GMT'
          attribute_name : 'objective'
          updated_value  : 'Updated project objective'
        ].reverse()
        relation_additions: [
          id            : 'relation_addition1'
          date          : 'Thu, 20 Sep 2012 17 : 00 : 00 GMT'
          relation_type : 'composition'
          supertask_id  : 'project1'
          subtask_id    : 'action1'
        ]

      expectedTasks = [
        id           : 'action1'
        type         : 'action'
        state        : 'considered'
        objective    : 'New objective'
        supertaskIds : ['project1']
        subtaskIds   : []
      ,
        id           : 'project1'
        type         : 'project'
        state        : 'underway'
        objective    : 'Updated project objective'
        supertaskIds : []
        subtaskIds   : ['action1']
      ]

      server.respondWith 'GET', '/tasks', (request) ->
        request.respond jsonResponse(taskEventsJSON)...

      taskEvents.fetch()
      server.respond()

      expect(taskEvents.length).toBe(8)
      expect(tasks.toJSON()).toEqualProperties(expectedTasks)
