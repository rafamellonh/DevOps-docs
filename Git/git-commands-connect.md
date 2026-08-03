# Git - Comandos Básicos

## 1. Clonar um repositório existente

Use quando o repositório já existe no GitHub e você quer baixá-lo para sua máquina.

```bash
# Ir para a pasta onde deseja salvar o projeto
cd /dados

# Clonar o repositório
git clone git@github.com:rafamellonh/DevOps-docs.git

# Entrar no projeto
cd DevOps-docs

# Abrir no VS Code
code .
```

---

## 2. Conectar um projeto local ao GitHub

Use quando você já possui os arquivos localmente e deseja enviá-los para um repositório existente no GitHub.

```bash
# Entrar na pasta do projeto
cd /dados/DevOps-docs

# Inicializar o Git (caso necessário)
git init

# Adicionar o repositório remoto
git remote add origin git@github.com:rafamellonh/DevOps-docs.git

# Verificar o remote
git remote -v

# Adicionar todos os arquivos
git add .

# Criar o primeiro commit
git commit -m "Primeiro commit"

# Definir a branch principal
git branch -M main

# Enviar para o GitHub
git push -u origin main
```

---

## 3. Alterar a URL do repositório remoto

Caso o `origin` já exista:

```bash
git remote set-url origin git@github.com:rafamellonh/DevOps-docs.git
```

Ou remover e adicionar novamente:

```bash
git remote remove origin
git remote add origin git@github.com:rafamellonh/DevOps-docs.git
```

---

# Fluxo diário de trabalho

## Baixar alterações do GitHub

```bash
git pull
```

## Verificar alterações locais

```bash
git status
```

## Adicionar alterações

Adicionar todos os arquivos:

```bash
git add .
```

Adicionar apenas um arquivo:

```bash
git add arquivo.md
```

## Criar um commit

```bash
git commit -m "Descrição da alteração"
```

## Enviar alterações para o GitHub

```bash
git push
```

---

# Consultas úteis

## Ver o histórico de commits

```bash
git log --oneline
```

## Ver diferenças antes do commit

```bash
git diff
```

## Ver o repositório remoto

```bash
git remote -v
```

## Ver a branch atual

```bash
git branch
```

## Trocar de branch

```bash
git checkout nome-da-branch
```

## Criar uma nova branch

```bash
git checkout -b nova-branch
```

---

# Fluxo recomendado

```bash
git pull
git status
git add .
git commit -m "Descrição da alteração"
git push
```