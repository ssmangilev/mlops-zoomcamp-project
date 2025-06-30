🛡️ Project Goal: Detecting Fraudulent Transactions

🎯 Objective

The goal of this project is to automatically detect fraudulent financial transactions using a machine learning pipeline. By leveraging the MLOps lifecycle, we aim to develop, test, deploy, and monitor a robust fraud detection system that can scale in production environments.
💡 Why Fraud Detection Matters

    Financial fraud causes billions in losses globally every year.

    Fraudsters constantly evolve, making manual detection ineffective.

    Early detection helps minimize financial losses and protect customer trust.

    Regulatory compliance often requires institutions to actively detect suspicious activity.

⚙️ Why Automate It?

Manual review of transactions is:

    ❌ Too slow

    ❌ Error-prone

    ❌ Not scalable

By automating fraud detection with ML & MLOps best practices:

    ✅ Models can adapt to new fraud patterns over time

    ✅ Real-time detection becomes possible

    ✅ Continuous integration (CI), testing, and monitoring ensure reliability

    ✅ Infrastructure-as-Code (IaC) and orchestration simplify deployment and maintenance

🔁 MLOps Value

This project isn't just about training a model — it's about building an end-to-end, production-ready system, including:

    ✅ Data validation & transformation

    ✅ Model training & evaluation

    ✅ CI/CD for rapid iteration

    ✅ Infrastructure setup with IaC (e.g., Terraform)

    ✅ Monitoring model performance over time

📈 Impact

Automating fraud detection at scale improves:

    Customer security

    Operational efficiency

    Regulatory compliance

    Business reputation

☁️ Cloud Usage

Although the project is not deployed in the cloud by default, it includes a ready-to-use Terraform configuration that allows you to provision the necessary infrastructure in AWS.

    ⚠️ Important:
    Deploying to AWS is not free — even minimal resources (EC2, S3, etc.) may incur charges.
    Make sure to review AWS pricing and clean up your resources when done.

📦 What Terraform Deploys

The included Terraform code can provision:

    An S3 bucket for storing models or data

    An EC2 instance for running training or inference pipelines

    (Optional) IAM roles, security groups, etc.

This gives you a quick path to running your MLOps pipeline on real cloud infrastructure.
🛠️ How to Use Terraform Locally
1. ✅ Install Terraform

Follow the steps for your OS:

On macOS (Homebrew):

    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform

On Ubuntu/Debian:

    sudo apt update && sudo apt install -y gnupg software-properties-common curl
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform

Verify installation:

    terraform -v

2. 🔧 Configure AWS Credentials

Make sure you have AWS CLI installed and run:

aws configure

This will prompt you to enter your:

    AWS Access Key ID

    AWS Secret Access Key

    Default region (e.g. us-west-1)

    Output format (e.g. json)

    ⚠️ Use a test AWS account to avoid unexpected charges.

3. 🚀 Deploy the Infrastructure

Navigate to the terraform folder in the repo and run:


    cd terraform

    terraform init
    terraform plan
    terraform apply


This will show a preview and then deploy the resources.
1. 🧹 Tear Down Resources (Very Important)

When you're done, make sure to destroy everything:

    terraform destroy

This helps you avoid AWS charges for idle resources.


🐳 Local Deployment with Docker Compose

In addition to Terraform-based cloud deployment, this project supports local infrastructure using Docker Compose. This is ideal for development, testing, and demo purposes without requiring cloud resources.

📁 Where to Find Docker Compose Files

All Docker Compose configuration files are located in the infrastructure folder of the project.

You can find files for services such as:

    MLflow Tracking Server

    Postgres (as MLflow backend)

    Airflow Server

    MinIO or local S3-compatible storage


⚠️ Important Before Running Docker Compose

Before running the services, make sure to review and update volume paths in the docker-compose.yml file:

    The volume mounts are often set to absolute paths on the host system.

    You should change these paths to directories that exist on your local machine to avoid errors and data loss.

    Failing to update volume paths may cause permission issues or overwrite important data.

