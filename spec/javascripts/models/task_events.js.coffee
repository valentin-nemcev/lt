#= require models/task_events

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

    it 'creates relation removal events', ->
      events = eventsCollection.parse relation_removals: [{id: 'eventId'}]

      expect(events.length).toBe(1)
      expect(events[0].type).toBe('relation_removal')

describe 'TaskCreation', ->
  it 'creates new tasks', =>
    tasks = new Backbone.Collection

    event = new Lt.Models.TaskCreation
      id        : 'event1'
      task_id   : 'task1'

    expectedTaskProperties =
      id   : 'task1'

    event.apply(tasks)

    expect(tasks.length).toBe(1)
    expect(tasks.get('task1').toJSON()).toEqualProperties(expectedTaskProperties)

  it 'updates tasks created on client', =>
    tasks = new Backbone.Collection
    updatedTask = new Backbone.Model
    tasks.add updatedTask

    event = new Lt.Models.TaskCreation
      id        : 'event1'
      task_id   : 'task1'
    ,
      updatedTask: updatedTask

    expectedTaskProperties =
      id   : 'task1'

    event.apply(tasks)

    expect(tasks.length).toBe(1)
    expect(updatedTask.toJSON()).toEqualProperties(expectedTaskProperties)

describe 'RelationAddition', ->
  it 'updates related tasks when applied', ->
    tasks = new Backbone.Collection

    supertask = new Backbone.Model id: 'supertask1'
    subtask   = new Backbone.Model id: 'subtask1'

    supertask.addSubtask = sinon.spy()
    subtask.addSupertask = sinon.spy()

    tasks.add [supertask, subtask]

    event = new Lt.Models.RelationAddition
      id            : 'event1'
      relation_type : 'relation_type'
      supertask_id  : 'supertask1'
      subtask_id    : 'subtask1'

    event.apply(tasks)

    expect(supertask.addSubtask)
      .toHaveBeenCalledWith('relation_type', subtask)
    expect(subtask.addSupertask)
      .toHaveBeenCalledWith('relation_type', supertask)

describe 'RelationRemoval', ->
  it 'updates related tasks when applied', ->
    tasks = new Backbone.Collection

    supertask = new Backbone.Model id: 'supertask1'
    subtask   = new Backbone.Model id: 'subtask1'

    supertask.removeSubtask = sinon.spy()
    subtask.removeSupertask = sinon.spy()

    tasks.add [supertask, subtask]

    event = new Lt.Models.RelationRemoval
      id            : 'event1'
      relation_type : 'relation_type'
      supertask_id  : 'supertask1'
      subtask_id    : 'subtask1'

    event.apply(tasks)

    expect(supertask.removeSubtask)
      .toHaveBeenCalledWith('relation_type', subtask)
    expect(subtask.removeSupertask)
      .toHaveBeenCalledWith('relation_type', supertask)

