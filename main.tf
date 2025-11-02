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
# Ele vai usar a conta que você logou com "az login"
provider "azurerm" {
  features {}
}

# ---------------------------------------------------
# Este é o nosso primeiro recurso.
# Um "Resource Group" (Grupo de Recursos) é um 
# container lógico para agrupar recursos do Azure.
# ---------------------------------------------------
resource "azurerm_resource_group" "rg_estudos" {
  name     = "rg-terraform-estudos-gustavo" # Coloquei um nome único
  # location = "Brazil South" # <-- REGIÃO SEM CAPACIDADE
  location = "East US 2"      # <-- MUDANDO PARA UMA REGIÃO MAIOR

  tags = {
    ambiente = "estudos"
    owner    = "gustavo"
    criado_com = "terraform"
  }
}
# --- Bloco 2: Rede Virtual (VNet) ---
# A rede principal onde nossos recursos vão morar.

resource "azurerm_virtual_network" "vnet_estudos" {
  name                = "vnet-principal-estudos"
  location            = azurerm_resource_group.rg_estudos.location
  resource_group_name = azurerm_resource_group.rg_estudos.name
  address_space       = ["10.10.0.0/16"] # O "bairro" inteiro (65.536 IPs)

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
  
  # APAGUE A LINHA "network_security_group_id = ..." DAQUI
}

# --- Bloco 4: Grupo de Segurança de Rede (NSG) ---
# Este é o nosso "Firewall" para a sub-rede.

resource "azurerm_network_security_group" "nsg_web" {
  name                = "nsg-servidores-web"
  location            = azurerm_resource_group.rg_estudos.location
  resource_group_name = azurerm_resource_group.rg_estudos.name

  # Aqui definimos as regras de entrada (inbound)
  security_rule {
    name                       = "AllowRDP"
    priority                   = 1001       # Ordem da regra (menor = mais importante)
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"        # Qualquer porta de origem
    destination_port_range     = "3389"     # A porta do RDP
    source_address_prefix      = "Internet" # De qualquer lugar da internet
    destination_address_prefix = "*"        # Para qualquer IP dentro da sub-rede
  }

  tags = {
    ambiente = "estudos"
    owner    = "gustavo"
  }
}

# --- Bloco 5: Associação do NSG com a Sub-rede ---
# Este é o "elo de ligação" que conecta o Bloco 3 (Subnet)
# com o Bloco 4 (NSG).

resource "azurerm_subnet_network_security_group_association" "assoc_nsg_subnet" {
  subnet_id                 = azurerm_subnet.subnet_web.id
  network_security_group_id = azurerm_network_security_group.nsg_web.id
}

# --- Bloco 6: IP Público (PIP) ---
# O endereço IP estático da nossa VM na internet.

resource "azurerm_public_ip" "pip_vm" {
  name                = "pip-vm-windows"
  location            = azurerm_resource_group.rg_estudos.location
  resource_group_name = azurerm_resource_group.rg_estudos.name
  allocation_method   = "Static" # Queremos que o IP não mude
  sku                 = "Standard"

  tags = {
    ambiente = "estudos"
    owner    = "gustavo"
  }
}

# --- Bloco 7: Placa de Rede (NIC) ---
# A placa de rede virtual que conecta tudo.

resource "azurerm_network_interface" "nic_vm" {
  name                = "nic-vm-windows"
  location            = azurerm_resource_group.rg_estudos.location
  resource_group_name = azurerm_resource_group.rg_estudos.name

  # A configuração de IP
  ip_configuration {
    name                          = "ipconfig-vm"
    # Conecta na nossa sub-rede (Bloco 3)
    subnet_id                     = azurerm_subnet.subnet_web.id
    private_ip_address_allocation = "Dynamic"
    # Conecta no nosso IP público (Bloco 6)
    public_ip_address_id          = azurerm_public_ip.pip_vm.id
  }
}

# --- Bloco 8: A Máquina Virtual (Windows) ---

resource "azurerm_windows_virtual_machine" "vm_windows" {
  name                = "vm-servidor-web-01"
  computer_name       = "vmweb01"  # <-- ESTA É A CORREÇÃO (um nome curto < 15)
  location            = azurerm_resource_group.rg_estudos.location
  resource_group_name = azurerm_resource_group.rg_estudos.name
  size                = "Standard_B1s" 
  # size                = "Standard_B2s" # ESTAVA SEM ESTOQUE
  # size                = "Standard_DS1_v2" # ESTAVA SEM ESTOQUE
  # =========================================================
  # !! ATENÇÃO AQUI !!
  # Defina seu usuário e senha. A senha do Azure exige:
  # 12+ caracteres, Maiúscula, minúscula, número e símbolo.
  #
  admin_username = "estudodevops"
  admin_password = "var.vm_admin_password" # <-- TROQUE ESTA SENHA!
  # =========================================================
  
  # Conecta na nossa placa de rede (Bloco 7)
  network_interface_ids = [
    azurerm_network_interface.nic_vm.id,
  ]

  # O disco do Sistema Operacional
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" # Disco HDD, mais barato para lab
  }

  # A Imagem do Windows (Marketplace)
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

# --- Bloco 9: Saída (Output) ---
# Isso fará o Terraform mostrar o IP público no final.

output "ip_publico_vm_windows" {
  value = azurerm_public_ip.pip_vm.ip_address
  description = "O IP publico para conectar via RDP."
}