# Storage estático + Deployment — passo a passo

Provisionamento **estático** (StorageClass com `no-provisioner`): o PV é criado à mão, antes de qualquer claim.

## Fluxo (ordem de criação)

```
StorageClass  →  PersistentVolume  →  PersistentVolumeClaim  →  Deployment (Pod)  →  Service
    (1)                (2)                    (3)                      (4)              (5)
```

- **StorageClass** — só uma "etiqueta" para casar PV e PVC pelo `storageClassName`. Com `no-provisioner` ela não cria nada sozinha.
- **PersistentVolume** — o disco real (aqui `hostPath: /mnt/data`). Nasce `Available`.
- **PersistentVolumeClaim** — o pedido. O Kubernetes procura um PV compatível e faz o *bind*.
- **Deployment** — gera os Pods que montam o PVC via `volumes` + `volumeMounts`.
- **Service** — expõe o nginx (NodePort na 30000).

Com `volumeBindingMode: WaitForFirstConsumer`, o bind PV↔PVC só acontece quando o **primeiro Pod** é agendado — não no momento em que o PVC é criado.

## Aplicar

```bash
kubectl apply -f sc-01.yaml
kubectl apply -f pv-01.yaml
kubectl apply -f pvc-01.yaml
kubectl apply -f deploy-01.yaml
kubectl apply -f svc-01.yaml
```

Ou tudo de uma vez, se estiver num único arquivo separado por `---`:

```bash
kubectl apply -f stack.yaml
```

## Validar

```bash
kubectl get sc                    # StorageClass criada
kubectl get pv                    # STATUS deve ir para Bound
kubectl get pvc                   # STATUS deve ir para Bound
kubectl get pods -o wide          # Pods Running e em qual nó caíram
kubectl get deployment            # READY deve ficar 3/3 (ou 1/1)
kubectl get svc                   # confirmar NodePort 30000
```

Estado saudável:

- `pv` → `Bound` para `default/pvc-01`
- `pvc` → `Bound` para o PV
- `pods` → todos `Running` (se algum ficar `Pending`, ver abaixo)

Testar o nginx (troca `<IP-do-nó>` pelo IP do worker):

```bash
curl http://<IP-do-nó>:30000
```

## Diagnóstico rápido

```bash
kubectl describe pvc pvc-01       # por que o PVC não faz Bind
kubectl describe pod <nome>       # eventos do Pod (Pending, erro de mount, etc.)
kubectl logs <nome>               # logs do nginx
```

## Armadilhas conhecidas

- **`ReadWriteOnce` + várias réplicas**: o volume monta em **um nó** por vez. Réplicas em outros nós ficam `Pending`. Em cluster de 1 worker passa; com vários nós, use `replicas: 1`, ou `ReadWriteMany` (ex: NFS), ou um StatefulSet.
- **`RECLAIM POLICY: Retain`**: ao deletar o PVC, o PV **não** recicla sozinho — fica `Released` e os dados continuam em `/mnt/data`. Para reusar, apagar/recriar o PV ou limpar o `claimRef`.
- **Campos são case-sensitive**: `kind: PersistentVolume`, `storageClassName`, `apiVersion: apps/v1` para Deployment. Erro comum: "no matches for kind ... ensure CRDs are installed first" quase sempre é `apiVersion`/`kind` escrito errado, não CRD faltando.
- **Nomes RFC 1123**: só minúsculas, números e hífen.

## Limpar

```bash
kubectl delete -f svc-01.yaml -f deploy-01.yaml -f pvc-01.yaml -f pv-01.yaml -f sc-01.yaml
```
