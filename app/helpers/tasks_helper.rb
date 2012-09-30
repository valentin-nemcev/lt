module TasksHelper
  def fetch_related_tasks(related_ids_hash)
    Hash[related_ids_hash.map{ |rel_ids_name, ids|
      rel_name = rel_ids_name.to_s.sub(/_ids$/, '').pluralize.to_sym
      tasks = ids.map{ |id| storage.fetch id }
      [rel_name, tasks]
    }]
  end
end
