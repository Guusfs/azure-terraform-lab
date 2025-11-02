# Projeto de Estudo: Infraestrutura Azure com Terraform

Este é um projeto do meu estudo de transição de carreira de Suporte de TI para Cloud/DevOps, focado na certificação AZ-104.

## 🚀 O que este código faz?

Este script Terraform provisiona uma infraestrutura completa de rede e computação no Azure. É um "template" básico para qualquer implantação de VM.

**Recursos Criados:**
* `azurerm_resource_group`
* `azurerm_virtual_network` (VNet)
* `azurerm_subnet`
* `azurerm_network_security_group` (NSG com regra para liberar a porta 3389/RDP)
* `azurerm_subnet_network_security_group_association`
* `azurerm_public_ip` (IP Público Estático)
* `azurerm_network_interface` (NIC)
* `azurerm_windows_virtual_machine` (Windows Server 2019)

## 🛠️ Desafios de Troubleshooting Enfrentados

Durante este laboratório, enfrentei vários problemas do mundo real que exigiram troubleshooting:

1.  **`SkuNotAvailable`:** A região `Brazil South` estava sem capacidade para 3 tipos diferentes de VM (B1s, DS1_v2, B2s). A solução foi refatorar o código para tornar a `location` uma variável implícita (herdada do RG) e migrar toda a infraestrutura para a região `East US 2`.

2.  **`Provider Inconsistent Result`:** Após múltiplas falhas de `apply`, o arquivo de estado (`.tfstate`) ficou corrompido. A solução foi um "hard reset": destruir manualmente os recursos órfãos no portal do Azure e deletar o estado local para rodar um `apply` limpo.

3.  **`ComputerNameTooLong`:** O nome do recurso da VM do Azure era longo demais para o `computer_name` do NetBIOS (limite de 15 caracteres). A solução foi adicionar o argumento `computer_name` explícito.

## 🔑 Como Usar

O código usa uma variável sensível para a senha do administrador. Para rodar:

```powershell
# 1. Autenticar no Azure
az login

# 2. Inicializar o Terraform
terraform init

# 3. Aplicar (O Terraform vai perguntar a senha)
terraform apply
