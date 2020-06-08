namespace :project_dataset do
  task migrate: :environment do
    counter = 0
    Project.all.each do |project|
      next unless project.team_dataset_id
      next if project.datasets.present?

      pd = ProjectDataset.new(dataset: TeamDataset.find(project.team_dataset_id).dataset,
                              terms_accepted: true)
      project.project_datasets << pd
      counter += 1
    end
    print "Updated #{counter} projects\n"
  end
end
