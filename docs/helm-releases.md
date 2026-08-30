# Helm Releases — SRE Incident Lab

Este documento registra as decisões de empacotamento, parametrização e gerenciamento de releases da Incident API utilizando Helm.

## Objetivo

O Helm foi introduzido no laboratório para substituir o gerenciamento manual dos manifests Kubernetes e permitir:

- parametrização de ambientes;
- releases versionadas;
- upgrades reproduzíveis;
- histórico de alterações;
- rollback para versões estáveis.

---

## Estrutura do Chart

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

`values.yaml` contém os valores padrão do chart.

Os arquivos adicionais permitem alterar o comportamento da release sem modificar os templates.

---

## Perfil local

Arquivo:

```text
values-local.yaml
```

Características:

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

Esse perfil é utilizado para execução local com menor consumo de recursos.

---

## Perfil stress

Arquivo:

```text
values-stress.yaml
```

Características:

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

Esse perfil é utilizado nos exercícios de carga e autoscaling.

---

## Validação do Chart

O chart foi validado utilizando:

```bash
helm lint helm/incident-api
```

Renderização:

```bash
helm template incident-api \
  helm/incident-api \
  --namespace sre-lab \
  -f helm/incident-api/values-stress.yaml
```

Também foi realizado `dry-run` contra o Kubernetes API Server.

Durante a migração dos manifests manuais para Helm, foi identificado que o Deployment existente utilizava um `spec.selector` diferente daquele gerado pelo chart.

O Kubernetes rejeitou a alteração porque o selector de um Deployment é imutável.

A aplicação foi então migrada de maneira controlada para uma release gerenciada pelo Helm.

---

## Instalação e upgrade

A mesma operação pode instalar ou atualizar a release:

```bash
helm upgrade --install incident-api \
  helm/incident-api \
  --namespace sre-lab \
  -f helm/incident-api/values-local.yaml \
  --wait
```

A primeira instalação gerou:

```text
Revision 1
Profile: local
Status: deployed
```

Posteriormente foi realizado upgrade para:

```text
Revision 2
Profile: stress
Status: deployed
```

---

## Histórico de Releases

O histórico pode ser consultado com:

```bash
helm history incident-api -n sre-lab
```

Durante o laboratório foram geradas:

```text
Revision 1 — instalação com perfil local
Revision 2 — upgrade para perfil stress
Revision 3 — deploy defeituoso
Revision 4 — rollback para revision 2
```

---

## Simulação de deploy defeituoso

Uma release propositalmente inválida foi criada através de override temporário:

```bash
helm upgrade incident-api \
  helm/incident-api \
  --namespace sre-lab \
  -f helm/incident-api/values-stress.yaml \
  --set image.tag=0.3.0-broken \
  --set image.pullPolicy=Never \
  --wait \
  --timeout 45s
```

O Kubernetes não encontrou a imagem:

```text
incident-api:0.3.0-broken
```

e registrou:

```text
ErrImageNeverPull
```

O Helm encerrou a operação com:

```text
Revision 3
Status: failed
```

Durante a falha, o Pod da revision anterior permaneceu saudável e disponível.

Isso demonstrou o comportamento de RollingUpdate: o Kubernetes não removeu a instância saudável enquanto a nova versão ainda não estava Ready.

---

## Rollback

A revision estável anterior era a revision 2.

O rollback foi executado com:

```bash
helm rollback incident-api 2 \
  --namespace sre-lab \
  --wait \
  --timeout 2m
```

Resultado:

```text
Revision 3 — failed
Revision 4 — deployed
Description: Rollback to 2
```

O comando de rollback foi concluído em aproximadamente:

```text
16 segundos
```

Esse valor representa o tempo entre o início do comando de rollback e a confirmação de conclusão pelo Helm.

Não representa tempo total de indisponibilidade da aplicação, pois o Pod saudável da revision anterior permaneceu disponível durante o rollout defeituoso.

---

## Estratégia de Secrets

Credenciais reais não são armazenadas no chart.

O padrão é:

```yaml
secret:
  create: false
```

O Deployment referencia um Secret Kubernetes externo.

O template de Secret pode ser habilitado apenas quando necessário e foi validado utilizando valores fictícios.

Nenhuma chave ou credencial real deve ser versionada no Git.

---

## Comandos operacionais

Listar releases:

```bash
helm list -n sre-lab
```

Status:

```bash
helm status incident-api -n sre-lab
```

Histórico:

```bash
helm history incident-api -n sre-lab
```

Upgrade:

```bash
helm upgrade --install incident-api \
  helm/incident-api \
  --namespace sre-lab \
  -f helm/incident-api/values-stress.yaml
```

Rollback:

```bash
helm rollback incident-api <revision> \
  -n sre-lab
```

---

## Aprendizados

A utilização do Helm mostrou que uma release não é apenas um conjunto de manifests Kubernetes.

O Helm adiciona uma camada de gerenciamento de estado e histórico que permite saber:

```text
o que foi instalado
↓
o que mudou
↓
qual revision falhou
↓
qual revision estava saudável
↓
para qual estado fazer rollback
```

O principal aprendizado do exercício foi que uma alteração pode falhar sem necessariamente causar indisponibilidade completa.

O estado do rollout, a disponibilidade dos Pods e o histórico da release precisam ser analisados em conjunto antes de concluir o impacto de um incidente.
