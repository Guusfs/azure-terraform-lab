# Bloco obrigatório do Terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Configuração do Provedor Azure
provider "azurerm" {
  features {}
}

# --- Bloco 1: Grupo de Recursos ---
resource "azurerm_resource_group" "rg_estudos" {
  name     = "rg-terraform-estudos-gustavo"
  location = "East US 2" # Região com alta disponibilidade

  tags = {
    ambiente   = "estudos"
    owner      = "gustavo"
    criado_com = "terraform"
  }
}

# --- Bloco 2: Rede Virtual (VNet) ---
resource "azurerm_virtual_network" "vnet_estudos" {
  name                = "vnet-principal-estudos"
  location            = azurerm_resource_group.rg_estudos.location
  resource_group_name = azurerm_resource_group.rg_estudos.name
  address_space       = ["10.10.0.0/16"]

  tags = {
    ambiente = "estudos"
    owner    = "gustavo"
  }
}

# --- Bloco 3: Sub-rede (Subnet) ---
resource "azurerm_subnet" "subnet_web" {
  name                 = "snet-web-servidores"
  resource_group_name  = azurerm_resource_group.rg_estudos.name
  virtual_network_name = azurerm_virtual_network.vnet_estudos.name
  address_prefixes     = ["10.10.1.0/24"]
}

# --- Bloco 4: Grupo de Segurança de Rede (NSG) ---
resource "azurerm_network_security_group" "nsg_web" {
  name                = "nsg-servidores-web"
  location            = azurerm_resource_group.rg_estudos.location
  resource_group_name = azurerm_resource_group.rg_estudos.name

  # Regra 1: Permitir SSH (porta 22) para podermos conectar
  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Regra 2: Permitir o tráfego do nosso site Docker (porta 80)
  security_rule {
    name                       = "AllowWeb"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = {
    ambiente = "estudos"
    owner    = "gustavo"
  }
}

# --- Bloco 5: Associação do NSG com a Sub-rede ---
resource "azurerm_subnet_network_security_group_association" "assoc_nsg_subnet" {
  subnet_id                 = azurerm_subnet.subnet_web.id
  network_security_group_id = azurerm_network_security_group.nsg_web.id
}

# --- Bloco 6: IP Público (PIP) ---
resource "azurerm_public_ip" "pip_vm" {
  name                = "pip-vm-linux" # Mudei o nome para refletir o Linux
  location            = azurerm_resource_group.rg_estudos.location
  resource_group_name = azurerm_resource_group.rg_estudos.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    ambiente = "estudos"
    owner    = "gustavo"
  }
}

# --- Bloco 7: Placa de Rede (NIC) ---
resource "azurerm_network_interface" "nic_vm" {
  name                = "nic-vm-linux" # Mudei o nome para refletir o Linux
  location            = azurerm_resource_group.rg_estudos.location
  resource_group_name = azurerm_resource_group.rg_estudos.name

  ip_configuration {
    name                          = "ipconfig-vm"
    subnet_id                     = azurerm_subnet.subnet_web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_vm.id
  }
}

# --- Bloco 8: A Máquina Virtual (Linux Ubuntu) ---
resource "azurerm_linux_virtual_machine" "vm_linux" {
  name                  = "vm-servidor-docker-01"
  computer_name         = "vm-docker-01"
  location              = azurerm_resource_group.rg_estudos.location
  resource_group_name   = azurerm_resource_group.rg_estudos.name
  size                  = "Standard_B1s" # VM barata
  admin_username        = "gustavoadmin"
  disable_password_authentication = true # Força o uso da chave SSH (mais seguro)

  # A Chave SSH que você gerou
  admin_ssh_key {
    username   = "gustavoadmin"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVrurFONufUIVHRMos+TwQLMt85aFOFEjv6O7Gar/qvTmMajvcrO37TSx5mhkmt4oZnfTbpPeRspN8nf90H/Y5VeSiK2g6jWbm19k3ygUA0tJ+f7BnGlIawsCAwr74pduQf1/4Dpu3yqIC2zMn/rIPQZ/tZUysnsjVsZ1m8fznG7nIkI6s+DaJevve/goEIYxtIZy2DkQuAH5BeV+jf4msHY7GH0A3R4QMkd4wqwi7dM324MOzQDgkCHZINpe7xpS6VX2COFWlg9uTE+4Dk51dHpTuF6/BbfXDpfyHCL8KdMOrHGZTBuaDnj2lgSmg9kBYfHsJ8RcwE6Wkoa7dg52wqdHnYqTIlFaVlKmzSZPHg2titKcppkYicYZSEBO85dyLuXhF9Y7h9gZmUwJ5eBQ9/ldDPonmhTqwHxFRIbfRH8a8GC8NYHeSez51+3GX54ybuMIszbT9p4ohJIJ0OSNJ8EkrH33AlnR9eJxzzzrCDtxJ/WIdp4G1sm6oCUnmk9cTk0OcOZFM8oAbFos/ztN0PQYLSCySvsC7AlWaNBAip9zPtNjCBE5eBRlrDuv6uD6yi02yFBkwEuGqBlaYo7tcpq58QvMbJYV5mEcdx/7JLwGPcav8PNW6eLd+C0K4QnkwnBhKRnT52JE9WZsDeDQk+w19RTL+p6/UNDiZIZsGYQ== Gustavo S@Gustavo-Homecd /c/azure-terraform-lab"
  }

  # Conecta na nossa placa de rede
  network_interface_ids = [
    azurerm_network_interface.nic_vm.id,
  ]

  # O disco do Sistema Operacional
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # A Imagem do Linux (Marketplace)
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # --- O PROJETO FINAL: UNINDO TERRAFORM + DOCKER ---
  # Este script roda na primeira vez que a VM liga.
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Mapeia a porta 80 (padrão web) para a porta 8000 (do seu app)
    sudo docker run -d -p 80:8000 guusoares/meu-primeiro-app
  EOF
  )
}

# --- Bloco 9: Saída (Output) ---
output "ip_publico_vm_linux" {
  value       = azurerm_public_ip.pip_vm.ip_address
  description = "O IP publico para acessar o site Dockerizado."
}