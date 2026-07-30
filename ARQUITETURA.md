# MedLink — Arquitetura Técnica

> Como o código está organizado, e como o desacoplamos do Firebase para que a
> migração futura para uma API própria seja barata em vez de ser uma reescrita.

---

## 1. Stack atual

- **Flutter / Dart** — app multiplataforma (mantém-se; boa escolha para Android de gama baixa).
- **Firebase Auth** — autenticação.
- **Cloud Firestore** — base de dados.
- **Provider** — gestão de estado.
- **device_preview** — pré-visualização em dev.

Organização em `lib/tl_2/`: `models/`, `services/`, `providers/`, `views/`, `core/`.

## 2. Princípio central: desacoplar o backend

Hoje os `services/` falam diretamente com `FirebaseFirestore.instance`. Isto funciona,
mas prende a app ao Firebase. A mudança estrutural é introduzir **interfaces de
repositório**: a app depende da interface, não da implementação.

```
┌─────────────────────────────────────────────┐
│  Views (UI)                                   │
│     ↓ lê estado de                            │
│  Providers (AuthProvider, ...)                │
│     ↓ chamam                                  │
│  Repositórios — INTERFACES (abstract)         │  ← a app só conhece isto
│     ↑ implementadas por                       │
│  ┌──────────────────┐   ┌──────────────────┐  │
│  │ Firebase (hoje)  │   │ API própria      │  │  ← troca-se aqui, sem
│  └──────────────────┘   │ (amanhã)         │  │     mexer em cima
│                         └──────────────────┘  │
└─────────────────────────────────────────────┘
```

A regra de ouro: **detalhes do Firestore nunca aparecem nas views nem nos providers.**
`QuerySnapshot`, `DocumentReference`, `collection('...')` vivem só dentro das
implementações de repositório.

## 3. Como refatorar (incremental, sem parar tudo)

O objetivo não é reescrever — é mover os `services/` atuais para trás de interfaces.

**Passo 1 — Definir a interface.** Para cada service, criar um abstract correspondente
em `lib/tl_2/repositories/`:

```dart
// lib/tl_2/repositories/consulta_repository.dart
abstract class ConsultaRepository {
  Future<String?> marcarConsulta(Consulta c);
  Stream<List<Consulta>> consultasActivasPaciente(String uid);
  Stream<List<Consulta>> consultasActivasMedico(String uid);
  Future<void> actualizarEstado(String id, String estado, {/* ... */});
  // ... a mesma assinatura que o ConsultaService já tem
}
```

**Passo 2 — A implementação Firebase é o service atual.** Renomear/mover o
`ConsultaService` para `lib/tl_2/repositories/firebase/firebase_consulta_repository.dart`
e fazê-lo implementar a interface:

```dart
class FirebaseConsultaRepository implements ConsultaRepository {
  final _db = FirebaseFirestore.instance;
  // ... o corpo é exatamente o que já existe hoje
}
```

**Passo 3 — Injetar a implementação num só sítio.** No `main.dart`, escolher qual
implementação usar. Amanhã, trocar uma linha aponta tudo para a API:

```dart
// um ponto único de decisão
final ConsultaRepository consultaRepo = FirebaseConsultaRepository();
// futuro: final ConsultaRepository consultaRepo = ApiConsultaRepository(baseUrl: ...);
```

**Passo 4 — Providers recebem a interface.** O `AuthProvider` (e futuros providers)
passam a depender de `ConsultaRepository`, não de `ConsultaService` concreto.

Repetir por domínio: `AuthRepository`, `ConsultaRepository`, `ChatRepository`,
`DisponibilidadeRepository`, `HistoricoRepository`, `UtilizadorRepository`.

> Nota: já existe um `ConsultaServiceInterface` em `core/tema.dart`. Faz sentido movê-lo
> para `repositories/` e consolidar com o esquema acima — a interface não deve viver no
> ficheiro de tema.

## 4. Modelo de dados (coleções Firestore atuais)

| Coleção           | Conteúdo                                                      |
|-------------------|--------------------------------------------------------------|
| `utilizadores`    | perfil (nome, email, tipo, telefone, idade, especialização)  |
| `consultas`       | marcação, estado, diagnóstico, exames, pagamento             |
| `avisos`          | notificações por destinatário (lido/não lido)                |
| `disponibilidade` | horários do médico por dia da semana                         |
| `medicamentos`    | prescrições ligadas a paciente/consulta                      |
| `mensagens`       | chat (chatId derivado dos dois uids ordenados)               |

Esta estrutura mapeia de forma limpa para tabelas relacionais (PostgreSQL) quando
chegar a API própria — cada coleção vira uma tabela, com chaves estrangeiras nos `*Id`.

## 5. Estratégia de migração Firebase → API própria

1. Manter as interfaces de repositório estáveis (Fases 0–2).
2. Construir a API (REST ou GraphQL) + PostgreSQL com o mesmo modelo de dados.
3. Criar `Api*Repository` que implementa as mesmas interfaces.
4. Migrar os dados existentes (script de exportação Firestore → PostgreSQL).
5. Trocar a injeção no `main.dart`, idealmente por domínio (migração gradual).
6. **Auth:** decidir entre manter Firebase Auth e validar tokens na API, ou migrar
   para uma solução própria (ex.: Keycloak/Ory). Recomenda-se manter Firebase Auth
   no início para reduzir risco.

## 6. Segurança

- **Regras do Firestore** (Fase 2, antes de dados reais): um paciente só lê/escreve
  os seus documentos; um médico só acede aos pacientes com quem tem consulta; admin
  com escopo controlado. Sem regras adequadas, a base de dados fica aberta.
- **App Check** para impedir acesso a partir de clientes não autorizados.
- **Logs de auditoria** de acesso a registos clínicos (coleção/tabela própria de
  auditoria — quem, o quê, quando).
- **Segredos:** nunca commitar chaves de *service account*. As chaves de cliente em
  `firebase_options.dart` não são segredas, mas a segurança depende das regras acima.
- **Cifra** em trânsito (TLS) e em repouso.

## 7. Usabilidade e offline-first

- Rede fraca/intermitente é a norma — os fluxos críticos (marcar consulta, ver avisos)
  devem funcionar offline e sincronizar depois. O Firestore tem persistência offline
  que ajuda no início; a API própria precisará de uma fila de sincronização explícita.
- Payloads pequenos, app leve, suporte a Android antigo.
- **SMS** para lembretes (não depender só de push/internet).
- Português primeiro; línguas locais conforme a expansão.

## 8. O que NÃO mudar agora

- Flutter — mantém-se.
- Provider — suficiente para já; reavaliar só se o estado crescer muito.
- Firebase — mantém-se para Fases 0–2; a camada de repositórios é o que permite trocar
  depois sem dor.
