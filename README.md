# SRE Incident Lab

Laboratório prático voltado ao desenvolvimento de competências em **Site Reliability Engineering (SRE)**, com foco em Kubernetes, Helm, Terraform, Datadog, observabilidade, resiliência, automação e troubleshooting.

O projeto foi criado para transformar conceitos estudados em experiências práticas de operação, falha, investigação e recuperação de serviços.

---

## Objetivo

Construir e operar uma aplicação containerizada em Kubernetes, evoluindo progressivamente o ambiente com mecanismos de configuração, resiliência, escalabilidade, gerenciamento de releases, Infrastructure as Code e observabilidade.

O laboratório será utilizado para simular situações comuns de operação, incluindo:

- falha e reinicialização de Pods;
- indisponibilidade de dependências;
- alta utilização de CPU;
- aumento de latência;
- erros HTTP;
- falhas de readiness e liveness;
- escalabilidade automática;
- deploy defeituoso;
- rollback;
- alertas;
- SLOs;
- troubleshooting;
- runbooks;
- Game Days;
- post-mortems.

A proposta é partir de uma aplicação simples executada localmente e evoluir até um laboratório reproduzível, observável e preparado para falhas controladas.

---

## Tecnologias

- Windows 11
- WSL2 / Ubuntu 20.04
- Docker
- Python
- FastAPI
- pytest
- Kubernetes
- kind
- kubectl
- Metrics Server
- Helm
- Terraform
- Datadog
- Git
- GitHub

---

## Ambiente local

O laboratório foi planejado para execução local e com **custo inicial de R$ 0**.

Por causa das limitações de hardware do notebook utilizado no projeto, principalmente os **8 GB de RAM**, o cluster Kubernetes utiliza um único nó e os experimentos são executados com consumo controlado de recursos.

### Toolchain validada

| Ferramenta | Versão |
| --- | --- |
| Docker | 29.6.2 |
| kubectl | 1.36.3 |
| kind | 0.32.0 |
| Helm | 3.21.3 |
| Terraform | 1.15.8 |
| Kubernetes | 1.36.1 |
| Python | 3.8.10 |
| pytest | 8.3.5 |

---

## Arquitetura

Fluxo de alto nível do laboratório:

```text
Windows 11
   |
   v
WSL2 / Ubuntu
   |
   v
Docker Desktop
   |
   v
kind
   |
   v
Kubernetes Cluster
   |
   +--> Incident API
   |
   +--> Kubernetes Resources
   |
   +--> Metrics Server
   |
   +--> Helm Releases
   |
   +--> Datadog Agent

Terraform
   |
   +--> Kubernetes Resources
   +--> Helm Releases
   +--> Platform Components
   +--> Datadog Resources
```

### Diagrama da arquitetura

![SRE Incident Lab - Local Architecture](docs/images/sre-incident-lab-architecture.png)

Mais detalhes sobre as decisões de arquitetura estão disponíveis em:

[docs/architecture.md](docs/architecture.md)

---

## Roadmap

### Pré-projeto — 04/08 a 09/08 — Concluído

O pré-projeto foi utilizado para validar a viabilidade técnica e estruturar o laboratório antes da execução.

Principais atividades:

- definição do objetivo e escopo;
- validação do hardware;
- definição da estratégia de custo zero;
- criação do repositório;
- criação da documentação inicial;
- planejamento do roadmap de seis semanas;
- desenho da arquitetura;
- definição da estratégia de conteúdo;
- anúncio público do projeto.

A decisão inicial foi utilizar um cluster `kind` com apenas um nó e deixar ambientes cloud, como EKS, fora do escopo inicial.

---

### Semana 1 — 10/08 a 16/08 — Concluída

#### Aplicação, Docker e cluster Kubernetes local

**Objetivo:** criar uma aplicação preparada para simulação de incidentes, containerizá-la e executá-la dentro de Kubernetes.

#### API desenvolvida

Foi criada uma API utilizando **Python e FastAPI** com endpoints específicos para futuros experimentos de operação e observabilidade.

Endpoints disponíveis:

- `/` — informações básicas do serviço;
- `/health/live` — liveness da aplicação;
- `/health/ready` — readiness da aplicação;
- `/error` — simulação de HTTP 500;
- `/slow` — introdução controlada de latência;
- `/cpu-stress` — geração controlada de carga de CPU.

Exemplo:

```bash
curl http://localhost:8000/health/live
```

Resposta:

```json
{"status":"alive"}
```

