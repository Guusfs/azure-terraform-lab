Projeto DevOps: Pipeline IaC (Terraform) + App Dockerizado no Azure
Este é um projeto de estudo completo da minha transição de carreira de Suporte de TI para Cloud/DevOps. O objetivo é demonstrar um ciclo "IaC" (Infra as Code) e "Deploy" básico.

O pipeline: O Terraform provisiona uma VM Linux no Azure que, ao iniciar, instala o Docker e executa uma aplicação Python que eu mesmo "conteinerizei" e publiquei no Docker Hub.

O que este código faz?
Este script Terraform provisiona uma infraestrutura de nuvem completa e funcional no Azure.

Fluxo de Execução:

Infra (Terraform): O Terraform cria uma VNet, uma Sub-rede, um IP Público e uma VM Linux (Ubuntu).

Segurança (Terraform): Um NSG é criado e associado à sub-rede, liberando as portas 22 (SSH) e 80 (HTTP).

Provisionamento (Terraform custom_data): Na primeira inicialização da VM, um script custom_data é executado para:

Instalar o Docker (docker.io).

Iniciar o serviço do Docker.

Executar o comando docker run -d -p 80:8000 guusoares/meu-primeiro-app.

Resultado: Em ~5 minutos, o IP público da VM está servindo meu site "Olá, Gustavo!", que está rodando de dentro de um contêiner Docker.

Diagrama de Arquitetura Simples: [Seu PC (Terraform)] -> [Azure API] -> [VM Linux] -> [Script custom_data] -> [docker run guusoares/meu-primeiro-app] -> [Site no Ar (Porta 80)]

Desafios de Troubleshooting Enfrentados
Durante este laboratório, enfrentei vários problemas do mundo real que exigiram troubleshooting:

SkuNotAvailable (Falta de Estoque): A região Brazil South estava sem capacidade para 3 tipos diferentes de VM (B1s, DS1_v2, B2s). A solução foi refatorar o código para migrar toda a infraestrutura para a região East US 2.

Chave SSH não suportada: O Azure não aceitou a chave padrão ed25519 gerada pelo meu ssh-keygen. A solução foi forçar a geração de uma chave RSA (ssh-keygen -t rsa -b 4096), que é o padrão suportado.

PlatformImageNotFound (Imagem não encontrada): O Azure não encontrou o sku "20.04-LTS" do Ubuntu na região East US 2. A solução foi alterar o sku para a versão 18.04-LTS, que é mais comum.

Provider Inconsistent Result (Estado Corrompido): Após múltiplas falhas de apply, o arquivo de estado (.tfstate) ficou corrompido. A solução foi um "hard reset": destruir manualmente os recursos órfãos no portal do Azure e deletar o arquivo de estado local para rodar um apply limpo.

Como Usar
Este projeto usa chaves SSH para autenticação (o padrão da indústria), e não senhas.

PowerShell

# 1. Clone o repositório
git clone https://github.com/Guusfs/azure-terraform-lab.git
cd azure-terraform-lab

# 2. Gere um par de chaves SSH (se você ainda não tiver)
# O Azure exige o tipo RSA.
ssh-keygen -t rsa -b 4096

# 3. Copie sua chave PÚBLICA
# Abra o arquivo C:\Users\SEU_USUARIO\.ssh\id_rsa.pub com o Bloco de Notas
# e copie o conteúdo (a linha longa "ssh-rsa AAAA...")

# 4. Cole a chave pública no main.tf
# Abra o main.tf e cole sua chave no bloco "admin_ssh_key".

# 5. Autentique-se no Azure
az login

# 6. Inicialize e Aplique o Terraform
./terraform init
./terraform apply
