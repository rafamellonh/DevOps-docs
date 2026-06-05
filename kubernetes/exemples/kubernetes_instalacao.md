# Instalação do Kubernetes — 1 Master + 2 Workers (Ubuntu)

> **Ambiente:** Ubuntu 22.04 LTS  
> **Versão:** Kubernetes 1.29  
> **Arquitetura:** 1 Control Plane (Master) + 2 Worker Nodes

---

## Visão Geral da Arquitetura

```
┌─────────────────────┐
│   MASTER NODE       │  → Gerencia o cluster, agenda pods, controla o estado
│   k8s-master        │    Componentes: kube-apiserver, etcd, scheduler,
│   192.168.1.10      │    controller-manager
└─────────────────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌─────────┐ ┌─────────┐
│ WORKER 1│ │ WORKER 2│  → Executam os containers/pods das aplicações
│k8s-node1│ │k8s-node2│    Componentes: kubelet, kube-proxy, container runtime
│192.168.1│ │192.168.1│
│   .11   │ │   .12   │
└─────────┘ └─────────┘
```

### Legenda — onde executar cada comando

| Ícone | Onde executar |
|---|---|
| 🖥️ `[MASTER + WORKERS]` | Todas as máquinas |
| 👑 `[MASTER]` | Somente no k8s-master |
| ⚙️ `[WORKERS]` | Somente nos k8s-node1 e k8s-node2 |

---

## Pré-requisitos

| Máquina | RAM | CPU | Disco | IP (exemplo) |
|---|---|---|---|---|
| k8s-master | 2 GB+ | 2+ vCPUs | 20 GB+ | 192.168.1.10 |
| k8s-node1 | 2 GB+ | 2+ vCPUs | 20 GB+ | 192.168.1.11 |
| k8s-node2 | 2 GB+ | 2+ vCPUs | 20 GB+ | 192.168.1.12 |

> ⚠️ Substitua os IPs pelos IPs reais das suas máquinas.

---

## PARTE 1 — Configuração Inicial (TODAS as máquinas)

> 🖥️ `[MASTER + WORKERS]` — Execute os passos abaixo no **Master e nos 2 Workers**.

### 1.1 — Atualizar o sistema

> 🖥️ `[MASTER + WORKERS]`

```bash
sudo apt update && sudo apt upgrade -y
```

Garante que o sistema está com os pacotes mais recentes antes de instalar qualquer coisa.

---

### 1.2 — Configurar o arquivo /etc/hosts

> 🖥️ `[MASTER + WORKERS]`

Adiciona os nomes das máquinas para que elas se comuniquem pelo hostname, não só pelo IP.

```bash
sudo nano /etc/hosts
```

Adicione as linhas abaixo (ajuste para os seus IPs reais):

```
192.168.1.10   k8s-master
192.168.1.11   k8s-node1
192.168.1.12   k8s-node2
```

---

### 1.3 — Desativar o Swap

> 🖥️ `[MASTER + WORKERS]`

O Kubernetes exige que o Swap esteja desativado. Com swap ativo, o kubelet se recusa a iniciar.

**Passo 1 — Desativar imediatamente (sem reiniciar):**

```bash
sudo swapoff -a
```

**Passo 2 — Desativar permanentemente comentando a entrada no fstab:**

Abra o arquivo `/etc/fstab` com um editor:

```bash
sudo nano /etc/fstab
```

Localize a linha que contém a palavra `swap`. Ela costuma se parecer com uma destas:

```
/swap.img   none   swap   sw   0   0
UUID=xxxx   none   swap   sw   0   0
/dev/sda2   none   swap   sw   0   0
```

Adicione um `#` no início da linha para comentá-la:

```
# /swap.img   none   swap   sw   0   0
```

Salve o arquivo (`Ctrl+O`, `Enter`, `Ctrl+X` no nano).

**Passo 3 — Verificar se o swap está desativado:**

```bash
free -h
# A linha "Swap" deve mostrar: 0B  0B  0B
```

> ℹ️ A alteração no `/etc/fstab` garante que o swap não seja reativado após reinicialização.

---

### 1.4 — Carregar módulos do kernel necessários

> 🖥️ `[MASTER + WORKERS]`

O Kubernetes precisa dos módulos `overlay` e `br_netfilter` para o networking de containers funcionar corretamente.

```bash
# Cria o arquivo de configuração dos módulos
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Carrega os módulos agora (sem precisar reiniciar)
sudo modprobe overlay
sudo modprobe br_netfilter
```

---

### 1.5 — Configurar parâmetros de rede do kernel (sysctl)

> 🖥️ `[MASTER + WORKERS]`

Permite que o iptables veja o tráfego de rede entre pods e que o IPv4 forwarding esteja ativo.

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Aplica as configurações imediatamente
sudo sysctl --system
```

---

### 1.6 — Instalar o Container Runtime (containerd)

> 🖥️ `[MASTER + WORKERS]`

O containerd é o runtime de containers usado pelo Kubernetes para executar os pods.

```bash
# Instala o containerd
sudo apt install -y containerd

# Cria o diretório de configuração
sudo mkdir -p /etc/containerd

# Gera o arquivo de configuração padrão
containerd config default | sudo tee /etc/containerd/config.toml
```

Agora edite o arquivo para ativar o **SystemdCgroup** — essencial para o Kubernetes gerenciar os cgroups corretamente:

```bash
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
```

Reinicie e habilite o containerd:

```bash
sudo systemctl restart containerd
sudo systemctl enable containerd

# Verifique se está rodando
sudo systemctl status containerd
```

---

### 1.7 — Instalar kubeadm, kubelet e kubectl

> 🖥️ `[MASTER + WORKERS]`

Esses são os 3 componentes principais:
- **kubeadm** → ferramenta para inicializar e gerenciar o cluster
- **kubelet** → agente que roda em cada node e gerencia os pods
- **kubectl** → CLI para interagir com o cluster

```bash
# Instala dependências
sudo apt install -y apt-transport-https ca-certificates curl gpg

