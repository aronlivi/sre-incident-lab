# SRE Incident Lab

Laboratório prático voltado ao desenvolvimento de competências em **Site Reliability Engineering (SRE)**, com foco em Kubernetes, Helm, Terraform, Datadog, observabilidade, resiliência e troubleshooting.

## Objetivo

Construir e operar uma aplicação containerizada em Kubernetes, utilizando infraestrutura como código, gerenciamento de releases e observabilidade.

O laboratório será utilizado para simular situações reais de operação, incluindo:

* falha e reinicialização de pods;
* indisponibilidade de dependências;
* alta utilização de CPU;
* aumento de latência;
* erros HTTP;
* escalabilidade automática;
* deploy defeituoso;
* rollback;
* alertas;
* SLOs;
* runbooks;
* post-mortem.

A proposta é evoluir o ambiente progressivamente, partindo de uma aplicação executada localmente até um laboratório com automação, observabilidade e simulações controladas de incidentes.

---

## Tecnologias

* Windows 11
* WSL2 / Ubuntu 20.04
* Docker
* Python / FastAPI
* pytest
* Kubernetes
* kind
* kubectl
* Helm
* Terraform
* Datadog
* Git / GitHub

---

## Ambiente local

O laboratório foi planejado para execução local e com **custo inicial de R$ 0**.

Devido às limitações de hardware do notebook utilizado no projeto, principalmente 8 GB de RAM, o cluster Kubernetes utiliza inicialmente apenas um nó.

### Toolchain validada

| Ferramenta | Versão |
| ---------- | ------ |
| Docker     | 29.6.2 |
| kubectl    | 1.36.3 |
| kind       | 0.32.0 |
| Helm       | 3.21.3 |
| Terraform  | 1.15.8 |
| Kubernetes | 1.36.1 |
| Python     | 3.8.10 |
| pytest     | 8.3.5  |

---

## Arquitetura inicial

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
   +--> Helm
   |
   +--> Datadog Agent

Terraform
   |
   +--> Kubernetes Resources
   +--> Helm Releases
   +--> Datadog Resources
```

### Diagrama da arquitetura

![SRE Incident Lab - Local Architecture](docs/images/sre-incident-lab-architecture.png)

Mais detalhes sobre as decisões de arquitetura estão disponíveis em:

[docs/architecture.md](docs/architecture.md)

---

# Roadmap

## Pré-projeto — 04/08 a 09/08 — Concluído

Principais atividades:

* definir escopo e objetivos;
* validar hardware e estratégia de custo;
* estruturar o repositório;
* criar documentação inicial;
* desenhar arquitetura;
* preparar o roadmap;
* anunciar o projeto.

---

## Semana 1 — 10/08 a 16/08 — Concluída

### Aplicação, Docker e cluster Kubernetes local

**Objetivo:** executar uma aplicação containerizada dentro de um cluster Kubernetes local e validar seu funcionamento.

### API desenvolvida

Foi criada uma API utilizando **Python e FastAPI**, preparada especificamente para gerar comportamentos úteis em futuros exercícios de observabilidade e incidentes.

Endpoints disponíveis:

* `/` — informações básicas do serviço;
* `/health/live` — indica se o processo da aplicação está ativo;
* `/health/ready` — indica se a aplicação está pronta para receber tráfego;
* `/error` — simula um erro HTTP 500;
* `/slow` — introduz latência controlada;
* `/cpu-stress` — gera carga controlada de CPU.

Exemplo de health check:

```bash
curl http://localhost:8000/health/live
```

Resposta esperada:

```json
{"status":"alive"}
```

A API também disponibiliza documentação automática através do Swagger UI:

```text
http://localhost:8000/docs
```

---

### Testes automatizados

Foram implementados testes básicos utilizando `pytest` e `TestClient` do FastAPI.

Os testes validam:

* endpoint raiz;
* liveness;
* readiness;
* erro HTTP 500;
* simulação de latência;
* geração de carga de CPU.

Execução:

```bash
python -m pytest -v
```

Resultado obtido:

```text
6 passed
```

---

### Containerização

A aplicação foi empacotada utilizando Docker.

Imagem criada:

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

Execução local:

```bash
docker run -d \
  --name incident-api \
  -p 8000:8000 \
  incident-api:0.1.0
