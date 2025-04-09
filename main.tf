# --------------------------------------------------------------
# Creating a VPC
# --------------------------------------------------------------

module "main_VPC" {
  source             = "./Modules/VPC"
  vpc_ip             = var.main_vpc_ip
  public_subnet_IP_1 = var.public_subnet_IP_1
  public_subnet_IP_2 = var.public_subnet_IP_2
  public_subnet_AZ_1 = var.public_subnet_AZ_1
  public_subnet_AZ_2 = var.public_subnet_AZ_2
  private_subnet1_IP = var.private_subnet1_IP
  private_subnet2_IP = var.private_subnet2_IP
  private_subnet3_IP = var.private_subnet3_IP
  private_subnet4_IP = var.private_subnet4_IP
  private_subnet1_AZ = var.private_subnet1_AZ
  private_subnet2_AZ = var.private_subnet2_AZ
  private_subnet3_AZ = var.private_subnet3_AZ
  private_subnet4_AZ = var.private_subnet4_AZ
}


# --------------------------------------------------------------
# Creating Security Group for the Reverse-Proxies
# --------------------------------------------------------------

module "ReverseProxy_SG" {
  source      = "./Modules/Security Group"
  name        = "ReverseProxy_SG"
  description = "Allow HTTP traffic from Public ALB and SSH traffic from Bastion Host."
  vpc_id      = module.main_VPC.vpc_id


  ingress_rules = {
    http = {
      cidr_ipv4                    = null
      referenced_security_group_id = module.External_ALB_SG.SecurityGroup_ID
      from_port                    = 80
      ip_protocol                  = "tcp"
      to_port                      = 80
    }
    ssh = {
      cidr_ipv4                    = null
      referenced_security_group_id = module.Bastion_SG.SecurityGroup_ID
      from_port                    = 22
      ip_protocol                  = "tcp"
      to_port                      = 22
    }
  }
}


# --------------------------------------------------------------
# Creating Reverse Proxy servers
# --------------------------------------------------------------

module "ReverseProxy01" {
  source             = "./Modules/EC2"
  instance_name      = "ReverseProxy01"
  instance_ami       = var.instance_ami
  instance_type      = var.instance_type
  instance_subnet_id = module.main_VPC.private_subnet3_id
  private_ip         = "10.10.50.10"
  SG_id              = module.ReverseProxy_SG.SecurityGroup_ID
  keyname            = var.instance_keypair
  Is_PublicIP        = false
  depends_on         = [module.main_VPC, module.INT_ALB]
  userdata           = <<-EOF
#!/bin/bash
# Update system and install Nginx
apt-get update
apt-get install -y nginx

# NGINX reverse proxy configuration
echo 'server {
  listen 80;
  location / {
    proxy_pass http://${module.INT_ALB.ALB_DNS};
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}' | tee /etc/nginx/sites-available/default > /dev/null

# Create symlink for sites-enabled
ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Test and restart nginx
nginx -t && systemctl restart nginx
systemctl enable nginx
EOF
}

module "ReverseProxy02" {
  source             = "./Modules/EC2"
  instance_name      = "ReverseProxy02"
  instance_ami       = var.instance_ami
  instance_type      = var.instance_type
  instance_subnet_id = module.main_VPC.private_subnet4_id
  private_ip         = "10.10.60.10"
  SG_id              = module.ReverseProxy_SG.SecurityGroup_ID
  keyname            = var.instance_keypair
  Is_PublicIP        = false
  depends_on         = [module.main_VPC, module.INT_ALB]
  userdata           = <<-EOF
#!/bin/bash
# Update system and install Nginx
apt-get update
apt-get install -y nginx

# NGINX reverse proxy configuration
echo 'server {
  listen 80;
  location / {
    proxy_pass http://${module.INT_ALB.ALB_DNS};
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}' | tee /etc/nginx/sites-available/default > /dev/null

# Create symlink for sites-enabled
ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Test and restart nginx
nginx -t && systemctl restart nginx
systemctl enable nginx
EOF
}


# --------------------------------------------------------------
# Creating Security Group for Bastion Host
# --------------------------------------------------------------

module "Bastion_SG" {
  source      = "./Modules/Security Group"
  name        = "Bastion_SG"
  description = "Allow SSH traffic."
  vpc_id      = module.main_VPC.vpc_id


  ingress_rules = {
    ssh = {
      cidr_ipv4                    = "0.0.0.0/0"
      referenced_security_group_id = null
      from_port                    = 22
      ip_protocol                  = "tcp"
      to_port                      = 22
    }
  }
}