A API também disponibiliza documentação automática através do Swagger UI:

```text
http://localhost:8000/docs
```

#### Testes automatizados

Foram implementados testes utilizando `pytest` e o `TestClient` do FastAPI.

Os testes validam:

- endpoint raiz;
- liveness;
- readiness;
- erro HTTP 500;
- simulação de latência;
- geração de carga de CPU.

Execução:

```bash
python -m pytest -v
```

Resultado:

```text
6 passed
```

#### Containerização

A primeira versão da aplicação foi empacotada em:

```text
incident-api:0.1.0
```

Build:

```bash
docker build \
  -f app/Dockerfile \
  -t incident-api:0.1.0 \
  .
```

O Dockerfile também utiliza um `HEALTHCHECK` baseado em:

```text
/health/live
```

Durante a validação foram confirmados:

- build da imagem;
- inicialização do container;
- estado `healthy`;
- exposição da porta 8000;
- acesso aos endpoints;
- comportamento após `stop/start`.

#### Cluster Kubernetes

Foi criado um cluster local utilizando `kind`.

Configuração:

```text
Cluster: sre-lab
Nodes: 1
Node: sre-lab-control-plane
Kubernetes: v1.36.1
```

Validação:

```bash
kubectl get nodes
```

Estado esperado:

```text
NAME                    STATUS   ROLES
sre-lab-control-plane   Ready    control-plane
```

#### Carregamento da imagem no kind

Como a imagem existe localmente no Docker Desktop, ela foi importada para o runtime do cluster:

```bash
kind load docker-image incident-api:0.1.0 \
  --name sre-lab
```

#### Primeiro Deployment

Inicialmente foram criados manifests Kubernetes para:

- Deployment;
- Service.

Aplicação:

```bash
kubectl apply -f cluster/manifests/
```

Estado validado:

```text
Deployment: incident-api
Replicas: 1/1
Pod: Running
Service: ClusterIP
Port: 8000
```

#### Acesso pelo Kubernetes Service

A aplicação foi acessada utilizando:

```bash
kubectl port-forward \
  service/incident-api \
  8000:8000
```

Fluxo:

```text
Browser / curl
      |
      v
localhost:8000
      |
      v
kubectl port-forward
      |
      v
Kubernetes Service
      |
      v
Pod
      |
      v
Container
      |
      v
Uvicorn / FastAPI
```

#### Baseline inicial

Antes da instalação dos componentes adicionais, foi registrada uma baseline aproximada:

```text
Node kind: ~720 MiB
WSL disponível: ~2.6 GiB
Swap: baixa utilização
```

Esses dados passaram a servir como referência para acompanhar o impacto dos novos componentes.

#### Dificuldades encontradas

Durante a Semana 1 também foram documentadas situações reais de troubleshooting.

**Falha na primeira criação do cluster**

A primeira inicialização do `kind` falhou durante o bootstrap do Kubernetes API Server.

Uma nova tentativa com a mesma configuração funcionou.

Como não houve evidência suficiente para determinar a causa raiz, nenhuma causa foi atribuída.

**Docker indisponível após reinicialização**

Após reiniciar o notebook, o Docker Desktop ainda não havia sido iniciado.

O Docker ficou temporariamente indisponível no WSL e voltou a funcionar após iniciar o Docker Desktop, sem necessidade de reinstalação.

**pytest executado com interpretador incorreto**

Uma instalação de `pytest` vinculada ao Python 2 foi utilizada acidentalmente.

O pacote foi removido e os testes passaram a ser executados dentro do ambiente virtual:

```bash
source .venv/bin/activate

python -m pytest -v
```

#### Aprendizado da Semana 1

O fluxo evoluiu de:

```text
Código Python
```

para:

```text
Código
   |
   v
Testes
   |
   v
Docker Image
   |
   v
kind
   |
   v
Kubernetes Deployment
   |
   v
Pod
   |
   v
Service
```

A principal evolução foi deixar de executar a aplicação apenas como processo local e passar a operá-la como um workload gerenciado pelo Kubernetes.

---

### Semana 2 — 17/08 a 23/08 — Concluída

#### Operação e resiliência Kubernetes

**Objetivo:** evoluir o Deployment básico para um serviço com mecanismos de configuração, capacidade, resiliência, troubleshooting e escalabilidade.

A aplicação passou a ser isolada no namespace:

```text
sre-lab
```

e os recursos receberam labels padronizadas.

Foram implementados:

- ConfigMap;
- Secret;
- startup probe;
- readiness probe;
- liveness probe;
- requests e limits;
- Metrics Server;
- Horizontal Pod Autoscaler;
- PodDisruptionBudget;
- testes de recriação de Pods;
- runbook de troubleshooting Kubernetes.

#### Configuração externa

A aplicação passou a receber parâmetros através de variáveis de ambiente provenientes de:

```text
ConfigMap
Secret
```

Nenhum segredo real foi versionado no repositório.

A aplicação também evoluiu para a versão:

```text
incident-api:0.3.0
```

#### Probes

Foram implementadas três categorias de health check.

**Startup Probe**

Fornece uma janela dedicada para inicialização da aplicação antes da atuação normal das outras probes.

**Readiness Probe**

Uma falha de readiness fez o Pod permanecer em execução, porém com:

```text
0/1 Running
```

Nesse estado, o Pod deixa de participar dos endpoints prontos do Service.

**Liveness Probe**

Uma falha persistente de liveness fez o kubelet reiniciar automaticamente o container.

Os Kubernetes Events registraram:

```text
Readiness probe failed

Container incident-api failed liveness probe,
will be restarted
```

Esse experimento demonstrou que readiness e liveness resolvem problemas diferentes.

#### Requests e Limits

Foram definidos:

```text
Requests:
CPU:    100m
Memory: 96Mi

Limits:
CPU:    250m
Memory: 192Mi
```

O consumo passou a ser acompanhado utilizando:

```bash
kubectl top nodes

kubectl top pods -n sre-lab
```

#### Metrics Server

O Metrics Server foi instalado para fornecer métricas de CPU e memória utilizadas por:

- `kubectl top`;
- Horizontal Pod Autoscaler.

Validações:

```bash
kubectl top nodes
kubectl top pods -n sre-lab
```

#### Horizontal Pod Autoscaler

O HPA foi configurado com:

```text
CPU target: 50%
minReplicas: 1
maxReplicas: 3
```

Durante um experimento de carga controlada, foi observado:

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

O Kubernetes registrou eventos:

```text
SuccessfulRescale
```

confirmando o scale-out e o scale-down.

#### PodDisruptionBudget e reconciliation loop

Foi configurado:

```text
minAvailable: 1
```

Também foi realizada a exclusão manual de um Pod para observar o reconciliation loop.

Resultado:

```text
Pod removido
↓
ReplicaSet detecta diferença
entre estado atual e desejado
↓
novo Pod criado
↓
Deployment retorna para 1/1
```

O exercício permitiu diferenciar dois conceitos:

- o PodDisruptionBudget define políticas para determinadas disrupções voluntárias;
- o Deployment/ReplicaSet mantém o estado desejado e recria Pods.

#### Runbook de troubleshooting

Foi criado um runbook com uma sequência inicial de investigação:

```text
kubectl get pods
↓
kubectl describe
↓
kubectl get events
↓
kubectl logs
↓
kubectl logs --previous
↓
kubectl rollout status
↓
kubectl top
↓
kubectl get/describe hpa
```

A documentação está disponível em:

[docs/runbook.md](docs/runbook.md)

#### Aprendizado da Semana 2

O principal princípio registrado no runbook foi:

> Observar primeiro, correlacionar evidências e somente depois concluir a causa.

A Semana 2 transformou o Deployment inicial em um workload com mecanismos básicos de operação, recuperação e escalabilidade.

---

### Semana 3 — 24/08 a 30/08 — Concluída

#### Helm e gerenciamento de releases

**Objetivo:** substituir o gerenciamento baseado apenas em manifests estáticos por releases parametrizadas, reproduzíveis e com histórico e capacidade de rollback.

Os recursos Kubernetes foram convertidos para templates Helm.

O chart passou a gerenciar:

- Deployment;
- Service;
- ConfigMap;
- Secret;
- Horizontal Pod Autoscaler;
- PodDisruptionBudget.

#### Estrutura do Chart

```text
helm/incident-api/
├── Chart.yaml
├── values.yaml
├── values-local.yaml
├── values-stress.yaml
└── templates/
    ├── _helpers.tpl
    ├── configmap.yaml
    ├── deployment.yaml
    ├── hpa.yaml
    ├── pdb.yaml
    ├── secret.yaml
    └── service.yaml
```

#### Perfis

Foram criados diferentes conjuntos de values.

**Perfil local**

```text
replicas: 1
HPA: disabled

requests:
CPU: 50m
Memory: 64Mi

limits:
CPU: 200m
Memory: 128Mi
```

