# Task Queues
output "task_queues" {
  description = "Cloud Tasks queue information"
  value = {
    for k, v in google_cloud_tasks_queue.queues : k => {
      id       = v.id
      name     = v.name
      location = v.location
      project  = v.project
    }
  }
}

# Queue Names
output "queue_names" {
  description = "Cloud Tasks queue names"
  value = {
    for k, v in google_cloud_tasks_queue.queues : k => v.name
  }
}

# Queue URLs
output "queue_urls" {
  description = "Cloud Tasks queue URLs for API calls"
  value = {
    for k, v in google_cloud_tasks_queue.queues : k =>
    "https://cloudtasks.googleapis.com/v2/projects/${var.project_id}/locations/${v.location}/queues/${v.name}"
  }
}

# Summary
output "task_queues_summary" {
  description = "Summary of Cloud Tasks deployment"
  value = {
    total_queues = length(google_cloud_tasks_queue.queues)

    queues_by_location = {
      for location in distinct([for q in google_cloud_tasks_queue.queues : q.location]) :
      location => [
        for k, v in google_cloud_tasks_queue.queues :
        v.name if v.location == location
      ]
    }

    queue_details = {
      for k, v in google_cloud_tasks_queue.queues : k => {
        name      = v.name
        location  = v.location
        full_name = "projects/${var.project_id}/locations/${v.location}/queues/${v.name}"
      }
    }
  }
}