# --------------------------------------------------------------
# Creating Bastion Host
# --------------------------------------------------------------

module "Bastion_Host" {
  source             = "./Modules/EC2"
  instance_name      = "Bastion_Host"
  instance_ami       = var.instance_ami
  instance_type      = var.instance_type
  instance_subnet_id = module.main_VPC.public_subnet_id_2
  SG_id              = module.Bastion_SG.SecurityGroup_ID
  keyname            = var.instance_keypair
  Is_PublicIP        = true
}



# --------------------------------------------------------------
# Creating Security Group for Backend Servers
# --------------------------------------------------------------

module "Backend_SG" {
  source      = "./Modules/Security Group"
  name        = "Backend_SG"
  description = "Allow HTTP traffic from Private ALB and SSH traffic from Bastion Host."
  vpc_id      = module.main_VPC.vpc_id


  ingress_rules = {
    http = {
      cidr_ipv4                    = null
      referenced_security_group_id = module.Internal_ALB_SG.SecurityGroup_ID
      from_port                    = 80
      ip_protocol                  = "tcp"
      to_port                      = 80
    }
    ssh = {
      cidr_ipv4                    = null
      referenced_security_group_id = module.Bastion_SG.SecurityGroup_ID
      from_port                    = 22
      ip_protocol                  = "tcp"
      to_port                      = 22
    }
  }
}


# --------------------------------------------------------------
# Creating Backend Servers
# --------------------------------------------------------------

module "Backend01" {
  source             = "./Modules/EC2"
  instance_name      = "Backend01"
  instance_ami       = var.instance_ami
  instance_type      = var.instance_type
  instance_subnet_id = module.main_VPC.private_subnet1_id
  private_ip         = "10.10.30.10"
  SG_id              = module.Backend_SG.SecurityGroup_ID
  keyname            = var.instance_keypair
  Is_PublicIP        = false
  depends_on         = [module.main_VPC]
  userdata           = <<-EOF
#!/bin/bash
# Update system and install Nginx
apt-get update
apt-get install -y nginx

# Get system information
HOSTNAME=$(hostname -f)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

echo "<html>
<head>
    <title>EC2 Instance Info</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #336699; }
        .info { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Hello World from $HOSTNAME</h1>
    <div class="info">
        <h2>Instance Information</h2>
        <p><strong>Availability Zone:</strong> $AZ</p>
        <p><strong>Private IP Address:</strong> $PRIVATE_IP</p>
        <p><strong>Hostname:</strong> $HOSTNAME</p>
    </div>
</body>
</html>" | sudo tee /var/www/html/index.nginx-debian.html > /dev/null

sudo systemctl restart nginx
EOF
}


module "Backend02" {
  source             = "./Modules/EC2"
  instance_name      = "Backend02"
  instance_ami       = var.instance_ami
  instance_type      = var.instance_type
  instance_subnet_id = module.main_VPC.private_subnet1_id
  private_ip         = "10.10.30.20"
  SG_id              = module.Backend_SG.SecurityGroup_ID
  keyname            = var.instance_keypair
  Is_PublicIP        = false
  depends_on         = [module.main_VPC]
  userdata           = <<-EOF
#!/bin/bash
# Update system and install Nginx
apt-get update
apt-get install -y nginx

# Get system information
HOSTNAME=$(hostname -f)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

echo "<html>
<head>
    <title>EC2 Instance Info</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #336699; }
        .info { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Hello World from $HOSTNAME</h1>
    <div class="info">
        <h2>Instance Information</h2>
        <p><strong>Availability Zone:</strong> $AZ</p>
        <p><strong>Private IP Address:</strong> $PRIVATE_IP</p>
        <p><strong>Hostname:</strong> $HOSTNAME</p>
    </div>
</body>
</html>" | sudo tee /var/www/html/index.nginx-debian.html > /dev/null

sudo systemctl restart nginx
EOF
}

module "Backend03" {
  source             = "./Modules/EC2"
  instance_name      = "Backend03"
  instance_ami       = var.instance_ami
  instance_type      = var.instance_type
  instance_subnet_id = module.main_VPC.private_subnet2_id
  private_ip         = "10.10.40.10"
  SG_id              = module.Backend_SG.SecurityGroup_ID
  keyname            = var.instance_keypair
  Is_PublicIP        = false
  depends_on         = [module.main_VPC]
  userdata           = <<-EOF
#!/bin/bash
# Update system and install Nginx
apt-get update
apt-get install -y nginx

# Get system information
HOSTNAME=$(hostname -f)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

echo "<html>
<head>
    <title>EC2 Instance Info</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #336699; }
        .info { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Hello World from $HOSTNAME</h1>
    <div class="info">
        <h2>Instance Information</h2>
        <p><strong>Availability Zone:</strong> $AZ</p>
        <p><strong>Private IP Address:</strong> $PRIVATE_IP</p>
        <p><strong>Hostname:</strong> $HOSTNAME</p>
    </div>
</body>
</html>" | sudo tee /var/www/html/index.nginx-debian.html > /dev/null

sudo systemctl restart nginx
EOF
}

module "Backend04" {
  source             = "./Modules/EC2"
  instance_name      = "Backend04"
  instance_ami       = var.instance_ami
  instance_type      = var.instance_type
  instance_subnet_id = module.main_VPC.private_subnet2_id
  private_ip         = "10.10.40.20"
  SG_id              = module.Backend_SG.SecurityGroup_ID
  keyname            = var.instance_keypair
  Is_PublicIP        = false
  depends_on         = [module.main_VPC]
  userdata           = <<-EOF
#!/bin/bash
# Update system and install Nginx
apt-get update
apt-get install -y nginx

# Get system information
HOSTNAME=$(hostname -f)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

echo "<html>
<head>
    <title>EC2 Instance Info</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #336699; }
        .info { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Hello World from $HOSTNAME</h1>
    <div class="info">
        <h2>Instance Information</h2>
        <p><strong>Availability Zone:</strong> $AZ</p>
        <p><strong>Private IP Address:</strong> $PRIVATE_IP</p>
        <p><strong>Hostname:</strong> $HOSTNAME</p>
    </div>
</body>
</html>" | sudo tee /var/www/html/index.nginx-debian.html > /dev/null

sudo systemctl restart nginx
EOF
}


# --------------------------------------------------------------
# Creating Security Group for External Application Load Balancer
# --------------------------------------------------------------

module "External_ALB_SG" {
  source      = "./Modules/Security Group"
  name        = "External_ALB_SG"
  description = "Allow HTTP traffic."
  vpc_id      = module.main_VPC.vpc_id


