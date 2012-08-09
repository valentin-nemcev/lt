module Task
  module RelationMethods

    include ::Graph::Node

    # TODO: Better way to extend NodeEdges
    module EffectiveEdges
      def effective
        ed = node.effective_date
        filter do |edge|
          edge.added_on <= ed && (!edge.removed_on || edge.removed_on > ed)
        end
      end

      def effective_tasks
        nodes.map{ |n| n.as_of node.effective_date }
      end
    end

    def initialize(attrs={})
      super

      edges.extend EffectiveEdges

      # Shortcuts
      attrs[:project].try { |p| add_project p }

      attrs.fetch(:projects        , []).each { |t| add_project        t }
      attrs.fetch(:dependent_tasks , []).each { |t| add_dependent_task t }
      attrs.fetch(:blocking_tasks  , []).each { |t| add_blocking_task  t }
      attrs.fetch(:component_tasks , []).each { |t| add_component_task t }
    end


    def add_related_task(opts)
      if opts[:supertask]
        opts[:subtask] = self
      elsif opts[:subtask]
        opts[:supertask] = self
      else
        raise ArgumentError, 'Sub or supertask is missing'
      end
      opts[:on] ||= self.effective_date
      Relation.new opts
    end

    def remove_related_task(opts)
      if supertask = opts.delete(:supertask)
        rel = edges.incoming.find{ |e| e.nodes.parent == supertask }
      elsif subtask = opts.delete(:subtask)
        rel = edges.outgoing.find{ |e| e.nodes.child == subtask }
      else
        raise ArgumentError, 'Sub or supertask is missing'
      end
      rel.remove opts if rel.present?
    end

    def relations
      edges.to_a
    end

    def with_connected_tasks_and_relations
      tasks, relations = edges.nodes_and_edges
      tasks << self
      [tasks, relations]
    end


    # Shortcuts

    def add_project project, opts={}
      add_related_task opts.merge supertask: project, :type => :composition
    end

    def remove_project project, opts={}
      remove_related_task opts.merge supertask: project
    end

    def add_component_task component, opts={}
      add_related_task opts.merge subtask: component, :type => :composition
    end

    def remove_component_task component, opts={}
      remove_related_task opts.merge subtask: component
    end

    def add_dependent_task dependent, opts={}
      add_related_task opts.merge supertask: dependent, :type => :dependency
    end

    def remove_dependent_task dependent, opts={}
      remove_related_task opts.merge supertask: dependent
    end

    def add_blocking_task blocking, opts={}
      add_related_task opts.merge subtask: blocking, :type => :dependency
    end

    def remove_blocking_task blocking, opts={}
      remove_related_task opts.merge subtask: blocking
    end


    def subtasks
      edges.effective.outgoing.effective_tasks
    end

    def supertasks
      edges.effective.incoming.effective_tasks
    end

    def blocking_tasks
      edges.effective.outgoing.filter(&:dependency?).effective_tasks
    end

    def dependent_tasks
      edges.effective.incoming.filter(&:dependency?).effective_tasks
    end

    def projects
      edges.effective.incoming.filter(&:composition?).effective_tasks
    end

    def project
      raise InvalidTaskError, 'Task has more than one project' if projects.many?
      projects.first
    end

    def component_tasks
      edges.effective.outgoing.filter(&:composition?).effective_tasks
    end

  end
end
