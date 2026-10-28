# 🏛️ KinCare — Architecture & Technical Specifications

Este documento formaliza as decisões de arquitetura de software, especificações técnicas de negócio e trade-offs operacionais adotados no desenvolvimento do **KinCare**. Ele serve como registro de engenharia para justificar escolhas técnicas, delimitar o escopo demonstrativo e garantir a separação clara entre a camada de apresentação e os contratos de infraestrutura.

---

## 1. Visão Geral da Arquitetura

O KinCare adota uma arquitetura **Serverless Client-Centric**, priorizando alta reatividade no frontend sem dependência de middlewares pagos para execução em ambiente demonstrativo:

```text
┌────────────────────────────────────────────────────────┐
│                   Flutter Web / PWA                    │
│      (State Management: Provider | Clean Layering)     │
└───────────────┬────────────────────────▲───────────────┘
                │                        │
       Atomic Writes / Streams   Live Query Listeners
                │                        │
┌───────────────▼────────────────────────┴───────────────┐
│              Google Cloud Firestore                    │
│   - Security Rules (RBAC + Field Validation)           │
│   - Online-First Session Synchronization               │
│   - Composite Indexes (Shelf-life & Priority)          │
└────────────────────────────────────────────────────────┘
```

* **Frontend:** Flutter Web estruturado com gerenciamento de estado reativo via `Provider`, separação de contratos de repositório e UI neutra e acessível em tema claro.
* **Estratégia de Conectividade:** Operação *online-first* otimizada para Web/PWA, utilizando gerenciamento de estado volátil em memória e listeners reativos. Esse modelo elimina riscos de concorrência por dados obsoletos (*stale cache*) entre múltiplos usuários simultâneos no mesmo inventário.
* **Segurança e Regras de Negócio:** Centralizadas em regras atômicas no Firestore Security Rules, garantindo validação de esquema, tipos e controle de acesso direto na borda do banco de dados.

---

## 2. Architecture Decision Records (ADR)

### ADR 001: Desacoplamento da Mensageria Push e Cloud Functions

* **Status:** Aprovado / Implementado
* **Data:** 2026

#### Contexto
No ecossistema de produção privado de referência, o ciclo operacional de refeições e a vigilância do estoque contam com notificações push em tempo real (FCM) acionadas por gatilhos em nuvem:
* **Gatilhos de Evento (Eventarc / Cloud Functions v2):** Disparo de notificações push a cada alteração na máquina de estados de pedidos (`orders`: `pending` ➔ `accepted` ➔ `preparing` ➔ `delivered`).
* **Rotina Agendada (Cloud Scheduler):** Varredura diária no inventário (`stock`) às 08:00 BRT, avaliando prazos de validade (`expiryDate`) e disparando alertas para o tópico administrativo `admin_stock_alerts` nos limiares de 7 dias, 3 dias, 24 horas e itens já vencidos.

Para viabilizar a publicação do KinCare como software de demonstração aberto e portfólio de engenharia, a dependência obrigatória de serviços que exigem o plano faturado (*Blaze Tier*) representava um custo fixo desnecessário e barreira de reprodutibilidade por terceiros.

#### Decisão
Desacoplou-se a infraestrutura de Cloud Functions e mensageria push externa no KinCare. A sincronização de dados e os alertas visuais foram absorvidos inteiramente pelo cliente:
1. **Sincronização de Pedidos:** Operada via `StreamProvider` diretamente nas coleções do Firestore, atualizando as interfaces de administração e cozinha instantaneamente sem necessidade de notificações push intermediárias.
2. **Monitoramento de Validade:** Implementado via triagem visual semafórica calculada de forma declarativa pelo Flutter com base na data de expiração (`expiryDate`) e parâmetros sanitários regulamentares.

#### Consequências & Trade-offs (FinOps)

| Dimensão | Pipeline com Backend Serverless (Privado) | Pipeline Desacoplado no Cliente (KinCare) |
| :--- | :--- | :--- |
| **Plano Firebase** | Requer *Blaze Plan* (faturamento ativo para instâncias Cloud Functions e Cloud Scheduler). | Opera estritamente no **Spark Plan** (100% gratuito). |
| **Custo de Manutenção** | Custo operacional fixo/recorrente por computação serverless e agendador em nuvem. | **Custo marginal zero** para portfólio permanente. |
| **Deploy & Execução** | Requer deploy de backend, variáveis de ambiente seguras e chaves de serviço privadas. | Repositório autônomo: basta clonar e executar com credenciais públicas de cliente. |
| **Experiência em Background** | Notificações do sistema operacional mesmo com o app fechado. | Feedbacks operacionais concentrados durante a sessão ativa do usuário. |

---

### ADR 002: Controle de Acesso Baseado em Funções (RBAC) via Firestore Security Rules

* **Status:** Aprovado / Implementado
* **Data:** 2026

#### Contexto
A aplicação possui três perfis de usuários com privilégios distintos: `admin`, `support` e `pending`. A integridade dos dados sanitários e cadastrais não pode depender de verificações exclusivas no frontend (vulneráveis a inspeção ou requisições forjadas via console).

#### Decisão
Impor o modelo de menor privilégio (*Principle of Least Privilege - PoLP*) diretamente nas regras de segurança do Firestore:
* Usuários com status `pending` possuem bloqueio total de leitura e escrita nas coleções operacionais (`stock`, `orders`, `food_history`).
* Apenas o perfil `admin` possui permissão para aprovar novos membros, alterar papéis e registrar baixas por descarte sanitário.
* Contas demonstrativas de sistema possuem regras imutáveis de escrita para evitar adulteração de papéis ou exclusões que quebrem a experiência de novos avaliadores.