  ingress_rules = {
    http = {
      cidr_ipv4                    = "0.0.0.0/0"
      referenced_security_group_id = null
      from_port                    = 80
      ip_protocol                  = "tcp"
      to_port                      = 80
    }
  }
}

# --------------------------------------------------------------
# Creating External Application Load Balancer
# --------------------------------------------------------------

module "EXT_ALB" {
  source            = "./Modules/ALB"
  lb_name           = "EXT-ALB"
  target_group_name = "ReverseProxy-Group"
  target_instances_ids = {
    "ReverseProxy01" = module.ReverseProxy01.EC2_id
    "ReverseProxy02" = module.ReverseProxy02.EC2_id
  }
  vpc_id            = module.main_VPC.vpc_id
  subnet_ids        = [module.main_VPC.public_subnet_id_1, module.main_VPC.public_subnet_id_2]
  Security_Group_id = module.External_ALB_SG.SecurityGroup_ID
  Is_Internal       = false
}


# --------------------------------------------------------------
# Creating Security Group for Internal Application Load Balancer
# --------------------------------------------------------------

module "Internal_ALB_SG" {
  source      = "./Modules/Security Group"
  name        = "Internal_ALB_SG"
  description = "Allow HTTP traffic from reverse proxies."
  vpc_id      = module.main_VPC.vpc_id


  ingress_rules = {
    http = {
      cidr_ipv4                    = null
      referenced_security_group_id = module.ReverseProxy_SG.SecurityGroup_ID
      from_port                    = 80
      ip_protocol                  = "tcp"
      to_port                      = 80
    }
  }
}


# --------------------------------------------------------------
# Creating Internal Application Load Balancer
# --------------------------------------------------------------

module "INT_ALB" {
  source            = "./Modules/ALB"
  lb_name           = "INT-ALB"
  target_group_name = "Backend-Group"
  target_instances_ids = {
    "Backend01" = module.Backend01.EC2_id
    "Backend02" = module.Backend02.EC2_id
    "Backend03" = module.Backend03.EC2_id
    "Backend04" = module.Backend04.EC2_id
  }
  vpc_id            = module.main_VPC.vpc_id
  subnet_ids        = [module.main_VPC.private_subnet1_id, module.main_VPC.private_subnet2_id]
  Security_Group_id = module.Internal_ALB_SG.SecurityGroup_ID
  Is_Internal       = true
  depends_on        = [module.Backend01, module.Backend02, module.Backend03, module.Backend04]
}