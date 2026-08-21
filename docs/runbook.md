# SRE Incident Lab — Kubernetes Troubleshooting Runbook

Este runbook reúne procedimentos básicos de diagnóstico utilizados no SRE Incident Lab para investigação de problemas envolvendo Pods, Deployments, probes, consumo de recursos e autoscaling.

O objetivo não é apenas listar comandos, mas estabelecer uma sequência de investigação baseada em evidências.

---

## 1. Escopo

Este runbook cobre troubleshooting do ambiente Kubernetes local do projeto:

- namespace `sre-lab`;
- aplicação `incident-api`;
- Deployment;
- Service;
- startup, readiness e liveness probes;
- requests e limits;
- Metrics Server;
- Horizontal Pod Autoscaler;
- PodDisruptionBudget;
- recriação de Pods.

---

## 2. Validação inicial do ambiente

Antes de investigar um incidente, confirmar o contexto Kubernetes:

```bash
kubectl config current-context
```

Verificar o node:

```bash
kubectl get nodes
```

Verificar os recursos da aplicação:

```bash
kubectl get all -n sre-lab
```

Estado esperado:

```text
Node: Ready
Deployment: 1/1
Pod: Running / Ready
Service: ClusterIP
```

---

## 3. Estado dos Pods

Primeira verificação durante uma indisponibilidade:

```bash
kubectl get pods -n sre-lab -o wide
```

Observar principalmente:

- `READY`;
- `STATUS`;
- `RESTARTS`;
- `AGE`;
- node;
- IP do Pod.

### Critérios iniciais

```text
1/1 Running + RESTARTS=0
→ estado normal

0/1 Running
→ investigar readiness/startup probe

RESTARTS aumentando
→ investigar liveness, crash ou término do processo

Pending
→ investigar scheduling e recursos

CrashLoopBackOff
→ investigar logs e estado anterior do container
```

---

## 4. Describe

Para investigar o estado detalhado de um Pod:

```bash
kubectl describe pod \
  -n sre-lab \
  <pod-name>
```

Verificar:

- State;
- Last State;
- Exit Code;
- Restart Count;
- requests e limits;
- probes;
- conditions;
- Events.

Para o Deployment:

```bash
kubectl describe deployment \
  incident-api \
  -n sre-lab
```

---

## 5. Logs

Logs atuais:

```bash
kubectl logs \
  -n sre-lab \
  deployment/incident-api
```

Quando ocorreu restart do container:

```bash
kubectl logs \
  -n sre-lab \
  deployment/incident-api \
  --previous
```

O `--previous` é importante para analisar a instância anterior do container depois de um restart.

---

## 6. Kubernetes Events

Eventos recentes:

```bash
kubectl get events \
  -n sre-lab \
  --sort-by=.lastTimestamp
```

Últimos eventos:

```bash
kubectl get events \
  -n sre-lab \
  --sort-by=.lastTimestamp |
  tail -n 20
```

Eventos encontrados durante o laboratório incluíram:

```text
Unhealthy
Readiness probe failed

Killing
Container failed liveness probe, will be restarted

SuccessfulCreate
ReplicaSet created a replacement Pod

Scheduled
Pod assigned to node

Created
Container created

Started
Container started
```

Events devem ser correlacionados com `describe`, logs e estado atual do workload antes de determinar uma causa raiz.

---

## 7. Rollout

Verificar o estado do Deployment:

```bash
kubectl rollout status \
  deployment/incident-api \
  -n sre-lab
```

Histórico:

```bash
kubectl rollout history \
  deployment/incident-api \
  -n sre-lab
```

Um rollout concluído confirma que o estado desejado atual foi alcançado.

Ele não comprova, isoladamente, que uma alteração anterior foi aplicada corretamente.

Durante o laboratório houve um caso em que um manifesto possuía erro de YAML e não foi aplicado. O comando `rollout status` retornou sucesso porque estava avaliando o Deployment anterior, ainda saudável.

