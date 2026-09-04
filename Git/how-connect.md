# Comandos Git — conectar e enviar código ao GitLab.com

> Referência rápida dos comandos usados no lab, com o **porquê** de cada um.
> A ideia é entender, não só copiar.

---

## 1. Conceito antes dos comandos: como o Git autentica

Ponto que confunde todo mundo: **não existe "login" no Git.** Você não faz um
login como num site. A autenticação acontece **na hora do push/clone**, e a
"senha" nunca é a senha da conta — é um **Personal Access Token**.

Três coisas diferentes que parecem a mesma:

| Item | O que é | Serve pra |
|------|---------|-----------|
| `user.name` / `user.email` | Identidade do autor | Assinar os commits (NÃO é login) |
| Personal Access Token (`glpat-`) | Credencial de acesso | Autenticar no push/clone (a "senha") |
| `git remote` | Endereço do repositório na nuvem | Dizer pra onde empurrar |

---

## 2. Configurar a identidade (uma vez só)

```bash
git config --global user.name "Rafael"
git config --global user.email "seu@email-do-gitlab.com"
```

**Por quê:** define quem aparece como autor dos commits. Use o mesmo email da
conta do GitLab.com pra os commits ficarem vinculados a você. Isso NÃO autentica
nada — só "assina" os commits. O `--global` aplica pra todos os repositórios da
máquina.

---

## 3. Criar o token no GitLab.com (a autenticação real)

No GitLab.com (interface web):

1. Avatar (canto superior direito) → **Edit profile**
2. Menu lateral → **Access Tokens**
3. **Add new token**
4. Nome: qualquer um (ex: `terminal`)
5. Escopo: marca `write_repository` e `read_repository`
6. **Create personal access token**
7. **Copia o `glpat-...`** — só aparece uma vez, então copia antes de sair

**Por quê:** o GitLab.com não aceita a senha da conta pra operações Git. Só
token. É mais seguro — se vazar, você revoga só o token, sem mexer na conta.

---

## 4. Iniciar um repositório e conectar ao remoto

### Se está começando um repo do zero (git init)

```bash
git init                                  # cria o repositório local
git add .                                 # prepara todos os arquivos
git commit -m "primeiro commit"           # registra o commit
git branch -M main                        # renomeia a branch para main
git remote add origin https://gitlab.com/SEU-USUARIO/SEU-PROJETO.git
git push -u origin main                   # envia (pede autenticação aqui)
```

### Se o projeto já existe na nuvem (mais limpo)

```bash
git clone https://gitlab.com/SEU-USUARIO/SEU-PROJETO.git
cd SEU-PROJETO
```

**O que cada um faz:**

- `git init` — cria um repositório Git vazio na pasta atual.
- `git add .` — marca todos os arquivos pra entrarem no próximo commit ("staging").
- `git commit -m "..."` — registra uma versão com uma mensagem descritiva.
- `git branch -M main` — garante que a branch principal se chama `main`.
- `git remote add origin URL` — conecta o repo local ao projeto na nuvem.
  `origin` é o apelido padrão do remoto principal.
- `git push -u origin main` — envia os commits pra nuvem. O `-u` memoriza a
  ligação, então nos próximos pushes basta `git push`.
- `git clone URL` — baixa um projeto que já existe, já conectado ao remoto.

---

## 5. Autenticar no push

Quando o terminal pedir credenciais:

- **Username:** teu usuário do GitLab.com (o nome de usuário, não o email)
- **Password:** cola o **token** `glpat-...` (NÃO a senha da conta)

**Detalhes que pegam:**

- Ao colar a senha/token, **nada aparece na tela** (nem asteriscos). É segurança
  do terminal. Cola e dá Enter "às cegas".
- Pra colar no Git Bash (Windows): botão direito, ou `Shift+Insert`.
- Pra colar no Linux: `Ctrl+Shift+V`.

### Alternativa: token na própria URL (evita o prompt)

```bash
git remote set-url origin https://SEU-USUARIO:glpat-SEU-TOKEN@gitlab.com/SEU-USUARIO/SEU-PROJETO.git
git push -u origin main
```

Formato: `https://usuario:token@gitlab.com/...` — a credencial já vai embutida,
então não pede nada. (Cuidado: o token fica salvo na config do repo; ok pra lab,
evite em repos compartilhados.)

---

## 6. Não digitar o token toda vez

```bash
git config --global credential.helper store
```

**Por quê:** depois do primeiro push (onde você digita o token), o Git salva a
credencial e para de pedir. No Windows/Git Bash, o Credential Manager já faz isso
sozinho.

---

## 7. O ciclo do dia a dia (depois de tudo configurado)

Uma vez conectado, o trabalho normal é só isto, repetido:

```bash
git add .                          # prepara as mudanças
git commit -m "descreve o que mudou"
git push                           # envia (sem -u, a ligação já existe)
```

**O fluxo mental:**

```
edita arquivos → git add (prepara) → git commit (registra) → git push (envia)
```

No caso do lab, o `git push` também **dispara o pipeline** no GitLab.com, que
manda o runner aplicar os manifestos no cluster.

---

## 8. Comandos úteis de verificação

```bash
git status              # o que mudou, o que está preparado
git remote -v           # pra qual URL o repo aponta
git log --oneline       # histórico de commits, resumido
git branch              # em qual branch você está
git config --list       # todas as configs ativas
```

---

## Resumo de uma página

1. **Identidade** (uma vez): `git config --global user.name/user.email`
2. **Token**: cria no GitLab.com → Access Tokens (escopo `write_repository`)
3. **Conectar**: `git remote add origin URL` (ou `git clone URL`)
4. **Enviar**: `git push -u origin main` → user + **token** como senha
5. **Salvar credencial**: `git config --global credential.helper store`
6. **Dia a dia**: `git add .` → `git commit -m "..."` → `git push`

**Lembra sempre:**
- A "senha" no push é o **token**, nunca a senha da conta.
- Ao colar o token, a tela não mostra nada — é normal.
- `git push` no lab dispara o pipeline que deploya no cluster.
