# 🏗️ AWS Multi-Tier Architecture using Terraform

This Terraform project sets up a complete multi-tier infrastructure on AWS. It includes a **public-facing Application Load Balancer (ALB)**, a **private internal ALB**, **reverse proxy instances**, **backend EC2 instances**, and a **bastion host**. The infrastructure is modular and includes four separate modules: `VPC`, `Security Groups`, `EC2`, and `ALB`.

---

## 📌 Project Structure

```bash
.
├── Modules/
│   ├── ALB/
│   │   ├── ALB.tf
│   │   ├── output.tf
│   │   └── variables.tf
│   ├── EC2/
│   │   ├── ec2.tf
│   │   ├── output.tf
│   │   └── variables.tf
│   ├── Security Group/
│   │   ├── sg.tf
│   │   ├── output.tf
│   │   └── variables.tf
│   └── VPC/
│       ├── vpc.tf
│       ├── output.tf
│       └── variables.tf
├── main.tf
├── provider.tf
├── variables.tf
├── terraform.tfvars       # (User can define custom values here)
├── terraform.tfvars.example
├── .gitignore
├── AWS-Diagram.svg        # Architecture diagram (image)
└── README.md              # This file
```

---

## 🧠 Architecture Overview

![AWS Diagram](AWS-Diagram.svg)

### 🔧 Key Components

- **VPC** with multiple public and private subnets across 2 AZs (`eu-west-2a` and `eu-west-2b`)
- **Public ALB** routes traffic to reverse proxies in private subnets.
- **Internal ALB** forwards requests to backend instances.
- **Reverse Proxy EC2 Instances** (Private Subnets)
- **Backend EC2 Instances** (Private Subnets)
- **Bastion Host** for SSH access (Public Subnet)
- **NAT Gateway** for outbound internet from private instances
- **Security Groups** that restrict traffic appropriately between tiers

---

## 🛠 Prerequisites

Before you begin, make sure you have the following:

1. **AWS CLI installed and configured**
   - Install from: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html
   - Then configure using:
     ```bash
     aws configure
     ```
     Provide your **Access Key ID**, **Secret Access Key**, default region (`eu-west-2`), and output format (`json`).

2. **An existing AWS Key Pair**
   - Create one via the AWS Console or CLI:
     ```bash
     aws ec2 create-key-pair --key-name my-key --query 'KeyMaterial' --output text > my-key.pem
     chmod 400 my-key.pem
     ```
   - Then provide the **key pair name** in `terraform.tfvars`:
     ```hcl
     key_pair = "my-key"
     ```

---

## 📥 How to Use

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/terraform-aws-multi-tier.git
cd terraform-aws-multi-tier
```

### 2. Customize Variables

Edit the `terraform.tfvars` file with your desired values. Example:

```hcl
instance_type    = "t2.micro"
instance_ami     = "ami-04da26f654d3383cf"
instance_keypair = "terraform-keypair"
region = "eu-west-2"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan the Deployment

```bash
terraform plan
```

### 5. Apply the Configuration

```bash
terraform apply
```

Type `yes` to confirm.

---

## 🔐 Security Notes

- **Bastion Host**: Use your `.pem` key and public IP to SSH into it.
- **Private Instances**: Only accessible through the Bastion Host or via internal communication.
- **Security Groups**:
  - Public ALB → Reverse Proxy
  - Reverse Proxy → Internal ALB
  - Internal ALB → Backend
  - Bastion → Reverse Proxy / Backend via SSH (restricted)

---

## 🧹 Cleanup

To destroy all resources created by this project:

```bash
terraform destroy
```

Type `yes` to confirm.

---

## 🧾 License

This project is licensed under the MIT License.

---

## 🙋‍♂️ Author

**Mohaned Ahmed**  
Multi-Cloud & DevOps Engineer  
[LinkedIn](https://linkedin.com/in/mohaned-ahmad) | [GitHub](https://github.com/MuhanedAhmed)