```

O Dockerfile inclui um `HEALTHCHECK` utilizando:

```text
/health/live
```

Durante a validação foi confirmado:

* imagem construída com sucesso;
* container iniciado corretamente;
* container em estado `healthy`;
* porta `8000` exposta corretamente;
* endpoint de saúde respondendo;
* ciclo de `stop/start` do container validado.

Exemplo:

```bash
docker ps
```

Estado esperado:

```text
Up ... (healthy)
```

---

### Cluster Kubernetes

Foi criado um cluster Kubernetes local com `kind`.

Configuração inicial:

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

Estado obtido:

```text
NAME                    STATUS   ROLES
sre-lab-control-plane   Ready    control-plane
```

A utilização de um único nó foi uma decisão intencional para reduzir o consumo de recursos do notebook.

---

### Carregamento da imagem no kind

Como a imagem `incident-api:0.1.0` existe apenas localmente no Docker Desktop, ela precisou ser carregada no runtime utilizado pelo cluster `kind`.

Comando:

```bash
kind load docker-image incident-api:0.1.0 \
  --name sre-lab
```

Validação da imagem dentro do node:

```bash
docker exec sre-lab-control-plane \
  crictl images | grep incident-api
```

---

### Primeiro deployment Kubernetes

Foram criados manifests Kubernetes para:

* `Deployment`;
* `Service`.

Aplicação dos recursos:

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

Validações utilizadas:

```bash
kubectl get deployments

kubectl get pods -o wide

kubectl get services

kubectl rollout status deployment/incident-api
```

Resultado do rollout:

```text
deployment "incident-api" successfully rolled out
```

---

### Logs da aplicação no Kubernetes

Os logs passaram a ser obtidos diretamente através do Kubernetes:

```bash
kubectl logs deployment/incident-api
```

Saída esperada:

```text
Started server process
Waiting for application startup.
Application startup complete.
Uvicorn running on http://0.0.0.0:8000
```

---

### Acesso através do Kubernetes Service

A aplicação foi acessada localmente utilizando `port-forward`:

```bash
kubectl port-forward service/incident-api 8000:8000
```

Fluxo da requisição:

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
Container incident-api
      |
      v
Uvicorn
      |
      v
FastAPI
```

Validação:

```bash
curl http://localhost:8000/health/live
```

Resposta:

```json
{"status":"alive"}
```

---

### Baseline inicial de recursos

Antes de adicionar componentes adicionais de observabilidade, foi registrada uma baseline aproximada do cluster local.

Com o cluster Kubernetes ativo:

```text
Memória utilizada pelo node kind: ~720 MiB
Memória disponível no WSL: ~2.6 GiB
Swap utilizada: baixa
```

Essa informação será utilizada como referência ao adicionar componentes como:

* Metrics Server;
* Helm releases;
* Datadog Agent;
* aplicação com múltiplas réplicas.

---

### Dificuldades encontradas

Os problemas encontrados durante a Semana 1 também foram registrados como parte do processo de troubleshooting.

#### 1. Falha na primeira criação do cluster

A primeira inicialização do cluster `kind` falhou durante o bootstrap do Kubernetes API Server.

A tentativa seguinte, utilizando a mesma configuração, foi concluída com sucesso.

Nenhuma alteração de configuração foi necessária.

O episódio foi mantido documentado sem atribuir uma causa raiz não comprovada.

#### 2. Docker indisponível após reinicialização

Após reiniciar o notebook, o Docker Desktop não havia sido iniciado.

Como consequência, o comando:

```bash
docker
```

deixou temporariamente de ficar disponível no WSL.

O problema foi identificado como indisponibilidade do Docker Desktop, sem reinstalação do Docker Engine dentro do Ubuntu.

#### 3. pytest executado com Python incorreto

Durante a configuração dos testes foi executada acidentalmente uma versão do `pytest` disponibilizada pelos pacotes do Ubuntu e vinculada ao Python 2.

O pacote foi removido e os testes passaram a utilizar corretamente o ambiente virtual Python 3:

```bash
source .venv/bin/activate

python -m pytest -v
```

Resultado:

```text
6 passed
```

Esse cenário reforçou a importância de validar qual interpretador e quais executáveis estão sendo utilizados dentro do ambiente virtual.

---

### Principais aprendizados da Semana 1

Ao final da primeira etapa, o fluxo evoluiu de:

```text
Código Python
```

para:

```text
Código
   |
   v
Ambiente virtual
   |
   v
Testes
   |
   v
Docker Image
   |
   v
Docker Container
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

A principal evolução foi deixar de executar a aplicação apenas como um processo local e passar a executá-la como um workload gerenciado pelo Kubernetes.

---

## Semana 2 — 17/08 a 23/08

### Operação e resiliência Kubernetes

**Objetivo:** evoluir o deployment básico para um serviço com mecanismos de configuração, capacidade, resiliência e escalabilidade.

Próximas entregas:

* namespace dedicado;
* ConfigMap;
* Secret;
* liveness probe;
* readiness probe;
* requests e limits de CPU e memória;
* Metrics Server;
* Horizontal Pod Autoscaler;
* PodDisruptionBudget;
* testes de recriação de pods;
* runbook inicial de troubleshooting Kubernetes.

---

## Semana 3 — 24/08 a 30/08

### Helm e gerenciamento de releases

**Objetivo:** transformar os manifests Kubernetes em um Helm Chart reutilizável e praticar gerenciamento de releases.

Principais entregas previstas:

* Helm Chart;
* templates;
* `values.yaml`;
* `values-local.yaml`;
* `values-stress.yaml`;
* `helm lint`;
* `helm template`;
* upgrade;
* histórico de releases;
* rollback.

---

## Semana 4 — 31/08 a 06/09

### Terraform e Infrastructure as Code

**Objetivo:** automatizar e tornar reproduzível a preparação da plataforma.

Principais entregas previstas:

* providers Kubernetes e Helm;
* namespace e configurações da plataforma;
* instalação de componentes por Terraform;
* variáveis e outputs;
* `terraform plan`;
* `terraform apply`;
* `terraform destroy`;
* reconstrução controlada do ambiente.

---

## Semana 5 — 07/09 a 13/09

### Datadog e observabilidade

**Objetivo:** integrar infraestrutura e aplicação ao Datadog.

Principais entregas previstas:

* Datadog Agent;
* métricas Kubernetes;
* logs;
* APM / traces;
* dashboards;
* monitores;
* alertas;
* tags;
* SLO.

O trial do Datadog somente será ativado nesta etapa para aproveitar melhor o período disponível.

---

## Semana 6 — 14/09 a 20/09

### Game Day e post-mortem

**Objetivo:** provocar falhas controladas, detectar problemas, investigar causas e documentar a recuperação.

Cenários planejados:

* pod removido;
* aplicação indisponível;
* CPU elevada;
* aumento de latência;
* erros HTTP;
* deploy defeituoso;
* rollback;
* falha de dependência.

Serão registrados:

* sintomas;
* alertas;
* diagnóstico;
* causa raiz quando identificada;
* ação de recuperação;
* MTTD;
* MTTR;
* ações preventivas;
* post-mortem.

---

# Segurança e credenciais

Nenhuma credencial real deve ser versionada neste repositório.

Os seguintes itens não devem ser enviados ao GitHub:

* API Keys;
* Application Keys;
* tokens;
* senhas;
* arquivos `.env`;
* arquivos `.tfvars` contendo valores reais;
* arquivos `terraform.tfstate`;
* chaves privadas;
* Kubernetes Secrets contendo credenciais reais.

Arquivos de exemplo poderão ser versionados desde que utilizem somente valores fictícios.

---

# Estrutura do repositório

```text
sre-incident-lab/
├── app/
│   ├── src/
│   ├── tests/
│   ├── Dockerfile
│   └── requirements.txt
│
├── cluster/
│   ├── kind-config.yaml
│   └── manifests/
│       ├── deployment.yaml
│       └── service.yaml
│
├── docs/
│   ├── decisions/
│   ├── images/
│   ├── architecture.md
│   ├── runbook.md
│   └── postmortem.md
│
├── helm/
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

# Status atual

* [x] Planejamento inicial
* [x] Arquitetura inicial
* [x] Repositório Git e GitHub
* [x] WSL2 configurado
* [x] Toolchain local instalada e validada
* [x] API FastAPI
* [x] Endpoints para simulação de falhas
* [x] Testes automatizados
* [x] Dockerfile
* [x] Imagem Docker
* [x] Container validado como healthy
* [x] Cluster Kubernetes local
* [x] Primeiro Deployment Kubernetes
* [x] Service Kubernetes
* [x] Aplicação acessível através de port-forward
* [ ] Resiliência e operação Kubernetes
* [ ] Metrics Server
* [ ] HPA
* [ ] Runbook
* [ ] Helm Chart
* [ ] Automação com Terraform
* [ ] Observabilidade com Datadog
* [ ] Game Day
* [ ] Post-mortem final

---

# Licença

Este projeto é disponibilizado sob a **MIT License**.

Consulte o arquivo:

[LICENSE](LICENSE)

---

# Status do projeto

🚧 **Em desenvolvimento**

**Próxima etapa:** operação e resiliência Kubernetes.

