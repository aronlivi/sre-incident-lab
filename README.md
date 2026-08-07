# SRE Incident Lab

Laboratório prático voltado ao desenvolvimento de competências em Site Reliability Engineering (SRE), com foco em Kubernetes, Helm, Terraform, Datadog, observabilidade, resiliência e troubleshooting.

## Objetivo

Construir e operar uma aplicação containerizada em Kubernetes, utilizando infraestrutura como código, gerenciamento de releases e observabilidade.

O laboratório será utilizado para simular situações reais de operação, incluindo:

- falha e reinicialização de pods;
- indisponibilidade de dependências;
- alta utilização de CPU;
- aumento de latência;
- erros HTTP;
- escalabilidade automática;
- deploy defeituoso;
- rollback;
- alertas, SLOs, runbooks e post-mortem.

## Tecnologias

- Windows 11
- WSL2 / Ubuntu 20.04
- Docker
- Python / FastAPI
- Kubernetes
- kind
- kubectl
- Helm
- Terraform
- Datadog
- Git / GitHub

## Ambiente local

O laboratório foi planejado para execução local e com custo inicial de R$ 0.

O cluster Kubernetes utiliza apenas um nó para reduzir o consumo de recursos do notebook.

### Toolchain validada

| Ferramenta | Versão |
|---|---|
| Docker | 29.6.2 |
| kubectl | 1.36.3 |
| kind | 0.32.0 |
| Helm | 3.21.3 |
| Terraform | 1.15.8 |
| Kubernetes | 1.36.1 |

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
   +--> Kubernetes resources
   |
   +--> Helm
   |
   +--> Datadog Agent

Terraform
   |
   +--> Kubernetes resources
   +--> Helm releases
   +--> Datadog resources
```

Um diagrama visual detalhado da arquitetura será adicionado posteriormente em `docs/architecture.md`.

## Roadmap

### Pré-projeto — 04/08 a 09/08

- Definir escopo e objetivos
- Validar hardware e estratégia de custo
- Estruturar o repositório
- Criar documentação inicial
- Desenhar arquitetura
- Anunciar o projeto

### Semana 1 — 10/08 a 16/08

**Aplicação, Docker e cluster local**

Objetivo: executar a aplicação no Kubernetes.

### Semana 2 — 17/08 a 23/08

**Operação e resiliência Kubernetes**

Objetivo: implementar probes, requests/limits, Metrics Server, HPA e runbook.

### Semana 3 — 24/08 a 30/08

**Helm e gerenciamento de releases**

Objetivo: transformar os manifests em um Helm Chart e simular deploy e rollback.

### Semana 4 — 31/08 a 06/09

**Terraform e Infrastructure as Code**

Objetivo: automatizar e tornar reproduzível a preparação do ambiente.

### Semana 5 — 07/09 a 13/09

**Datadog e observabilidade**

Objetivo: integrar métricas, logs, traces, dashboards, alertas e SLO.

### Semana 6 — 14/09 a 20/09

**Game Day e post-mortem**

Objetivo: executar falhas controladas, medir MTTD/MTTR e documentar incidentes.

## Segurança e credenciais

Nenhuma credencial real deve ser versionada neste repositório.

Os seguintes itens não devem ser enviados ao GitHub:

- API Keys
- Application Keys
- tokens
- senhas
- arquivos `.env`
- arquivos `.tfvars` contendo valores reais
- arquivos `terraform.tfstate`
- chaves privadas
- Kubernetes Secrets contendo credenciais reais

Arquivos de exemplo poderão ser versionados desde que utilizem somente valores fictícios.

## Estrutura do repositório

```text
sre-incident-lab/
├── app/
├── cluster/
├── docs/
├── helm/
├── scenarios/
├── scripts/
├── terraform/
├── .github/
├── .gitignore
├── LICENSE
├── Makefile
└── README.md
```

## Status atual

- [x] WSL2 configurado
- [x] Toolchain local instalada e validada
- [x] Repositório Git e GitHub configurados
- [x] Cluster Kubernetes local criado
- [ ] API FastAPI
- [ ] Testes automatizados
- [ ] Dockerfile da aplicação
- [ ] Primeiro Deployment Kubernetes
- [ ] Helm Chart
- [ ] Automação com Terraform
- [ ] Observabilidade com Datadog
- [ ] Game Day

## Licença

Este projeto é disponibilizado sob a MIT License. Consulte o arquivo `LICENSE`.

## Status do projeto

🚧 Em desenvolvimento.
