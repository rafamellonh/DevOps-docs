# kubectl port-forward — Acesso rápido a Services e Pods

> **Uso:** acesso rápido e debug. **Não** serve para acesso permanente.

---

## Como funciona

O `port-forward` é um **processo rodando onde o `kubectl` foi executado**. Ele abre uma porta nessa máquina e faz um túnel até o pod:

```
navegador → IP-da-máquina-do-kubectl:PORTA (processo kubectl)
         → apiserver → kubelet do node onde o pod roda → pod
```

- Não importa em qual node o pod está: o túnel passa pelo apiserver
- Escuta **sempre na máquina que roda o `kubectl`** (no lab: o master `192.168.2.181`)
- Funciona **só enquanto o comando estiver rodando**
- Se o pod for recriado, o túnel quebra e é preciso rodar o comando de novo

---

## Sintaxe

```bash
k port-forward -n NAMESPACE svc/NOME PORTA_LOCAL:PORTA_DO_SERVICE
k port-forward -n NAMESPACE pod/NOME PORTA_LOCAL:PORTA_DO_CONTAINER
```

| Parte | Significado |
|---|---|
| `PORTA_LOCAL` | Porta aberta na máquina do `kubectl` |
| `PORTA_DO_SERVICE` | O `port` do Service (ou a porta do container, se for pod) |
| `--address 0.0.0.0` | Escuta em todas as interfaces (acessível pela rede) |

---

## Armadilha 1 — só escuta em localhost

Por padrão escuta só em `127.0.0.1`:

```
Forwarding from 127.0.0.1:3000 -> 3000
```

Rodando no master e abrindo `http://localhost:3000` no PC **não funciona**: o `localhost` do PC é o próprio PC.

**Solução:** abrir para a rede e acessar pelo IP do master:

```bash
k port-forward -n monitoring svc/grafana 3000:3000 --address 0.0.0.0
```

```
http://192.168.2.181:3000
```

---

## Armadilha 2 — portas abaixo de 1024

Portas privilegiadas (80, 443...) exigem root para escutar:

```
Error listen tcp4 127.0.0.1:443: bind: permission denied
```

**Solução:** usar uma porta local alta no formato `local:remota`:

```bash
k port-forward svc/meu-app 8443:443
```

> Evite `sudo kubectl port-forward`: o root não tem o `~/.kube/config` nem o alias `k`.

---

## Alternativa — rodar o kubectl no próprio PC

Com o kubeconfig do cluster no PC, o túnel escuta no PC e `localhost` funciona sem `--address`:

```bash
scp rafael@192.168.2.181:~/.kube/config ~/.kube/config
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

```
http://localhost:3000
```

---

## Vários túneis ao mesmo tempo

Em terminais separados ou em background com `&`:

```bash
k port-forward -n monitoring svc/grafana 3000:3000 --address 0.0.0.0 &
k port-forward -n monitoring svc/prometheus-k8s 9090:9090 --address 0.0.0.0 &
k port-forward -n monitoring svc/alertmanager-main 9093:9093 --address 0.0.0.0 &
```

Listar e encerrar os que estão em background:

```bash
jobs
kill %1
```

---

## Acesso permanente (sem depender de terminal aberto)

| Forma | URL de exemplo | Observação |
|---|---|---|
| **Ingress** | `http://grafana.nginx.io:32005` | O mais limpo; vários apps na mesma porta, separados por host |
| **NodePort** | `http://IP-DE-QUALQUER-NODE:3XXXX` | Porta alta (30000–32767) em todos os nodes |
| **LoadBalancer + MetalLB** | `http://192.168.2.24X:3000` | IP próprio da rede, sem porta alta |

> **Regra:** `port-forward` para acesso rápido e debug; **Ingress / NodePort / LoadBalancer** para uso contínuo.

---

## Referência rápida (kube-prometheus — Day 11)

| Serviço | Comando | URL | Login |
|---|---|---|---|
| Grafana | `k port-forward -n monitoring svc/grafana 3000:3000 --address 0.0.0.0` | `http://192.168.2.181:3000` | admin / admin (pede troca no 1º acesso) |
| Prometheus | `k port-forward -n monitoring svc/prometheus-k8s 9090:9090 --address 0.0.0.0` | `http://192.168.2.181:9090` | — |
| Alertmanager | `k port-forward -n monitoring svc/alertmanager-main 9093:9093 --address 0.0.0.0` | `http://192.168.2.181:9093` | — |

> **Nota:** o kube-prometheus instala NetworkPolicies que só liberam tráfego de dentro do namespace `monitoring`. Com Flannel elas **não são aplicadas**; com Calico/Cilium, um Ingress para o Grafana precisaria liberar o namespace `ingress-nginx` nessas políticas.
