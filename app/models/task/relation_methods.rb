module Task
  module RelationMethods
    extend ActiveSupport::Concern

    module ClassMethods
      def has_relation(type, params)
        supers = params.fetch :supers
        subs = params.fetch :subs
        opts = {type: type}
        relation_opts[supers] = opts.merge relation: :super
        relation_opts[subs]   = opts.merge relation: :sub
      end

      def related_tasks
        relation_opts.keys
      end
    end

    included do |base|
      base.class_attribute :relation_opts
      self.relation_opts ||= {}
    end

    def initialize(attrs = {})
      super
      @edges = Relations.new(self)
    end

    attr_reader :edges

    # TODO: Do something with to_s conversion
    def update_related_tasks(new_related_tasks = {}, opts = {})
      effective_date = opts.fetch :on, Time.current
      changed_relations = []
      effective_related_tasks(:on => effective_date).
        each do |relation_type, related|
        related.flat_map do |relation_dir, tasks_with_relations|
          new_tasks = new_related_tasks.fetch(relation_type, {}).
            fetch(relation_dir, [])
          existing_tasks = tasks_with_relations.collect(&:second)
          (new_tasks - existing_tasks).map do |task|
            changed_relations <<
              add_relation(relation_type, relation_dir, task, opts)
          end
          tasks_with_relations.each do |(relation, task)|
            unless new_tasks.include? task
              changed_relations << relation.remove(:on => effective_date)
            end
          end
        end
      end
      changed_relations
    end

    def add_relation(type, relation, task, additional_opts)
      related_tasks = case relation
                      when :supertasks then {subtask: self, supertask: task}
                      when :subtasks   then {subtask: task, supertask: self}
                      else {}
                      end
      params = [related_tasks, {type: type}, additional_opts].inject(&:merge)
      Relation.new params
    end

    def relations
      edges.to_a
    end

    def filtered_relations(args = {})
      opts = relation_opts_for(args.fetch :for)
      e = edges.dup
      case opts[:relation]
      when :super then e.incoming!
      when :sub   then e.outgoing!
      end
      opts.fetch(:type).tap do |type|
        e.filter!{ |r| r.type == type }
      end
      e
    end

    def effective_related_tasks(args = {})
      effective_date = args[:on]
      tasks = Hash.new{ |hash, key| hash[key] = Hash.new }
      self.class.related_tasks.each do |relation_name|
        opts = relation_opts_for(relation_name)
        relation = case opts[:relation]
        when :super then :supertasks
        when :sub   then :subtasks
        end
        tasks[opts[:type]][relation] =
          filtered_relations(:for => relation_name).filter do |r|
            r.effective_on? effective_date
          end.with_nodes
      end
      tasks
    end

    def related(tasks)
      filtered_relations(:for => tasks).nodes
    end

    def related_tasks(args = {})
      e = filtered_relations(args)
      args[:in].try do |interval|
        e.filter!{ |r| r.effective_in? interval }
      end
      e.with_nodes.map do |relation, task|
        [task, relation.effective_interval]
      end
    end

    def last_related_tasks(args = {})
      e = filtered_relations(args)
      args[:before].try do |date|
        e.filter! do |r|
          int = r.effective_interval
          # TODO: Better comparison
          int.beginning <= date && (int.ending.nil? || date <= int.ending)
        end
      end
      e.with_nodes.map do |relation, task|
        [task, relation.effective_interval]
      end
    end

    def destroy
      super
      relations.each(&:destroy)
    end

    def with_connected_tasks_and_relations
      tasks, relations = edges.nodes_and_edges
      [tasks << self, relations]
    end

    protected

    def relation_opts_for(relation_name)
      relation_opts[relation_name]
    end

  end
end
