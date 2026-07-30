# MedLink — Plano de Desenvolvimento e Escala

> Sistema de gestão de saúde para Moçambique. Este documento descreve a estratégia
> faseada: validar com Firebase, pilotar com clínicas pequenas, e preparar a
> migração para uma infraestrutura própria e segura à medida que escalamos.

**Estado do documento:** rascunho de trabalho · última revisão por discussão de equipa.

---

## 1. Visão

Disponibilizar o MedLink de forma fiável em todo Moçambique, respeitando usabilidade
em redes fracas e dispositivos modestos, segurança a nível de dados de saúde, e as
normas moçambicanas de proteção de dados.

## 2. Contexto legal (resumo)

> **Aviso:** este resumo não é aconselhamento jurídico. Antes do tratamento de dados
> reais de pacientes, e obrigatoriamente antes do rollout nacional, consultar um
> advogado moçambicano especializado.

- Em 2026 Moçambique **ainda não tem uma lei autónoma de proteção de dados em vigor**.
  A proteção assenta na Constituição, na Lei n.º 3/2017 (transações eletrónicas),
  em regulamentação setorial (Banco de Moçambique, INCM) e na Convenção de Malabo
  (ratificada em 2019).
- A **Proposta de Lei de Proteção de Dados Pessoais** foi aprovada pelo Conselho de
  Ministros em março de 2026 e aguarda votação na Assembleia da República. É
  inspirada no RGPD/Convenção 108+/Malabo, com um período transitório esperado.
- Dados de saúde são **dados sensíveis** — a categoria mais protegida. A futura lei
  deverá exigir: Encarregado de Proteção de Dados (DPO), avaliação de impacto (DPIA),
  notificação de violações, medidas técnicas (cifra, controlo de acessos, backups),
  registo de atividades de tratamento, privacy by design/by default, e consentimento
  informado e revogável. Supervisão pela futura ANPD.

**Implicação:** construímos desde já para o padrão que aí vem (nível RGPD), mesmo
usando Firebase. Privacidade retrofitada custa muito mais.

## 3. Princípio estratégico

Firebase **agora** (apresentação + pilotos), API própria e segura **depois** (escala).
A chave para isto não custar uma reescrita é a **disciplina de arquitetura**: a app
fala com repositórios; o backend por trás (Firebase hoje, API amanhã) pode trocar
sem a interface mudar. Ver `ARQUITETURA.md`.

## 4. Fases

### Fase 0 — Fundações (antes de mais funcionalidades)
Objetivo: pôr a casa em ordem para trabalho em equipa + Claude Code.
- [ ] Fluxo de git: branches por funcionalidade, `main` protegida, PRs com revisão.
- [ ] Remover backups `.zip` do repo e ignorar `*.zip` (feito no `.gitignore`).
- [ ] Confirmar que nenhum segredo sensível está no repo (chaves de *service account*
      nunca devem ser commitadas; as chaves Firebase de cliente não são secretas mas
      a segurança depende das regras do Firestore).
- [ ] Separar ambientes: `dev` / `staging` / `prod` (projetos Firebase distintos).
- [ ] Introduzir a **camada de repositórios** (refatorar os `services/` atuais).
- [ ] Definir o **modelo de consentimento** (que dados, para quê, por quanto tempo).

### Fase 1 — MVP para apresentação e aprovação
Objetivo: demonstração credível e sem falhas, com dados fictícios.
- [ ] Polir os fluxos principais (login, marcação, consulta, chat, avisos).
- [ ] Guião de demonstração ponta-a-ponta para a apresentação.
- [ ] Narrativa de conformidade e escala (este documento) pronta a apresentar.
- [ ] Risco: zero — sem dados reais de pacientes nesta fase.

### Fase 2 — Piloto com clínicas pequenas (dados reais)
Objetivo: validar em contexto real, com responsabilidade legal a sério.
- [ ] **Mínimo de segurança/privacidade do piloto** (ver secção 5) — não-negociável.
- [ ] Offline-first básico nos fluxos críticos.
- [ ] Acordo escrito com a(s) clínica(s) sobre tratamento de dados.
- [ ] Recolha de feedback estruturada.

### Fase 3 — Preparação para escala
Objetivo: deixar de depender só do Firebase para dados clínicos.
- [ ] Construir a **API própria + PostgreSQL** por trás da camada de repositórios.
- [ ] Storage cifrado para ficheiros de exames.
- [ ] Gateway de **SMS** para lembretes (rede fraca, telefones simples).
- [ ] Integração de pagamentos (M-Pesa, e-Mola, mKesh) via APIs oficiais.
- [ ] Observabilidade (logs, métricas, alertas) e testes de carga.
- [ ] **DPIA**, designação de **DPO**, política de privacidade e termos (revisão legal).
- [ ] **Pentest** antes de qualquer expansão.

### Fase 4 — Rollout nacional
- [ ] Expansão multi-região, suporte, monitorização contínua.
- [ ] Parcerias institucionais (ex.: MISAU) e requisitos de residência de dados.
- [ ] Localização (português + línguas locais conforme necessidade).

## 5. Checklist do mínimo de segurança e privacidade para o piloto

A partir do momento em que existe **um único paciente real**, isto aplica-se:

- [ ] **Regras de segurança do Firestore** fechadas: cada utilizador só acede ao que
      lhe pertence; sem isto, qualquer pessoa lê a base de dados inteira.
- [ ] **Firebase App Check** ativo (impede acesso à API a partir de apps não autorizadas).
- [ ] **MFA** para contas de médico e admin.
- [ ] **Consentimento informado** registado antes de recolher dados do paciente.
- [ ] **Logs de auditoria**: quem acedeu a que registo clínico e quando.
- [ ] **Cifra em trânsito** (TLS, por defeito) e em repouso.
- [ ] **Backups** automáticos e um restauro testado pelo menos uma vez.
- [ ] Processo simples de **resposta a incidentes** (quem faz o quê numa violação).
- [ ] Princípio da **minimização**: recolher só o estritamente necessário.

## 6. Decisões em aberto

- Requisito de residência/soberania de dados vindo de parceiro institucional? (define
  o timing da Fase 3).
- Provedor de SMS e de integração de pagamentos.
- Tecnologia exata da API própria (ver `ARQUITETURA.md` para a recomendação).
