module TasksHelper
  def fetch_related_tasks(params)
    tasks = Hash.new do |tasks, rel_name|
      tasks[rel_name] = {supertasks: [], subtasks: [] }
    end
    {
      :supertask_ids => :supertasks,
      :subtask_ids => :subtasks
    }.each do |rel_ids, rel|
      params.symbolize_keys.fetch(rel_ids, {}).each do |rel_name, ids|
        rel_tasks = ids.compact.map{ |id| storage.fetch id }
        tasks[rel_name.to_sym][rel.to_sym] = rel_tasks
      end
    end
    tasks
  end
end
