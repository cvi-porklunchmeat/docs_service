resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 1
  min_capacity       = 1
  resource_id        = "service/${module.tfm_aws_ecs.ecs_cluster.name}/${module.tfm_aws_ecs.aws_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# AWS Cron Docs
# https://docs.aws.amazon.com/autoscaling/application/userguide/scheduled-scaling-using-cron-expressions.html


# Scale down to 1 MIN and MAX tasks at 5:00 PM Pacific (PDT) on Friday / 1:00 AM London (BST) on Saturday
resource "aws_appautoscaling_scheduled_action" "friday_evening" {
  name               = "${var.env_name}-scale-down"
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  schedule           = "cron(0 0 ? * SAT *)"

  scalable_target_action {
    min_capacity = 1
    max_capacity = 1
  }

}

# Scale up to 2 MIN - 3 MAX tasks at 10:00 PM Pacific (PDT) on Sunday / 6:00 AM London (BST) on Monday
resource "aws_appautoscaling_scheduled_action" "monday_morning" {
  name               = "${var.env_name}-scale-up"
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  schedule           = "cron(0 5 ? * MON *)"

  scalable_target_action {
    min_capacity = 2
    max_capacity = 3
  }

  depends_on = [aws_appautoscaling_scheduled_action.friday_evening]
}
