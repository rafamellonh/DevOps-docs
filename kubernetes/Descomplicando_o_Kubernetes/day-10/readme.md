# cert-manager — Certificados TLS no Kubernetes (Day 10)

> **Ambiente:** cluster kubeadm 1.29 (1 master + 2 workers) com ingress-nginx em NodePort
> **cert-manager:** v1.18.x (última linha compatível com Kubernetes 1.29)
> **Porta HTTPS do ingress-nginx:** 31305 (`k get svc -n ingress-nginx ingress-nginx-controller`)

---

## 1. O que é o cert-manager

Um **despachante de certificados TLS** dentro do cluster. Você declara que quer HTTPS para um domínio e ele:

1. **Emite** o certificado com o emissor escolhido
2. **Guarda** o certificado num Secret do tipo `kubernetes.io/tls`
3. **Renova** sozinho antes de vencer

| Sem cert-manager (Day 8) | Com cert-manager (Day 10) |
|---|---|
| Gera o certificado com `openssl` | Declara o que quer no Ingress |
| Cria o Secret TLS à mão | O Secret é criado automaticamente |
| Renova manualmente antes de vencer | Renova sozinho (padrão: com 1/3 da validade restante) |

---

## 2. As 3 peças que importam

```
1. ClusterIssuer / Issuer  →  QUEM emite (Let's Encrypt, autoassinado, CA própria...)
2. Ingress (annotation+tls) →  O QUE você quer (HTTPS para tal domínio, com tal emissor)
3. Secret TLS               →  O RESULTADO (certificado pronto, usado pelo ingress-nginx)
```

Você escreve **1** e **2**. A peça **3** o cert-manager cria.

### Objetos intermediários (criados automaticamente)

Você **não cria** estes recursos. Só os consulta quando algo trava:

| Recurso | Função |
|---|---|
| `Certificate` | Representa o certificado desejado; gerado a partir da annotation do Ingress |
| `CertificateRequest` | O pedido de emissão enviado ao Issuer |
| `Order` | Pedido ao servidor ACME (só Let's Encrypt) |
| `Challenge` | Prova de posse do domínio (só Let's Encrypt) |
| Ingress `cm-acme-http-solver-xxxxx` | Ingress temporário do desafio HTTP-01 (só Let's Encrypt) |
| Secret `<nome>-xxxxx` (Opaque) | Chave privada temporária durante a emissão; não é o certificado final |

---

## 3. Issuer × ClusterIssuer

| | `Issuer` | `ClusterIssuer` |
|---|---|---|
| Escopo | Só o **namespace** onde foi criado | O **cluster inteiro** |
| Uso típico | Cada equipe/namespace com seu emissor | Um emissor compartilhado |
| Annotation no Ingress | `cert-manager.io/issuer: <nome>` | `cert-manager.io/cluster-issuer: <nome>` |

> Mesma lógica de `Role` × `ClusterRole`.

### Tipos de emissor

| Tipo | Uso | Navegador confia? |
|---|---|---|
| `selfSigned` | Lab, testes, cluster sem internet | ❌ Não (mostra aviso) |
| `ca` | PKI interna da empresa (CA própria instalada nas máquinas) | ✅ Se a CA estiver instalada |
| `acme` (Let's Encrypt) | Sites públicos na internet | ✅ Sim |
| `vault`, `venafi` | Integração com cofres/PKI corporativos | Depende |

---

## 4. Let's Encrypt: staging × prod

| | Staging | Prod |
|---|---|---|
| `server` | `https://acme-staging-v02.api.letsencrypt.org/directory` | `https://acme-v02.api.letsencrypt.org/directory` |
| Certificado | **Não confiável** | Válido e confiável |
| Limite de pedidos | Alto | Baixo e rígido (erros repetidos bloqueiam temporariamente) |
| Quando usar | Testar a configuração | Depois que o staging funcionou |

**Fluxo recomendado:** testar no staging → funcionou → trocar para prod.

### Campos do Issuer ACME

| Campo | Função |
|---|---|
| `email` | Contato para avisos de expiração e problemas |
| `privateKeySecretRef` | Secret onde fica a **chave da conta ACME** (não é o certificado do site) |
| `solvers.http01.ingress.ingressClassName` | Como provar a posse do domínio: o cert-manager cria um Ingress temporário com essa classe |

### Por que o Let's Encrypt não funciona no lab

O desafio **HTTP-01** exige que o servidor do Let's Encrypt, **na internet**, acesse:

```
http://<seu-dominio>/.well-known/acme-challenge/<token>
```

na **porta 80**. Isso requer:

- Um **domínio público seu**, com DNS apontando para o seu IP
- O cluster **acessível pela internet** na porta 80

No lab, o domínio existe só no arquivo hosts e o ingress está na NodePort 31305 dentro da rede de casa. O resultado é um certificado preso em `READY False`, com o motivo visível em `k describe challenge`.

**Na nuvem (AKS/EKS)** com domínio próprio e LoadBalancer público, funciona normalmente.

---

## 5. Instalação

### 5.1 Compatibilidade de versões

Antes de instalar, confira a versão do cluster e a tabela oficial:
https://cert-manager.io/docs/releases/

```bash
k version
```

| cert-manager | Kubernetes suportado |
|---|---|
| 1.21 | 1.33 → 1.36 |
| 1.20 | 1.32 → 1.35 |
| 1.19 | 1.31 → 1.35 |
| **1.18** | **1.29 → 1.33** |
| 1.17 | 1.29 → 1.33 |

> ⚠️ **Sintoma de versão incompatível:** `strict decoding error: unknown field "spec.versions[0].selectableFields"` ao criar os CRDs. A instalação fica pela metade.

### 5.2 Remover uma instalação parcial (se necessário)

```bash
k delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.21.2/cert-manager.yaml
```

### 5.3 Descobrir o último patch da versão compatível

```bash
curl -s https://api.github.com/repos/cert-manager/cert-manager/releases?per_page=100 | grep -o '"tag_name": "v1\.18\.[0-9]*"' | head -1
```

### 5.4 Instalar

```bash
k apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.X/cert-manager.yaml
k get pods -n cert-manager -w
```

Pods esperados (todos `1/1 Running`):

| Pod | Função |
|---|---|
| `cert-manager` | Controller principal: emite e renova |
| `cert-manager-cainjector` | Injeta CAs em webhooks e CRDs |
| `cert-manager-webhook` | Valida os recursos do cert-manager no `apply` |

### 5.5 Verificar os CRDs

```bash
k get crd | grep cert-manager
```

Devem aparecer 6:

```
certificaterequests.cert-manager.io
certificates.cert-manager.io
challenges.acme.cert-manager.io
clusterissuers.cert-manager.io
issuers.cert-manager.io
orders.acme.cert-manager.io
```

---

## 6. Lab: HTTPS com emissor autoassinado

### 6.1 ClusterIssuer

`selfsigned-issuer.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned
spec:
  selfSigned: {}
```

```bash
k apply -f selfsigned-issuer.yaml
k get clusterissuer
# READY deve ser True
```

### 6.2 Ingress com TLS

`ingress-selfsigned.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: giropops-tls
  annotations:
    cert-manager.io/cluster-issuer: "selfsigned"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - giropops.nginx.io
    secretName: giropops-nginx-io
  rules:
  - host: giropops.nginx.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: giropops-senhas
            port:
              number: 5000
```

**Regras importantes:**

- O host em `tls.hosts` deve ser **o mesmo** do `rules[].host`
- `secretName` é o nome do Secret que o cert-manager vai **criar**; não crie antes
- Com `path: /`, não use `rewrite-target`

```bash
k apply -f ingress-selfsigned.yaml
```

### 6.3 Verificar a emissão

```bash
k get certificate
# READY True

k get secret giropops-nginx-io
# TYPE kubernetes.io/tls, DATA 3 (ca.crt, tls.crt, tls.key)
```

### 6.4 Testar

No arquivo hosts do PC: `192.168.2.181   giropops.nginx.io`

```bash
curl -k https://giropops.nginx.io:31305/
```

Confirmar que o certificado servido é o do cert-manager (e não o `Kubernetes Ingress Controller Fake Certificate`):

```bash
curl -kv https://giropops.nginx.io:31305/ 2>&1 | grep -E 'subject|issuer'
```

No navegador: `https://giropops.nginx.io:31305/` → aviso `NET::ERR_CERT_AUTHORITY_INVALID` (esperado) → **Advanced → Proceed**.

### 6.5 Inspecionar o certificado

```bash
k get secret giropops-nginx-io -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -subject -issuer -ext subjectAltName -dates
```

Saída esperada:

```
subject=
issuer=
X509v3 Subject Alternative Name: critical
    DNS:giropops.nginx.io
notBefore=...
notAfter=...   (90 dias depois)
```

| Campo | Explicação |
|---|---|
| `subject=` vazio | Certificado gerado por annotation não preenche o Common Name |
| `issuer=` vazio | Em autoassinado, issuer = subject |
| SAN `critical` | O navegador valida pelo SAN; fica `critical` porque o subject está vazio (RFC 5280) |
| Validade de 90 dias | Padrão do cert-manager |

---

## 7. Exemplos de Issuers Let's Encrypt (para uso em nuvem)

### Issuer staging (namespace)

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: seu@email.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
```

### ClusterIssuer prod (cluster)

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: seu@email.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
```

### Ingress para nuvem (domínio próprio)

```yaml
# Para uso em cluster exposto à internet (AKS/EKS) com domínio próprio.
# O desafio HTTP-01 do Let's Encrypt precisa alcançar o domínio na porta 80.
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-tls
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.meudominio.com
    secretName: app-meudominio-com
  rules:
  - host: app.meudominio.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: meu-app
            port:
              number: 80
```

---

## 8. Certificate explícito (opcional)

Em vez da annotation no Ingress, dá para criar o `Certificate` diretamente, com mais controle (Common Name, validade, antecedência da renovação):

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: giropops-cert
spec:
  secretName: giropops-nginx-io
  commonName: giropops.nginx.io
  dnsNames:
  - giropops.nginx.io
  duration: 2160h      # 90 dias
  renewBefore: 720h    # renova 30 dias antes
  issuerRef:
    name: selfsigned
    kind: ClusterIssuer
```

Nesse caso, o Ingress mantém o bloco `tls` com o mesmo `secretName`, mas **sem** a annotation `cert-manager.io/cluster-issuer`.

---

## 9. Renovação

- Padrão: o cert-manager renova quando resta **1/3 da validade** (com 90 dias, renova por volta do 60º dia)
- Ver quando está agendada:

```bash
k describe certificate giropops-nginx-io | grep -iE 'renewal|not after'
```

---

## 10. Troubleshooting

Siga a cadeia de cima para baixo:

```bash
k get clusterissuer          # READY True?
k get certificate            # READY True?
k describe certificate <nome>
k get certificaterequest
k get order                  # só ACME
k get challenge              # só ACME
k describe challenge <nome>  # o motivo da falha aparece aqui
k logs -n cert-manager deploy/cert-manager
```

| Sintoma | Causa provável | Ação |
|---|---|---|
| CRDs falham com `unknown field "selectableFields"` | cert-manager novo demais para o cluster | Instalar versão compatível (ver seção 5.1) |
| Certificate `READY False` com Let's Encrypt | Domínio não público ou porta 80 inacessível da internet | `k describe challenge`; no lab, usar `selfsigned` |
| Ingress `cm-acme-http-solver-*` não some | Desafio ACME pendente | Resolver o challenge ou apagar o Certificate |
| Navegador mostra `Kubernetes Ingress Controller Fake Certificate` | Secret TLS não existe ou o host não bate | Conferir `k get secret`, `tls.hosts` e `rules[].host` |
| ClusterIssuer `READY False` | Erro de configuração (servidor, e-mail, Secret) | `k describe clusterissuer <nome>` |
| Aviso de certificado no navegador com `selfsigned` | Comportamento esperado | Aceitar, ou usar um Issuer `ca` com CA instalada no PC |

### Limpar um pedido travado

```bash
k delete ingress <nome>
k delete certificate <nome>
k delete secret <nome>-xxxxx   # chave temporária, se ficou para trás
```

---

## 11. Referência rápida

```bash
# Porta HTTPS do ingress-nginx
k get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}'

# Emissores
k get issuer -A
k get clusterissuer

# Certificados
k get certificate -A
k describe certificate <nome>

# Conteúdo do certificado
k get secret <secret> -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -text
```

---

> **Próximo passo sugerido:** criar uma CA própria com um Issuer do tipo `ca`, instalar o certificado da CA como confiável no PC e eliminar o aviso do navegador em todos os certificados do lab.
