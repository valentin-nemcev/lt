#= require models/task_events
#= require models/tasks

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
    tasks.events = taskEvents

    server = sinon.fakeServer.create()

  afterEach ->
    server.restore()

  jsonRequest = (body) -> JSON.parse(body)
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
          date       : 'Tue, 18 Sep 2012 16:00:00 GMT'
        ,
          id         : '2'
          task_id    : 'project1'
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
        id            : 'project1'
        state         : 'underway'
        objective     : 'Updated project objective'
        supertask_ids : {}
        subtask_ids   : {composition: ['action1']}
      ,
        id            : 'action1'
        state         : 'considered'
        objective     : 'New objective'
        supertask_ids : {composition: ['project1']}
        subtask_ids   : {}
      ]

      server.respondWith 'GET', '/tasks', (request) ->
        request.respond jsonResponse(taskEventsJSON)...

      taskEvents.fetch()
      server.respond()

      expect(taskEvents.length).toBe(8)
      actualTasks   = _.sortBy(tasks.toJSON(), 'id')
      expectedTasks = _.sortBy(expectedTasks,  'id')
      expect(tasks.toJSON()).toEqualProperties(expectedTasks)

  describe 'Create', ->
    it 'posts a tasks and handles response', ->
      taskEventsResponseJSON =
        task_creations: [
          id             : 'creation1'
          task_id        : 'action1'
          date           : 'Sat, 27 Oct 2012 09 : 17 : 35 GMT'
        ]
        task_updates: [
          id             : 'update1'
          task_id        : 'action1'
          attribute_name : 'state'
          updated_value  : 'considered'
          date           : 'Sat, 27 Oct 2012 09 : 17 : 35 GMT'
        ,
          id             : 'update2'
          task_id        : 'action1'
          attribute_name : 'objective'
          updated_value  : 'Test objective'
          date           : 'Sat, 27 Oct 2012 09 : 17 : 35 GMT'
        ]

      expectedTasks = [
        id            : 'action1'
        objective     : 'Test objective'
        state         : 'considered'
        subtask_ids   : {}
        supertask_ids : {}
      ]

      expectedTaskRequestJSON =
        objective     : 'Test objective'
        state         : 'considered'
        subtask_ids   : {}
        supertask_ids : {}

      actualTaskRequestJSON = null
      server.respondWith 'POST', '/tasks', (request) ->
        actualTaskRequestJSON = jsonRequest request.requestBody
        request.respond jsonResponse(taskEventsResponseJSON)...

      tasks.create
        objective : 'Test objective'
        state     : 'considered'

      server.respond()

      expect(actualTaskRequestJSON).toEqualProperties(expectedTaskRequestJSON)

      expect(tasks.toJSON()).toEqualProperties(expectedTasks)
