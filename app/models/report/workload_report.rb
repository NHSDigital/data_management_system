module Report
  # ODR Report showing all open projects assigned to a given application manager, to support
  # offline working.
  # See Plan.IO #26901
  class WorkloadReport < OpenProjectReport
    def relation
      super.assigned_to(user_context)
    end
  end
end
