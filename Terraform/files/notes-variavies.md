# Variáveis no Terraform: `default` vs `terraform.tfvars`

## Por que combinar os dois?

O sentido de combinar os dois aparece quando você tem **várias variáveis**.

### Exemplo

`variables.tf`:

```hcl
variable "instance_type" {
  type    = string
  default = "t2.micro"      # tem default
}

variable "ambiente" {
  type = string              # NÃO tem default → obrigatória
}
```

`terraform.tfvars`:

```hcl
ambiente = "producao"
# instance_type não está aqui
```

### Comportamento

- **`ambiente`** → pega `"producao"` do tfvars (era obrigatória).
- **`instance_type`** → como não está no tfvars, cai no default `"t2.micro"`.

Ou seja: você usa o `default` para as variáveis que têm um valor "padrão bom" e deixa **sem default** (obrigatórias) só as que precisam ser preenchidas a cada uso. O tfvars então preenche o que for necessário e sobrescreve o que quiser.

## Resumindo a lógica

| Situação | O que o Terraform usa |
|----------|----------------------|
| Só `default` | usa o default |
| Só `tfvars` | usa o tfvars |
| Os dois | usa o **tfvars** (default vira fallback) |
| Nenhum dos dois | pergunta interativamente |