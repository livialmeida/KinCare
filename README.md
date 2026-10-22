# KinCare 🌿

> **Household Inventory & Pantry Lifecycle Management**  
> Aplicação progressiva multiplataforma (foco Web/PWA) desenvolvida com **Flutter** e **Firebase**, projetada sob princípios rigorosos de **Security by Design**, conformidade com normas sanitárias e controle de acesso baseado em funções (RBAC).

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Spark%20Plan-FFCA28?logo=firebase)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 🚀 Demonstração Online & Controle de Acesso (RBAC)

A aplicação está disponível em produção via Firebase Hosting:  
👉 **[kincare-9b1d4.web.app](https://kincare-9b1d4.web.app)**

Para avaliar a arquitetura de permissões (*Role-Based Access Control*), utilize as contas de demonstração pré-configuradas ou crie sua própria credencial:

| Perfil | E-mail | Senha | Capacidades & Escopo |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin.demo@kincare.app` | `DemoPassword2026!` | Gestão completa de estoque, descarte sanitário, auditoria e aprovação de novos membros |
| **Support** | `support.demo@kincare.app` | `DemoPassword2026!` | Registro de itens próprios, pedidos familiares e solicitação de acesso temporário à despensa |
| **Pending** | `pending.demo@kincare.app` | `DemoPassword2026!` | Conta demonstrativa bloqueada para simulação da triagem de segurança (*Read-Only*) |

---

### 🧪 Teste Interativo do Ciclo Completo (Triagem + LGPD)

Caso deseje testar a esteira completa de segurança e ciclo de vida de dados:

1. **Auto-registro:** Cadastre-se normalmente no formulário de registro da aplicação.
2. **Triagem de Segurança:** Sua conta nascerá estritamente com o status `pending` validado por regras atômicas do Firestore.
3. **Aprovação em Tempo Real:** Em outra aba/navegador, autentique-se como `admin.demo@kincare.app` e autorize o usuário recém-criado.
4. **Privacidade & Direito ao Esquecimento (LGPD/GDPR):** Ao concluir os testes, acesse **Configurações da Conta > Excluir Minha Conta** para expurgar imediatamente suas credenciais do Firebase Authentication e seus dados do Cloud Firestore.

---

## 🛡️ Arquitetura & Security by Design

* **Princípio do Menor Privilégio (PoLP):** Regras de segurança no Firestore garantem que usuários `pending` não possuam permissão de leitura ou escrita em coleções operacionais (`stock`, `orders`, `food_history`).
* **Blindagem de Contas Demo:** Contas demonstrativas de sistema possuem regras imutáveis a nível de banco de dados, impedindo alterações acidentais de permissão ou exclusões indevidas.
* **Governança de Credenciais:** O repositório não expõe chaves privadas, tokens ou arquivos de serviço de backend. A chave de API web opera com restrições explícitas de **Referenciadores HTTP** (`kincare-9b1d4.web.app`) e restrições de escopo de serviço.
* **Otimização Spark Plan:** Toda a arquitetura foi desenhada para operação 100% serverless sem necessidade de Cloud Functions pagas, utilizando regras de segurança do Firestore, índices compostos enxutos e streams reativas do Flutter.

---

## 📦 Funcionalidades Principais

* **Gestão de Validade e Estoque:** Monitoramento de shelf-life com triagem visual preventiva e registros de auditoria em histórico imutável (`food_history`).
* **Descarte Sanitário Responsivo:** Fluxo não bloqueante com confirmação atômica e feedback contextual sem travamento de interface.
* **Solicitações de Despensa:** Membros do perfil `support` possuem controle de acesso temporário condicional via solicitações aprovadas por administradores.
* **PWA & Instalação Móvel:** Suporte nativo para Web com atalhos de instalação (Add to Home Screen) e guia adaptado para Safari (iOS) e Chrome (Android/Desktop).

---

## 🛠️ Tecnologias Utilizadas

* **Frontend:** Flutter Web (Dart) com gerenciamento de estado via `Provider`.
* **Backend as a Service:** Firebase Authentication, Cloud Firestore e Firebase Hosting.
* **Design & UI:** Design minimalista claro (Light Theme), tipografia acessível e paleta suave focada em legibilidade e usabilidade.

---

## 💻 Como Rodar o Projeto Localmente

### Pré-requisitos
* Flutter SDK (versão estável mais recente)
* Dart SDK
* Firebase CLI instalado e logado (`firebase login`)

### Configuração Passo a Passo

1. **Clone o repositório:**
   git clone https://github.com/SEU_USUARIO/kincare.git
   cd kincare

2. **Instale as dependências:**
   flutter pub get

3. **Configure as credenciais do Firebase:**
    * Crie uma cópia do arquivo de exemplo:
      cp lib/firebase_options.dart.example lib/firebase_options.dart
    * Preencha com as credenciais do seu projeto Firebase ou configure automaticamente via FlutterFire CLI:
      flutterfire configure

4. **Execute localmente no navegador:**
   flutter run -d chrome

---

## 📄 Licença

Este projeto é protegido por direitos autorais. O código-fonte está disponível publicamente exclusivamente para fins de visualização técnica e portfólio. Todos os direitos reservados. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.