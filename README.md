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
