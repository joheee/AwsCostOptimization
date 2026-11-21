output "schedule_names" {
  value = [for s in aws_scheduler_schedule.office_hours : s.name]
}
