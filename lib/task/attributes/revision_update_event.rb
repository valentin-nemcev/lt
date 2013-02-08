module Task
  class Attributes::RevisionUpdateEvent < Event
    alias_method :revision, :target

    def type
      'task_update'
    end

    def id
      "#{revision.id}-#{revision.task_id}"
    end

    def previous_revision
      revision.previous_revision
    end

    def changed_revisions
      [previous_revision, revision].compact
    end

    def date
      revision.update_date
    end


    def as_json(*)
      super.merge \
        :task_id        => revision.task_id,
        :attribute_name => revision.attribute_name,
        :updated_value  => revision.updated_value
    end
  end
end