Por isso, sempre validar também a saída do `kubectl apply`.

---

## 8. Probes

### Startup Probe

Endpoint:

```text
/health/live
```

Objetivo:

Evitar que liveness/readiness interfiram durante a inicialização da aplicação.

Configuração atual:

```text
periodSeconds: 2
failureThreshold: 15
```

### Readiness Probe

Endpoint:

```text
/health/ready
```

Quando a readiness falha:

```text
Pod continua Running
READY muda para 0/1
Pod deixa de participar dos endpoints prontos do Service
```

Teste realizado:

```bash
curl -X POST \
  http://localhost:8001/simulate/readiness/fail
```

Recuperação:

```bash
curl -X POST \
  http://localhost:8001/simulate/readiness/recover
```

### Liveness Probe

Endpoint:

```text
/health/live
```

Quando a liveness falha de forma persistente:

```text
kubelet detecta a falha
→ container é reiniciado
→ Restart Count aumenta
→ aplicação volta saudável
```

Teste realizado:

```bash
curl -X POST \
  http://localhost:8001/simulate/liveness/fail
```

Durante o laboratório, os Events registraram:

```text
Container incident-api failed liveness probe,
will be restarted
```

---

## 9. Requests e Limits

Configuração atual da Incident API:

```text
Requests:
CPU:    100m
Memory: 96Mi

Limits:
CPU:    250m
Memory: 192Mi
```

Verificar:

```bash
kubectl describe deployment \
  incident-api \
  -n sre-lab
```

O Pod passou a utilizar QoS:

```text
Burstable
```

---

## 10. Métricas

Metrics Server deve estar disponível:

```bash
kubectl get apiservice \
  v1beta1.metrics.k8s.io
```

Esperado:

```text
AVAILABLE=True
```

Consumo do node:

```bash
kubectl top nodes
```

Consumo dos Pods:

```bash
kubectl top pods -n sre-lab
```

Consumo por container:

```bash
kubectl top pod \
  -n sre-lab \
  --containers
```

Baseline observada durante o laboratório:

```text
Incident API idle:
CPU: aproximadamente 3m
Memory: aproximadamente 36Mi
```

Valores podem variar entre execuções.

---

## 11. Horizontal Pod Autoscaler

Verificar:

```bash
kubectl get hpa \
  incident-api \
  -n sre-lab
```

Detalhes:

```bash
kubectl describe hpa \
  incident-api \
  -n sre-lab
```

Configuração:

```text
CPU target: 50%
minReplicas: 1
maxReplicas: 3
```

Com CPU request de `100m`, o target de 50% corresponde aproximadamente a:

```text
50m de CPU por Pod
```

Durante carga controlada, o laboratório demonstrou:

```text
1 Pod
↓
CPU acima do target
↓
3 Pods
↓
carga encerrada
↓
2 Pods
↓
1 Pod
```

Events registrados:

```text
SuccessfulRescale
New size: 3 — CPU above target

SuccessfulRescale
New size: 2 — metrics below target

SuccessfulRescale
New size: 1 — metrics below target
```

Durante a criação de um novo Pod, o HPA pode temporariamente registrar:

```text
FailedGetResourceMetric
```

se o Pod ainda estiver unready e não possuir métricas disponíveis.

Avaliar novamente após o workload estabilizar antes de considerar isso uma falha persistente do Metrics Server.

---

## 12. PodDisruptionBudget

Verificar:

```bash
kubectl get pdb \
  incident-api \
  -n sre-lab
```

Configuração:

```text
minAvailable: 1
```

Com somente uma réplica:

```text
Allowed Disruptions: 0
```

Isso indica que disrupções voluntárias que respeitem o PDB não podem reduzir a disponibilidade abaixo de um Pod.

O PDB não é responsável por recriar Pods.

