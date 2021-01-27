module SharedMailersNotifications
  def notify_and_mail_requires_dataset_approval(project)
    DatasetRole.fetch(:approver).users.each do |user|
      matching_datasets = project.project_datasets.any? do |pd|
        ProjectDataset.dataset_approval(user, nil).include? pd
      end
      next unless matching_datasets

      CasNotifier.requires_dataset_approval(project, user.id)
      CasMailer.with(project: project, user: user).send(:requires_dataset_approval).deliver_now
    end
  end
end
