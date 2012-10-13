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

    def edges
      @edges ||= Relations.new(self)
    end

    def update_related_tasks(new_related_tasks = {}, opts = {})
      new_related_tasks.flat_map do |relation_name, tasks|
        tasks.map do
          |task| add_relation(relation_name, task, opts)
        end.compact
      end
    end

    def add_relation(name, task, additional_opts)
      relation_opts = relation_opts_for(name)
      related_tasks = case relation_opts[:relation]
                      when :sub   then {subtask: task, supertask: self}
                      when :super then {subtask: self, supertask: task}
                      else {}
                      end
      Relation.new [
        related_tasks,
        {type: relation_opts[:type]},
        additional_opts
      ].inject(&:merge)
    rescue Relations::DuplicateRelationError
    end

    def relations
      edges.to_a
    end

    def destroy_relations
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