**Perfil stress**

```text
HPA: enabled
minReplicas: 1
maxReplicas: 3
CPU target: 50%

requests:
CPU: 100m
Memory: 96Mi

limits:
CPU: 250m
Memory: 192Mi
```

Os perfis permitem alterar o comportamento da release sem modificar os templates.

#### Validação do Chart

O chart foi validado através de:

```bash
helm lint helm/incident-api
```

e:

```bash
helm template incident-api \
  helm/incident-api \
  --namespace sre-lab
```

Também foram realizados testes utilizando:

```text
kubectl apply --dry-run=server
```

em um namespace temporário.

#### Migração dos manifests manuais

Durante a migração foi identificado que o Deployment criado anteriormente possuía um `spec.selector` diferente daquele gerado pelo Helm.

O Kubernetes rejeitou a alteração porque:

```text
spec.selector
```

é imutável após a criação do Deployment.

Os recursos manuais da aplicação foram então removidos de maneira controlada e recriados como uma release gerenciada pelo Helm.

#### Instalação e Upgrade

A primeira instalação utilizou o perfil local:

```text
Revision 1
Status: deployed
Profile: local
```

Posteriormente foi realizado upgrade para:

```text
Revision 2
Status: deployed
Profile: stress
```

O histórico passou a ser consultado utilizando:

```bash
helm history incident-api -n sre-lab
```

#### Deploy defeituoso

Foi criada propositalmente uma revision utilizando uma imagem inexistente:

```text
incident-api:0.3.0-broken
```

com:

```text
imagePullPolicy=Never
```

O Kubernetes registrou:

```text
ErrImageNeverPull
```

e o Helm marcou:

```text
Revision 3
Status: failed
```

Durante o rollout defeituoso, o Pod da revision anterior permaneceu saudável enquanto o novo Pod não atingia o estado Ready.

Por isso, o experimento não demonstrou indisponibilidade completa do serviço.

#### Rollback

A última revision saudável era a revision 2.

O rollback foi executado com:

```bash
helm rollback incident-api 2 \
  --namespace sre-lab \
  --wait \
  --timeout 2m
```

O histórico final ficou:

```text
Revision 1 — superseded
Revision 2 — superseded
Revision 3 — failed
Revision 4 — deployed — Rollback to 2
```

O comando de rollback foi concluído em aproximadamente:

```text
16 segundos
```

Esse valor representa o tempo entre o início do comando de rollback e a confirmação de conclusão pelo Helm.

Ele não representa tempo de indisponibilidade da aplicação.

#### Segurança dos Secrets

O chart utiliza por padrão:

```yaml
secret:
  create: false
```

A release referencia um Secret Kubernetes externo.

O template de Secret foi validado somente com valores fictícios, evitando o versionamento de credenciais reais.

#### Documentação Helm

A documentação detalhada sobre estrutura, profiles, upgrades, histórico e rollback está disponível em:

[docs/helm-releases.md](docs/helm-releases.md)

#### Aprendizado da Semana 3

O Helm adicionou uma camada de gerenciamento de estado sobre os recursos Kubernetes:

```text
instalação
↓
revision
↓
upgrade
↓
history
↓
falha
↓
rollback
```

O principal aprendizado foi que uma release pode falhar sem necessariamente causar indisponibilidade total.

O estado da release, o estado do rollout e a disponibilidade real dos Pods precisam ser analisados em conjunto.

---

### Semana 4 — 31/08 a 06/09 — Planejada

#### Terraform e Infrastructure as Code

**Objetivo:** tornar a preparação da plataforma reproduzível utilizando Terraform.

Principais entregas previstas:

- configurar providers Kubernetes e Helm;
- definir versões dos providers;
- versionar o lock file;
- provisionar namespace e ResourceQuota;
- instalar Metrics Server utilizando o Helm provider;
- criar variables e outputs;
- criar `terraform.tfvars.example`;
- revisar proteção de state e credenciais;
- executar `terraform fmt`;
- executar `terraform validate`;
- executar `terraform plan`;
- executar `terraform apply`;
- executar `terraform destroy`;
- reconstruir o ambiente seguindo somente a documentação.

---

### Semana 5 — 07/09 a 13/09 — Planejada

#### Datadog e observabilidade

**Objetivo:** integrar infraestrutura e aplicação ao Datadog.

Principais entregas previstas:

