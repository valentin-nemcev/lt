describe 'Filtered collection', ->
  filterOpts = modelFilter: (model) -> model.get('filtered')
  original = null
  filtered = null

  beforeEach ->
    original = new Backbone.Collection([
      id: 'filtered_model1'
      filtered: yes
    ,
      id: 'unfiltered_model1'
      filtered: no
    ])
    filtered = new Backbone.FilteredCollection original, filterOpts


  describe 'after initialize', ->
    it 'contains filtered models from original', ->
      expect(filtered.pluck('id')).toEqual(['filtered_model1'])

  describe 'reset', ->
    resetCallback = null
    beforeEach ->
      resetCallback = sinon.spy()
      filtered.on 'reset', resetCallback
      original.reset([
        id: 'filtered_model2'
        filtered: yes
      ,
        id: 'unfiltered_model2'
        filtered: no
      ])

    it 'contains new filtered models from original', ->
      expect(filtered.pluck('id')).toEqual(['filtered_model2'])

    it 'fires correct reset event', ->
      expect(resetCallback).toHaveBeenCalledWith(filtered)

  describe 'add', ->
    addCallback = null
    addedModel = null
    beforeEach ->
      addCallback = sinon.spy()
      filtered.on 'add', addCallback
      original.add([
        id: 'filtered_model2'
        filtered: yes
      ,
        id: 'unfiltered_model2'
        filtered: no
      ])

      addedModel = original.get('filtered_model2')

    it 'it adds only filtered model', ->
      expect(filtered.pluck('id'))
        .toEqual(['filtered_model1', 'filtered_model2'])

    it 'fires correct add event', ->
      expect(addCallback).toHaveBeenCalledWith(addedModel, filtered)

  describe 'remove', ->
    removeCallback = null
    removedModel = null
    beforeEach ->
      removeCallback = sinon.spy()
      filtered.on 'remove', removeCallback
      original.add([
        id: 'filtered_model2'
        filtered: yes
      ,
        id: 'unfiltered_model2'
        filtered: no
      ])

      removedModel = original.get('filtered_model2')

      original.remove('filtered_model2')

    it 'it removes only filtered model', ->
      expect(filtered.pluck('id'))
        .toEqual(['filtered_model1'])

    it 'fires correct remove event', ->
      expect(removeCallback).toHaveBeenCalledWith(removedModel, filtered)


  describe 'add via change', ->
    addCallback = null
    changedModel = null
    beforeEach ->
      addCallback = sinon.spy()
      filtered.on 'add', addCallback
      original.add([
        id: 'model1'
        filtered: no
      ])

      changedModel = original.get('model1')
      changedModel.set('filtered', yes)

    it 'it adds model after it became filtered', ->
      expect(filtered.pluck('id'))
        .toEqual(['filtered_model1', 'model1'])

    it 'fires correct add event', ->
      expect(addCallback).toHaveBeenCalledWith(changedModel, filtered)

  describe 'remove via change', ->
    removeCallback = null
    changedModel = null
    beforeEach ->
      removeCallback = sinon.spy()
      filtered.on 'remove', removeCallback
      original.add([
        id: 'model1'
        filtered: yes
      ])

      changedModel = original.get('model1')
      changedModel.set('filtered', no)

    it 'it removes model after it stopped being filtered', ->
      expect(filtered.pluck('id'))
        .toEqual(['filtered_model1'])

    it 'fires correct remove event', ->
      expect(removeCallback).toHaveBeenCalledWith(changedModel, filtered)
