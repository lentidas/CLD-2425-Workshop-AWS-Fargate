# CLD-2425-Workshop-AWS-Fargate

Repository for the CLD course workshop on AWS Fargate.

## Deployment

As a requirement, ensure you have Terraform installed and configured with your AWS credentials, tipically passed through environment variables (see the [provider's documentation](https://registry.terraform.io/providers/hashicorp/aws/5.99.1/docs) for more details).

To deploy the infrastructure, run the following commands:

```bash
# Clone the repository and go to the Terraform directory
git clone git@github.com:lentidas/CLD-2425-Workshop-AWS-Fargate.git
cd CLD-2425-Workshop-AWS-Fargate/terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the deployment
terraform apply

# Destroy the deployment (optional)
terraform destroy
```

Terraform should output the DNS name of the load balancer, which you can use to access the deployed service.

## PoC Notes

- The service is deployed in the `us-east-1` region, using the `CLD-Workshop-GrE-ecs-cluster` ECS cluster and the `CLD-Workshop-GrE-service` service.
- The service is configured to use Fargate as the launch type, with a task definition that includes a container running a simple web application.
- The service is set to scale automatically based on average request count per target of the Application Load Balancer (ALB). It should scale from 2 to 32 tasks based on the load.

## Show and tell

- Show the ECS cluster in the AWS console -> [link](https://us-east-1.console.aws.amazon.com/ecs/v2/clusters/CLD-Workshop-GrE-ecs-cluster?region=us-east-1)
- Show the service in the AWS console -> [link](https://us-east-1.console.aws.amazon.com/ecs/v2/clusters/CLD-Workshop-GrE-ecs-cluster/services/CLD-Workshop-GrE-service?region=us-east-1)
- Show the running tasks in the AWS console -> [link](https://us-east-1.console.aws.amazon.com/ecs/v2/clusters/CLD-Workshop-GrE-ecs-cluster/services/CLD-Workshop-GrE-service/tasks?region=us-east-1)
- Show the auto-scaling policies as well as the scaling events in the AWS console -> [link](https://us-east-1.console.aws.amazon.com/ecs/v2/clusters/CLD-Workshop-GrE-ecs-cluster/services/CLD-Workshop-GrE-service/service-auto-scaling/view?region=us-east-1)
- Show how it is connected to the Application Load Balancer (*the service console should show the LB attached*).
- Open the web application in the browser using the DNS name of the load balancer, which should be output by Terraform after the deployment. Note that the IP address shown by the container `traefik:whoami` changes on every request, showcasing the multiple tasks running behind the load balancer.
- Show the logs of the tasks in the AWS console -> [link](https://us-east-1.console.aws.amazon.com/ecs/v2/clusters/CLD-Workshop-GrE-ecs-cluster/services/CLD-Workshop-GrE-service/logs?region=us-east-1)
- Scale up the service manually in the AWS console to 8 tasks and observe the changes in the service's task count. 
- Showcase the auto-scaling feature by generating load on the service (e.g., using a load testing tool) and observe how the service scales up to 32 tasks based on the average request count per target of the ALB.

> [!NOTE]
> From our experience, the auto-scaling feature may take a few minutes to scale up, even with a high load from `vegeta` and a low threshold of 10 average requests per target with a cooldown period of 0 seconds. Because of this, on the demo day, we will manually scale the service to 8 tasks and open the web application in the browser to showcase the multiple tasks running behind the load balancer.

## References

- [AWS ECS Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)
- [AWS Fargate Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Best practices for receiving inbound connections to Amazon ECS from the internet](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/networking-inbound.html)
- [Amazon ECS task definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)
- [Example Amazon ECS task definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/example_task_definitions.html)