---

### ADR 003: Estratégia de Distribuição via Web/PWA e Viabilidade de Plataforma

* **Status:** Aprovado / Implementado
* **Data:** 2026

#### Contexto
Embora o ecossistema tenha sido desenvolvido em **Flutter** — conferindo capacidade técnica nativa para geração de binários móveis (APK/AAB para Android e IPA para iOS) —, a estratégia de distribuição para o KinCare demandava avaliar custos fixos de manutenção, atrito de acesso para avaliadores e velocidade de ciclo de vida do software.

A entrega de notificações push nativas para o ecossistema iOS via APNs (*Apple Push Notification service*) impõe a contratação obrigatória da anuidade do *Apple Developer Program* (USD 99/ano), além de taxas recorrentes de publicação em lojas fechadas. Paralelamente, a distribuição de arquivos binários manuais (*sideloading*) impõe barreiras de segurança e alta fricção de teste para recrutadores e avaliadores técnicos.

#### Decisão
Adotou-se a distribuição primária como **Progressive Web App (PWA)** hospedado no Firebase Hosting, priorizando execução web de alto desempenho e instalação facilitada na tela de início (*Add to Home Screen*):
1. **Ciclo de Atualização Contínuo e Instantâneo:** As correções de regras de negócio, patches de segurança e refinamentos de interface entram em produção imediatamente via CI/CD e Firebase Hosting, eliminando tempos de esteira de revisão (*app review*) e fragmentação de versões entre usuários.
2. **Acessibilidade Imediata para Avaliação:** Elimina barreiras de instalação de pacotes não verificados; qualquer avaliador pode inspecionar o produto em produção diretamente pelo navegador em Desktop, Android ou iOS.
3. **Governança de Custos de Ecossistema:** Evita taxas compulsórias de licenciamento de contas de desenvolvedor corporativas em projetos concebidos para exibição técnica e código aberto.

#### Consequências & Trade-offs

| Dimensão | Distribuição em Lojas Fechadas (Google Play / App Store) | Distribuição Progressiva (Web / PWA) |
| :--- | :--- | :--- |
| **Custos de Licenciamento** | USD 99 anuais (Apple) + taxa de cadastro (Google Play). | **Custo zero** de publicação e distribuição contínua. |
| **Tempo de Propagação de Patches** | Horas a dias dependendo da revisão da loja e ação do usuário para atualizar. | **Instantâneo (Over-the-Air):** aplicação sempre na versão mais recente a cada carregamento. |
| **Push no iOS** | Nativo via APNs, dependente de certificações e credenciais pagas de dev. | Requer atalho na tela inicial (iOS 16.4+) com limitações de segundo plano em ambientes não faturados. |
| **Atrito de Acesso ao Portfólio** | Alto: exige download, permissões de instalação ou busca na loja. | **Zero:** URL pública direta com suporte opcional a instalação na tela de início. |

---

## 3. Especificação do Ciclo Sanitário de Estoque

A lógica de cálculo de validade e estados de armazenamento segue rigorosamente as diretrizes técnicas de boas práticas de manipulação:

### Matriz de Shelf-Life (`daysValid`)

| Localização Física | Categoria / Sensibilidade | Prazo Regulamentar |
| :--- | :--- | :--- |
| **Despensa / Ambiente** | Preparações secas / prontas para consumo | 24 horas |
| **Refrigeração (Geladeira)** | Itens de alta perecibilidade (pescados, bases lácteas) | 3 dias |
| **Refrigeração (Geladeira)** | Preparações padrão cozidas (grãos, carnes cozidas) | 5 dias |
| **Congelamento (Freezer)** | Molhos porcionados e pescados | 30 dias |
| **Congelamento (Freezer)** | Massas estruturadas e panificação | 60 dias |
| **Congelamento (Freezer)** | Refeições cozidas convencionais | 90 dias |
| **Congelamento (Freezer)** | In natura / vegetais branqueados | 180 dias |

### Regra de Degradação por Recongelamento (`refrozen`)
O ciclo de descongelamento e recongelamento altera a integridade celular e acelera a proliferação microbiológica.
* Quando um item retorna ao estado de congelamento após manipulação ou degelo, o sistema aplica uma redução proporcional sobre o prazo remanescente do lote e ativa sinalização prioritária na interface.

---

## 4. Governança de Dados, Auditoria e Privacidade (LGPD)

1. **Rastreabilidade de Ações:**
    * Nenhum documento operacional é anônimo. Os registros contêm campos de autoria técnica (`creatorId`, `authorId`, `createdAt`), permitindo auditoria clara de quem produziu, solicitou ou consumiu o lote.
2. **Histórico Imutável de Auditoria Sanitária (`food_history`):**
    * Baixas de estoque não utilizam exclusão física cega. As transições para consumo ou descarte sanitário alimentam um log contínuo, preservando o histórico de segurança alimentar da residência.
3. **Direito ao Esquecimento e Anonimização:**
    * O fluxo de exclusão de conta remove atômica e irreversivelmente as credenciais de autenticação (`Firebase Auth`) e o documento de perfil (`users/{uid}`), expurgando os dados de identificação pessoal (PII).
    * Os logs históricos operacionais são preservados de forma desassociada da identidade civil, garantindo a integridade dos relatórios de estoque em conformidade com o Artigo 16 da LGPD.