# Adiciona a chave GPG do repositório do Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Adiciona o repositório oficial
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

# Atualiza e instala
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Marca os pacotes para não serem atualizados automaticamente
# (atualizações do Kubernetes devem ser feitas de forma controlada)
sudo apt-mark hold kubelet kubeadm kubectl

# Habilita e inicia o kubelet
sudo systemctl enable --now kubelet
```

---

## PARTE 2 — Inicializar o Cluster (SOMENTE no Master)

> 👑 `[MASTER]` — Execute apenas na máquina **k8s-master**.

### 2.1 — Inicializar o Control Plane

> 👑 `[MASTER]`

```bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.1.10
```

**Explicação dos parâmetros:**
- `--pod-network-cidr=10.244.0.0/16` → range de IPs para os pods (usado pelo Flannel)
- `--apiserver-advertise-address` → IP do master que os workers usarão para se conectar

> ⏳ Aguarde alguns minutos. No final você verá uma mensagem de sucesso com um comando `kubeadm join`.

**Guarde o comando `kubeadm join`** — você precisará dele no Passo 3.1. Ele se parece com:

```
kubeadm join 192.168.1.10:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:xxxxxxxx...
```

---

### 2.2 — Configurar o kubectl para o usuário atual

> 👑 `[MASTER]`

Sem essa configuração, o kubectl não sabe como se conectar ao cluster.

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Teste se funcionou:

```bash
kubectl get nodes
# O master deve aparecer com status "NotReady" (ainda sem rede de pods)
```

---

### 2.3 — Instalar o Plugin de Rede (Flannel)

> 👑 `[MASTER]`

Sem um plugin de rede, os pods não conseguem se comunicar entre si. O Flannel é simples e amplamente usado.

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

Aguarde ~1 minuto e verifique:

```bash
kubectl get nodes
# O master agora deve mostrar "Ready"

kubectl get pods -n kube-flannel
# Os pods do flannel devem estar "Running"
```

---

## PARTE 3 — Adicionar os Workers ao Cluster (SOMENTE nos Workers)

> ⚙️ `[WORKERS]` — Execute em **k8s-node1** e **k8s-node2**.

### 3.1 — Executar o comando kubeadm join

> ⚙️ `[WORKERS]`

Cole o comando `kubeadm join` que foi gerado no Passo 2.1:

```bash
sudo kubeadm join 192.168.1.10:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:xxxxxxxx...
```

> ⚠️ Se o token expirou (validade de 24h), gere um novo no master com:
> ```bash
> # 👑 [MASTER]
> kubeadm token create --print-join-command
> ```

---

## PARTE 4 — Verificação Final (no Master)

> 👑 `[MASTER]` — Execute apenas na máquina **k8s-master**.

### 4.1 — Verificar os nodes

> 👑 `[MASTER]`

```bash
kubectl get nodes -o wide
```

Saída esperada:

```
NAME         STATUS   ROLES           AGE   VERSION   INTERNAL-IP
k8s-master   Ready    control-plane   10m   v1.29.x   192.168.1.10
k8s-node1    Ready    <none>          5m    v1.29.x   192.168.1.11
k8s-node2    Ready    <none>          5m    v1.29.x   192.168.1.12
```

---

### 4.2 — Verificar os pods do sistema

> 👑 `[MASTER]`

```bash
kubectl get pods -n kube-system
```

Todos os pods devem estar com status **Running** ou **Completed**.

---

### 4.3 — Teste rápido: deploy de um pod nginx

> 👑 `[MASTER]`

```bash
# Cria um deployment de teste
kubectl create deployment nginx-test --image=nginx --replicas=2

# Verifica onde os pods foram agendados
kubectl get pods -o wide

# Remove o deployment de teste
kubectl delete deployment nginx-test
```

Os pods devem ter sido criados nos workers (k8s-node1 ou k8s-node2), não no master.

---

## Referência Rápida de Comandos

```bash
# 👑 [MASTER] — Ver todos os nodes
kubectl get nodes

# 👑 [MASTER] — Ver pods em todos os namespaces
kubectl get pods -A

# 👑 [MASTER] — Ver detalhes de um node
kubectl describe node k8s-node1

# 🖥️ [MASTER + WORKERS] — Ver logs do kubelet (útil para troubleshooting)
sudo journalctl -u kubelet -f

# 👑 [MASTER] — Remover um worker do cluster
kubectl drain k8s-node1 --ignore-daemonsets --delete-emptydir-data
kubectl delete node k8s-node1

# ⚙️ [WORKERS] — Resetar um node
sudo kubeadm reset
```

---

## Troubleshooting Comum

| Problema | Causa | Solução |
|---|---|---|
| Node em `NotReady` | Plugin de rede não instalado | Verificar se o Flannel está rodando: `kubectl get pods -n kube-flannel` |
| `kubelet` não inicia | Swap ativo | `sudo swapoff -a` e comentar a linha swap no `/etc/fstab` |
| Token expirado | Validade de 24h | `kubeadm token create --print-join-command` no master |
| Pods travados em `Pending` | Sem workers disponíveis | Verificar se os workers estão `Ready` |
| Erro de CRI | containerd mal configurado | Verificar `SystemdCgroup = true` no `/etc/containerd/config.toml` |

---

> **Próximos passos sugeridos:** Instalar o **Metrics Server** para monitoramento de recursos, configurar o **Ingress Controller** (nginx-ingress) para expor serviços HTTP, e explorar o **kubectl** para gerenciar deployments, services e configmaps.
