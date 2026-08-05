# SRE Incident Lab

Laboratório prático voltado ao desenvolvimento de competências em SRE,
Kubernetes, Helm, Terraform e Datadog.

## Objetivo

Construir e operar uma aplicação containerizada em Kubernetes, utilizando
infraestrutura como código, gerenciamento de releases e observabilidade.

O laboratório será utilizado para simular cenários como:

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

- Python e FastAPI
- Docker
- Kubernetes
- kind
- Helm
- Terraform
- Datadog

## Status

🚧 Projeto em desenvolvimento.

## Roadmap

- [ ] Preparar o ambiente local
- [ ] Criar a aplicação
- [ ] Criar a imagem Docker
- [ ] Criar o cluster Kubernetes
- [ ] Implantar a aplicação
- [ ] Configurar probes e recursos
- [ ] Criar o chart Helm
- [ ] Automatizar a plataforma com Terraform
- [ ] Integrar com Datadog
- [ ] Executar o Game Day
- [ ] Produzir runbook e post-mortem
