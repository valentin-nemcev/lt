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

    it 'with events for one task without updates', ->
      taskEventsJSON =
        task_creations: [
          id         : '1'
          task_id    : 1
          task_type  : 'action'
          date       : 'Tue, 18 Sep 2012 16:00:00 GMT'
        ]
        task_updates: [
          id             : 'update1'
          task_id        : 1
          attribute_name : 'state'
          updated_value  : 'considered'
          date           : 'Tue, 18 Sep 2012 16:00:00 GMT'
        ,
          id             : 'update2'
          task_id        : 1
          attribute_name : 'objective'
          updated_value  : 'New objective'
          date           : 'Tue, 18 Sep 2012 16:00:00 GMT'
        ]

      expectedTasks = [
        id        : 1
        type      : 'action'
        state     : 'considered'
        objective : 'New objective'
      ]

      server.respondWith 'GET', '/tasks', (request) ->
        request.respond jsonResponse(taskEventsJSON)...

      taskEvents.fetch()
      server.respond()

      expect(taskEvents.length).toBe(3)
      expect(tasks.toJSON()).toEqual(expectedTasks)

    it 'with unordered events for multiple tasks with updates', ->
      # TODO: Add sequence numbers
      taskEventsJSON =
        task_creations: [
          id         : '1'
          task_id    : 1
          task_type  : 'action'
          date       : 'Tue, 18 Sep 2012 16:00:00 GMT'
        ,
          id         : '2'
          task_id    : 2
          task_type  : 'project'
          date       : 'Thu, 20 Sep 2012 17:00:00 GMT'
        ]
        task_updates: [
          id             : 'update1'
          task_id        : 1
          date           : 'Tue, 18 Sep 2012 16:00:00 GMT'
          attribute_name : 'state'
          updated_value  : 'considered'
        ,
          id             : 'update2'
          task_id        : 1
          date           : 'Tue, 18 Sep 2012 16:00:00 GMT'
          attribute_name : 'objective'
          updated_value  : 'New objective'
        ,
          id             : 'update3'
          task_id        : 2
          date           : 'Thu, 20 Sep 2012 17:00:00 GMT'
          attribute_name : 'state'
          updated_value  : 'underway'
        ,
          id             : 'update4'
          task_id        : 2
          date           : 'Thu, 20 Sep 2012 17:00:00 GMT'
          attribute_name : 'objective'
          updated_value  : 'Project objective'
        ,
          id             : 'update5'
          task_id        : 2
          date           : 'Thu, 20 Sep 2012 18:00:00 GMT'
          attribute_name : 'objective'
          updated_value  : 'Updated project objective'
        ].reverse()

      expectedTasks = [
        id        : 1
        type      : 'action'
        state     : 'considered'
        objective : 'New objective'
      ,
        id        : 2
        type      : 'project'
        state     : 'underway'
        objective : 'Updated project objective'
      ]

      server.respondWith 'GET', '/tasks', (request) ->
        request.respond jsonResponse(taskEventsJSON)...

      taskEvents.fetch()
      server.respond()

      expect(taskEvents.length).toBe(7)
      expect(tasks.toJSON()).toEqual(expectedTasks)

