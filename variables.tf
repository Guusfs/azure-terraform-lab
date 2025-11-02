variable "vm_admin_password" {
  description = "Senha do administrador da VM Windows"
  type        = string
  sensitive   = true # Isso diz ao Terraform para não mostrar a senha no log
}