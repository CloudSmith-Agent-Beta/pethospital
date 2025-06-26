# Pet Hospital Management System

A comprehensive pet hospital management system built with microservices architecture running on Amazon EKS. 

## Architecture

This project implements a microservices architecture with the following components:

- **Backend Services**:
  - Pet Service: Manage pet information
  - Hospital Service: Manage hospital information
  - Doctor Service: Manage doctor information
  - Billing Service: Handle billing operations
  - Insurance Service: Manage pet insurance
  - Visit Service: Track pet visits
  - Vet Service: Manage veterinarian information

- **Frontend**: React-based UI for the application

- **Infrastructure**: AWS resources managed with Terraform
  - Amazon EKS for Kubernetes orchestration
  - Amazon RDS for databases
  - Amazon CloudWatch for monitoring and alerting
  - AWS Application Load Balancer for traffic routing

- **CI/CD**: GitOps workflow using GitHub Actions and ArgoCD

## Getting Started

### Prerequisites

- AWS CLI configured
- kubectl installed
- Terraform installed
- Docker installed
- If you want to clone and deploy the application to your account, then create a repository secret with `AWS_ROLE_ARN` key and a OIDC role to github.
  
### Deployment

The application is deployed automatically via GitHub Actions workflows:

1. Push changes to the `main` branch to trigger infrastructure and application deployment
2. Run GitHub workflow `setup.yml` once to setup the terraform state S3 bucket.
3. Then run GitHub workflow `deploy.yml` to
   - Apply Terraform configurations
   - Build and push Docker images
   - Deploy to EKS using ArgoCD

### Connect to ArgoCD UI

To connect to argoCD UI, run below commands to port forward.
- `aws eks update-kubeconfig --region us-west-2 --name pet-hospital-eks-cluster --role-arn arn:aws:iam::<AWS_ACCOUNT>:role/github-actions-role`
- `kubectl port-forward svc/argocd-server -n argocd 8080:80`
- Username is admin
- To get password run: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

### Cleanup

To remove all AWS resources:

1. Go to the GitHub Actions tab
2. Run the "Terraform Destroy" workflow manually

## Monitoring

The application is monitored using AWS CloudWatch with alerts for:
- Service health
- API latency
- Error rates

## Development

Follow the standard GitOps workflow:
1. Create a feature branch
2. Make changes
3. Submit a pull request
4. After approval and merge, changes will be automatically deployed.
