#= require backbone/models/task_events

describe 'TaskEvents', ->

  eventsCollection = null
  describe 'creation of event objects from server response', ->

    beforeEach ->
      eventsCollection = new Lt.TaskEvents

    it 'creates creation events', ->
      events = eventsCollection.parse task_creations: [{id: 'eventId'}]

      expect(events.length).toBe(1)
      expect(events[0].type).toBe('task_creation')

    it 'creates update events', ->
      events = eventsCollection.parse task_updates: [{id: 'eventId'}]

      expect(events.length).toBe(1)
      expect(events[0].type).toBe('task_update')

    it 'creates relation addition events', ->
      events = eventsCollection.parse relation_additions: [{id: 'eventId'}]

      expect(events.length).toBe(1)
      expect(events[0].type).toBe('relation_addition')


describe 'RelationAddition', ->
  it 'updates related tasks when applied', ->
    tasks = new Backbone.Collection

    supertask = new Backbone.Model id: 'supertask1'
    subtask   = new Backbone.Model id: 'subtask1'

    supertask.addSubtask = jasmine.createSpy('addSubtask')
    subtask.addSupertask = jasmine.createSpy('addSupertask')

    tasks.add [supertask, subtask]

    event = new Lt.Models.RelationAddition
      id           : 'event1'
      supertask_id : 'supertask1'
      subtask_id   : 'subtask1'

    event.apply(tasks)

    expect(supertask.addSubtask).toHaveBeenCalledWith('subtask1')
    expect(subtask.addSupertask).toHaveBeenCalledWith('supertask1')