- ativação controlada do trial;
- criação segura de API/Application Keys;
- Datadog Agent;
- Cluster Agent;
- métricas Kubernetes;
- logs;
- APM;
- traces;
- tags de `env`, `service`, `version` e `team`;
- dashboards;
- monitores;
- alertas;
- SLO.

O trial somente será ativado nesta etapa para aproveitar melhor o período disponível.

---

### Semana 6 — 14/09 a 20/09 — Planejada

#### Game Day e post-mortem

**Objetivo:** provocar falhas controladas, detectar sintomas, investigar causas, recuperar o serviço e documentar os incidentes.

Cenários planejados:

- exclusão/reinício de Pod;
- aplicação indisponível;
- CPU elevada;
- autoscaling;
- aumento de latência;
- erros HTTP;
- deploy defeituoso;
- rollback;
- falhas de dependência.

Serão registrados:

- sintomas;
- alertas;
- evidências;
- diagnóstico;
- causa raiz quando comprovada;
- ação de recuperação;
- MTTD;
- MTTR;
- timeline;
- ações preventivas;
- post-mortem.

---

## Segurança e credenciais

Nenhuma credencial real deve ser versionada neste repositório.

Não devem ser enviados ao GitHub:

- API Keys;
- Application Keys;
- tokens;
- senhas;
- arquivos `.env`;
- `.tfvars` contendo valores reais;
- `terraform.tfstate`;
- backups de state;
- chaves privadas;
- Kubernetes Secrets contendo valores reais.

Arquivos de exemplo podem ser versionados desde que contenham somente valores fictícios.

A estratégia adotada é separar:

```text
código e configuração reproduzível
          ↓
       GitHub

credenciais e secrets reais
          ↓
fora do repositório
```

---

## Estrutura do repositório

```text
sre-incident-lab/
├── app/
│   ├── src/
│   ├── tests/
│   ├── Dockerfile
│   └── requirements.txt
│
├── cluster/
│   ├── examples/
│   ├── manifests/
│   └── kind-config.yaml
│
├── docs/
│   ├── decisions/
│   ├── images/
│   ├── architecture.md
│   ├── helm-releases.md
│   ├── postmortem.md
│   └── runbook.md
│
├── helm/
│   └── incident-api/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-local.yaml
│       ├── values-stress.yaml
│       └── templates/
│           ├── _helpers.tpl
│           ├── configmap.yaml
│           ├── deployment.yaml
│           ├── hpa.yaml
│           ├── pdb.yaml
│           ├── secret.yaml
│           └── service.yaml
│
├── scenarios/
├── scripts/
├── terraform/
│   ├── platform/
│   └── datadog/
│
├── .github/
├── .dockerignore
├── .gitignore
├── LICENSE
├── Makefile
└── README.md
```

---

## Status atual

- [x] Planejamento inicial
- [x] Arquitetura inicial
- [x] Repositório Git e GitHub
- [x] WSL2 configurado
- [x] Toolchain local instalada e validada
- [x] API FastAPI
- [x] Endpoints para simulação de falhas
- [x] Testes automatizados
- [x] Dockerfile e imagem Docker
- [x] Cluster Kubernetes local
- [x] Deployment e Service Kubernetes
- [x] Namespace dedicado
- [x] ConfigMap e Secret
- [x] Startup, readiness e liveness probes
- [x] Requests e limits
- [x] Metrics Server
- [x] Horizontal Pod Autoscaler
- [x] PodDisruptionBudget
- [x] Testes de recriação de Pods
- [x] Runbook de troubleshooting
- [x] Helm Chart
- [x] Perfis local e stress
- [x] Validação com Helm lint e template
- [x] Releases e upgrades com Helm
- [x] Deploy defeituoso controlado
- [x] Rollback com Helm
- [ ] Automação com Terraform
- [ ] Observabilidade com Datadog
- [ ] Game Day
- [ ] Post-mortem final

---

## Documentação

Documentos complementares:

- [Arquitetura](docs/architecture.md)
- [Runbook de troubleshooting Kubernetes](docs/runbook.md)
- [Helm Releases](docs/helm-releases.md)
- [Post-mortem](docs/postmortem.md)

---

## Licença

Este projeto é disponibilizado sob a **MIT License**.

Consulte:

[LICENSE](LICENSE)

---

## Status do projeto

🚧 **Em desenvolvimento**

Etapas concluídas:

```text
Pré-projeto   ✅
Semana 1      ✅
Semana 2      ✅
Semana 3      ✅
```

**Próxima etapa:** Terraform e Infrastructure as Code.