A reconciliação é responsabilidade do Deployment/ReplicaSet.

---

## 13. Recriação de Pod

Teste executado:

```bash
kubectl delete pod \
  -n sre-lab \
  <pod-name>
```

Comportamento observado:

```text
Pod antigo removido
↓
ReplicaSet detecta actual replicas < desired replicas
↓
novo Pod criado
↓
Scheduled
↓
Container Created
↓
Started
↓
Ready
```

O novo Pod recebeu um nome diferente e o Deployment retornou para:

```text
READY: 1/1
AVAILABLE: 1
```

Uma exclusão direta com `kubectl delete pod` não deve ser usada como prova de bloqueio do PDB.

O experimento demonstra principalmente o reconciliation loop do Deployment/ReplicaSet.

---

## 14. Service e Port Forward

Verificar Service:

```bash
kubectl get service \
  incident-api \
  -n sre-lab
```

Criar acesso local:

```bash
kubectl port-forward \
  -n sre-lab \
  service/incident-api \
  8000:8000
```

Health check:

```bash
curl http://localhost:8000/health/live
```

Esperado:

```json
{"status":"alive"}
```

Durante a exclusão/recriação de um Pod, uma sessão existente de port-forward pode perder conexão.

Após o workload voltar a ficar Ready, recriar o port-forward caso necessário.

---

## 15. Sequência recomendada de troubleshooting

```text
1. kubectl get pods
       ↓
2. Verificar READY / STATUS / RESTARTS
       ↓
3. kubectl describe pod
       ↓
4. kubectl get events
       ↓
5. kubectl logs
       ↓
6. kubectl logs --previous, se houve restart
       ↓
7. kubectl rollout status
       ↓
8. kubectl top pods
       ↓
9. kubectl get/describe hpa
       ↓
10. Validar Service e health endpoint
```

A causa raiz só deve ser registrada quando houver evidências suficientes para sustentá-la.

---

## 16. Casos observados no laboratório

### Caso 1 — Deployment novo não aplicado

Sintoma:

```text
ConfigMap e Secret existiam,
mas aplicação não recebia as variáveis.
```

Diagnóstico:

```text
kubectl apply deployment.yaml
→ erro de sintaxe YAML
```

Aprendizado:

Um `rollout status` bem-sucedido pode estar avaliando o Deployment anterior se a mudança pretendida nunca foi aplicada.

---

### Caso 2 — Readiness failure

Sintoma:

```text
Pod: 0/1 Running
```

Comportamento:

Pod continuou vivo, mas foi retirado dos endpoints prontos do Service.

---

### Caso 3 — Liveness failure

Sintoma:

```text
Restart Count aumentou.
```

Events:

```text
failed liveness probe
will be restarted
```

Comportamento:

Kubelet reiniciou o container e a aplicação retornou saudável.

---

### Caso 4 — Probe durante startup

Sintoma:

```text
connection refused
```

Após adicionar `startupProbe`, a aplicação recebeu uma janela dedicada para inicialização antes da atuação normal das outras probes.

Em uma execução posterior ainda foram observadas falhas temporárias da startup probe, porém o Pod tornou-se Ready e permaneceu com `Restart Count: 0`.

Não foi atribuída causa raiz sem evidência suficiente.

---

### Caso 5 — HPA e carga de CPU

Baseline:

```text
CPU ≈ 3m
```

Carga:

```text
CPU > target de 50%
```

Resultado:

```text
1 → 3 → 2 → 1 Pods
```

---

### Caso 6 — Pod removido

Sintoma:

Pod excluído manualmente.

Resultado:

ReplicaSet criou um novo Pod automaticamente e restabeleceu o estado desejado do Deployment.

---

## 17. Princípio operacional

O runbook segue uma regra simples:

> Observar primeiro, correlacionar evidências e somente depois concluir a causa.

Um comando isolado ou um único evento não deve ser tratado automaticamente como causa raiz.