⚙️ How to Run Locally with Docker Compose
1. ✅ Install Docker & Docker Compose

On macOS / Windows:

    Download and install Docker Desktop:
    https://www.docker.com/products/docker-desktop/

On Ubuntu:

    sudo apt update
    sudo apt install docker.io docker-compose
    sudo usermod -aG docker $USER
    newgrp docker

2. 🧱 Build Docker Images

Navigate to the infrastructure folder and build the services:

    cd infrastructure
    docker-compose build

This will build all Docker images defined in the docker-compose.yml file.
3. 🚀 Start All Services

After building, start the containers with:

    docker-compose up

This will spin up all defined services and you should be able to access:

    MLflow UI (usually on http://localhost:5000)

    MinIO (e.g., http://localhost:9001, default credentials often minioadmin:minioadmin)

    Postgres (on port 5432, used as MLflow backend)

    📌 Tip: You can also run services in the background with docker-compose up -d

4. 🧼 Shut Down and Clean Up

When you're done, stop the containers with:

    docker-compose down

To remove volumes and networks as well:

    docker-compose down -v --remove-orphans


🔍 Experiment Tracking & Model Registry

This project leverages MLflow to manage both experiment tracking and model registry, ensuring a robust and reproducible MLOps workflow.

    Experiment Tracking:
    Every training run is logged with MLflow, capturing key metrics, parameters, and artifacts. This allows you to compare model versions easily, track performance trends, and make data-driven decisions.

    Model Registry:
    Models are registered and versioned within MLflow’s Model Registry. This enables smooth transition from experimentation to deployment by managing stages like Staging, Production, and Archived.

Using MLflow for both experiment tracking and model registry provides:

    A single source of truth for all model-related metadata

    Simplified model lifecycle management

    Seamless integration with deployment workflows

You can access the MLflow UI locally (via Docker Compose) or on the cloud (if deployed), making it easy to monitor and manage models throughout their lifecycle.

🔄 Workflow Orchestration

The project uses Apache Airflow 3.0.1 to orchestrate the machine learning pipeline. Airflow manages the end-to-end workflow, automating tasks such as data ingestion, model training, evaluation, and deployment.

Key benefits include:

    Clear task dependencies defined via Directed Acyclic Graphs (DAGs)

    Scheduling and monitoring workflows with an intuitive UI

    Retries and failure handling to improve pipeline robustness

    Support for scaling and extensibility via custom operators and plugins

Airflow integration ensures your ML workflow is automated, reproducible, and maintainable.

You can run Airflow locally via Docker Compose or deploy it in the cloud using Terraform.

🚀 Model Deployment

The model deployment in this project is implemented as a containerized Python Kafka consumer application.

    The deployment code is packaged into a Docker container, ensuring consistency across environments.

    The Kafka consumer listens to input streams, performs inference using the trained model, and outputs predictions in real-time.

    This containerized setup allows easy deployment either locally with Docker or on cloud platforms supporting container orchestration.

    The architecture supports scalable, event-driven model inference suitable for production use.

Containerization simplifies CI/CD integration and cloud portability, enabling seamless updates and maintenance of deployed models.

📈 Model Monitoring

The project implements comprehensive model monitoring that goes beyond simple metric reporting.

    Monitoring is performed using Evidently, which continuously analyzes model predictions and input data for drift, performance degradation, and other anomalies.

    These metrics and alerts are integrated with Prometheus, enabling efficient time-series data collection and alerting rules.

    The monitoring dashboards are visualized in Grafana, providing real-time insights into model health and data quality.

    If any defined metric thresholds are violated, the system can trigger conditional workflows such as:

        Automatic model retraining

        Generating debugging dashboards

        Switching to a fallback or alternative model

This setup ensures that the deployed models remain reliable and performant over time, supporting proactive maintenance and minimizing business risk.