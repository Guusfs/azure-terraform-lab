# ☁️ Azure Infrastructure Automation: Terraform + Docker

> **Projeto de Portfólio:** Pipeline de Infraestrutura como Código (IaC) simulando um cenário real de deploy automatizado.
>
> **Status:** Concluído ✅

---

## 🎯 Visão Geral
Este projeto marca minha transição técnica de **Suporte N2 para DevOps**. O objetivo foi construir um ciclo completo de provisionamento e deploy sem intervenção manual, aplicando conceitos de **Imutabilidade** e **Automação**.

O script provisiona uma infraestrutura completa no **Microsoft Azure** e realiza o bootstrap de uma aplicação conteinerizada.

### 🛠️ Tech Stack
* **Terraform (IaC):** Orquestração e gerenciamento de estado.
* **Microsoft Azure:** Provedor de Nuvem (Compute & Network).
* **Docker:** Containerização da aplicação.
* **Linux (Ubuntu):** Sistema Operacional base.
* **Bash/Cloud-Init:** Scripts de automação pós-provisionamento.

---

## ⚙️ Arquitetura e Fluxo de Execução

O código Terraform executa as seguintes etapas automaticamente:

1.  **Infraestrutura:** Criação de Resource Group, VNet, Subnet e IP Público dinâmico.
2.  **Segurança (Network Security Group):** Configuração de regras de firewall liberando apenas portas críticas:
    * `22` (SSH) - Para gerenciamento.
    * `80` (HTTP) - Para acesso à aplicação web.
3.  **Computação:** Provisionamento de VM Linux (Ubuntu).
4.  **Bootstrap (Custom Data):** Na primeira inicialização, um script injetado realiza:
    * Instalação do Docker Engine.
    * Pull da imagem `guusoares/meu-primeiro-app` do Docker Hub.
    * Execução do container expondo a aplicação na porta 80.

**Fluxo Simplificado:**
`[Terraform]` ➔ `[Azure API]` ➔ `[VM Linux]` ➔ `[Docker Install]` ➔ `[App Live 🚀]`

---

## 🔧 Desafios Reais & Troubleshooting (Lessons Learned)

Durante o desenvolvimento deste laboratório, enfrentei e solucionei problemas comuns do dia a dia de engenharia:

* ❌ **Erro: SkuNotAvailable (Capacidade de Região)**
    * **Cenário:** A região `Brazil South` estava sem capacidade para VMs da família B e D (falta de estoque físico no Azure).
    * **Solução:** Refatoração do código para parametrizar a região e migração completa dos recursos para `East US 2`.

* ❌ **Erro: SSH Key Format**
    * **Cenário:** O Azure rejeitou chaves geradas com algoritmo `ed25519` (mais moderno, porém não suportado em algumas imagens legacy).
    * **Solução:** Geração forçada de chaves no padrão `RSA 4096` bits.

* ❌ **Erro: PlatformImageNotFound**
    * **Cenário:** A versão específica `20.04-LTS` do Ubuntu não estava disponível no catálogo da nova região escolhida.
    * **Solução:** Pivoteamento para a versão `18.04-LTS` para garantir estabilidade e disponibilidade.

* ❌ **Erro: Terraform State Corruption**
    * **Cenário:** Após falhas de rede durante o `apply`, o arquivo `.tfstate` ficou inconsistente com a nuvem real.
    * **Solução:** Realizei a limpeza manual de recursos órfãos no Portal do Azure e reconstruí o estado do zero (State Reset) para garantir integridade.

---

## 🚀 Como Executar o Projeto

Pré-requisitos: Azure CLI e Terraform instalados.

```bash
# 1. Clone o repositório
git clone [https://github.com/Guusfs/azure-terraform-lab.git](https://github.com/Guusfs/azure-terraform-lab.git)
cd azure-terraform-lab

# 2. Gere um par de chaves SSH (Tipo RSA é obrigatório para Azure)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_azure

# 3. Configure a chave no Terraform
# Abra o arquivo main.tf e insira o conteúdo da sua chave pública (id_rsa_azure.pub)
# no campo "admin_ssh_key".

# 4. Autentique-se no Azure
az login

# 5. Inicialize e Aplique a Infraestrutura
terraform init
terraform apply --auto-approve
