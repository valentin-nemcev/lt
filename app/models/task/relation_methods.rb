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

    def update_related_tasks(new_related_tasks = {}, opts = {})
      new_related_tasks.flat_map do |relation_type, related|
        related.flat_map do |relation, tasks|
          tasks.map { |task|
            add_relation(relation_type, relation, task, opts)
          }.compact
        end
      end
    end

    def add_relation(type, relation, task, additional_opts)
      related_tasks = case relation
                      when :supertasks then {subtask: self, supertask: task}
                      when :subtasks   then {subtask: task, supertask: self}
                      else {}
                      end
      params = [related_tasks, {type: type}, additional_opts].inject(&:merge)
      Relation.new params
    rescue Relations::DuplicateRelationError
    end

    def relations
      edges.to_a
    end

    def related(filter_opts = {})
      e = edges.dup
      case filter_opts[:relation]
      when :super then e.incoming!
      when :sub   then e.outgoing!
      end
      if type = filter_opts[:type]
        e.filter!{ |r| r.type == type }
      end
      e.nodes
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
