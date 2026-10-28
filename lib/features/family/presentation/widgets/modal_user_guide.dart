import 'package:flutter/material.dart';
import 'package:kincare/core/theme/app_theme.dart';

class ModalUserGuide extends StatelessWidget {
  const ModalUserGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFFF5F5F5),
      contentPadding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, color: KinColors.text, size: 20),
            SizedBox(width: 6),
            Text(
              "Guia de Utilização",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: screenHeight * 0.70),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: Container(
            color: const Color(0xFFF5F5F5),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Who is Who
                  _buildGuideCard(
                    icon: Icons.people_outline,
                    title: "1. Perfis e Níveis de Acesso",
                    children: [
                      const Text(
                        "O KinCare estrutura as permissões operacionais em papéis definidos para garantir a integridade dos dados e a organização das rotinas:",
                        style: TextStyle(fontSize: 14, color: KinColors.text, height: 1.45),
                      ),
                      const SizedBox(height: 14),
                      _buildGuideTextRow(
                        "Administração (Admin)",
                        "Responsável pela gestão residencial. Possui controle cadastral sobre os membros, autoriza solicitações de acesso à despensa, emite pedidos de refeição, consome os itens produzidos pelo suporte e faz a gestão da localização dos itens no estoque/despensa.",
                      ),
                      _buildGuideTextRow(
                        "Suporte e Cozinha (Support)",
                        "Membros responsáveis pelo preparo e logística das refeições. Podem assumir pedidos pendentes, registrar iniciativas proativas de preparo e registrar entregas no estoque. O acesso integral ao inventário geral da despensa pode ser concedido temporariamente pela administração.",
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCEEAD6)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Segurança e Rastreabilidade",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF137333)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "O sistema adota o princípio de segurança por padrão. As operações no estoque e nos pedidos mantêm histórico dos autores de criação e modificação, impedindo a sobreposição inadvertida de registros.",
                              style: TextStyle(fontSize: 13, color: Color(0xFF137333), height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Section 2: Storage Panel
                  _buildGuideCard(
                    icon: Icons.kitchen_outlined,
                    title: "2. Diretrizes Técnicas de Armazenamento",
                    children: [
                      const Text(
                        "Ao cadastrar ou transferir um item, o sistema calcula a data de validade com base em parâmetros de boas práticas e vigilância sanitária. O inventário adota sinalização por cores para indicar prioridade de consumo:",
                        style: TextStyle(fontSize: 14, color: KinColors.text, height: 1.45),
                      ),
                      const SizedBox(height: 14),
                      const Text("DESPENSA (Temperatura Ambiente)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
                      const Divider(height: 16),
                      _buildGuideTextRow("Despensa (24h)", "Preparações prontas mantidas em temperatura ambiente. Exemplos: bolos secos sem recheio, biscoitos artesanais e pães em bancada."),

                      const SizedBox(height: 12),
                      const Text("GELADEIRA (Refrigeração)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
                      const Divider(height: 16),
                      _buildGuideTextRow("Sensível / Delicado (3 dias)", "Preparações com maior perecibilidade que demandam consumo rápido sob refrigeração. Exemplos: molhos com derivados de leite, pescados cozidos e saladas com maionese."),
                      _buildGuideTextRow("Padrão (5 dias)", "Refeições cozidas convencionais mantidas refrigeradas continuamente. Exemplos: carnes cozidas, grãos preparados e ensopados."),

                      const SizedBox(height: 12),
                      const Text("FREEZER (Congelamento)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
                      const Divider(height: 16),
                      _buildGuideTextRow("Pescados / Molhos (30 dias)", "Itens sensíveis ao congelamento ou bases líquidas. Exemplos: molhos caseiros porcionados e filés de peixe temperados."),
                      _buildGuideTextRow("Massas / Panificação (60 dias)", "Preparações de panificação e massas estruturadas prontas para cocção ou aquecimento. Exemplos: lasanhas, nhoques e pães integrais."),
                      _buildGuideTextRow("Preparações Cozidas (90 dias)", "Refeições completas porcionadas e congeladas imediatamente após o resfriamento. Exemplos: marmitas prontas, caldos e feijão cozido."),
                      _buildGuideTextRow("In natura / Vegetais (180 dias)", "Ingredientes congelados crus devidamente higienizados ou submetidos a branqueamento. Exemplos: cortes de carne crua e vegetais branqueados."),
                    ],
                  ),

                  // Section 3: Food States
                  _buildGuideCard(
                    icon: Icons.swap_horiz_outlined,
                    title: "3. Entendendo os Estados da Comida",
                    children: [
                      const Text(
                        "Para os responsáveis pela cozinha, cada alimento percorre etapas cruciais no inventário:",
                        style: TextStyle(fontSize: 14, color: KinColors.text, height: 1.45),
                      ),
                      const SizedBox(height: 14),
                      _buildGuideTextRow(
                          "Armário / Geladeira / Freezer",
                          "Indica a localização física atual do alimento no estoque."
                      ),
                      _buildGuideTextRow(
                          "Descongelado / Descongelando",
                          "Indica que o item saiu do freezer e está em processo de degelo ou já descongelado na geladeira. Monitoramento sanitário essencial para garantir a segurança alimentar."
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE8E6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFAD2CF)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Color(0xFFC5221F), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  "Recongelado - Atenção Redobrada",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC5221F)),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Múltiplos ciclos de recongelamento alteram a integridade celular e aumentam a carga microbiológica. Por isso, a cada ciclo de recongelamento, o sistema reduz o prazo remanescente do lote e exige atenção redobrada quanto ao consumo prioritário.",
                              style: TextStyle(fontSize: 13, color: Color(0xFFC5221F), height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

// Section 4: Order Flows
                  _buildGuideCard(
                    icon: Icons.assignment_outlined,
                    title: "4. Fluxos de Solicitação e Entrega",
                    children: [
                      const Text(
                        "O ciclo de atendimento e preparo de refeições contempla três fluxos operacionais:",
                        style: TextStyle(fontSize: 14, color: KinColors.text, height: 1.45),
                      ),
                      const SizedBox(height: 14),

                      // Flow 1: Regular Request Pipeline
                      _buildGuideTextRow(
                        "1. Fluxo Regular de Pedidos",
                        "Solicitações criadas por membros da família, percorrendo uma esteira estruturada de quatro etapas até a conclusão:",
                      ),
                      const SizedBox(height: 6),
                      Container(
                        margin: const EdgeInsets.only(left: 8, bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE9ECEF)),
                        ),
                        child: Column(
                          children: [
                            _buildGuideStatusRow(
                              Icons.mail_outline,
                              "Solicitado",
                              "O pedido é registrado pelo membro e entra na fila da cozinha como pendente.",
                            ),
                            _buildGuideStatusRow(
                              Icons.check_circle_outline,
                              "Aceito",
                              "Um responsável assume o preparo da solicitação.",
                            ),
                            _buildGuideStatusRow(
                              Icons.soup_kitchen_outlined,
                              "Em Preparo",
                              "A refeição está em processo ativo de produção.",
                            ),
                            _buildGuideStatusRow(
                              Icons.inventory_2_outlined,
                              "Entrega",
                              "O prato é finalizado, tem o local e validade definidos e dá entrada oficial no estoque.",
                            ),
                          ],
                        ),
                      ),

                      // Flow 2: Proactive Cooking
                      _buildGuideTextRow(
                        "2. Iniciativa Própria de Preparo",
                        "Quando os responsáveis pela cozinha decidem preparar um lote de forma voluntária, permitindo a entrada direta do item no estoque sem solicitação prévia.",
                      ),

                      // Flow 3: Discrete/Surprise Preparation
                      _buildGuideTextRow(
                        "3. Preparo Surpresa (Mimo)",
                        "Destinado a carinhos e mimos culinários preparados em segredo. Mantém o item oculto da visualização dos membros até a entrega final, garantindo que o gesto surpresa seja uma boa experiência. ",
                      ),
                    ],
                  ),

                  // Section 5: Mutation Timeframes
                  _buildGuideCard(
                    icon: Icons.schedule_outlined,
                    title: "5. Janela de Edição e Cancelamento",
                    children: [
                      _buildGuideTextRow(
                        "Período de Correção",
                        "Após registrar uma solicitação ou preparo, o usuário dispõe de uma janela de 3 (três) horas para retificar dados cadastrais como descrição e parâmetros iniciais.",
                      ),
                      _buildGuideTextRow(
                        "Exclusão de Solicitações",
                        "Caso uma preparação não possa ser executada ou o pedido precise ser cancelado antes de entrar em preparo, o registro pode ser removido pelo autor diretamente no card correspondente.",
                      ),
                    ],
                  ),

                  // Section 6: Notifications and Alerts
                  _buildGuideCard(
                    icon: Icons.notifications_none_outlined,
                    title: "6. Notificações e Alertas (Roadmap)",
                    children: [
                      const Text(
                        "O ecossistema conta com pipeline de mensageria desenhado para manter os usuários informados sobre prazos e status operacionais:",
                        style: TextStyle(fontSize: 14, color: KinColors.text, height: 1.45),
                      ),
                      const SizedBox(height: 14),

                      // Profile: Admin
                      const Text(
                        "FLUXOS ADMINISTRATIVOS",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5),
                      ),
                      const Divider(height: 16),
                      _buildGuideTextRow(
                        "Andamento de Solicitações",
                        "Alertas em tempo real quando pedidos são aceitos, entram em preparo ou são entregues.",
                      ),
                      _buildGuideTextRow(
                        "Alertas de Validade",
                        "Avisos automáticos quando itens do estoque atingem o limiar de consumo prioritário ou prazo de validade expirado.",
                      ),
                      _buildGuideTextRow(
                        "Gestão de Acessos",
                        "Avisos de novos cadastros pendentes de aprovação e solicitações pontuais de liberação da despensa.",
                      ),

                      const SizedBox(height: 12),

                      // Profile: Support
                      const Text(
                        "FLUXOS DE COZINHA E SUPORTE ",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5),
                      ),
                      const Divider(height: 16),
                      _buildGuideTextRow(
                        "Novas Demandas",
                        "Notificações instantâneas quando novos pedidos são registrados pelos membros da residência.",
                      ),

                      const SizedBox(height: 6),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD2E3FC)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Color(0xFF1967D2), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  "Nota de Arquitetura",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1967D2)),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              "As regras de negócio, tópicos FCM e rotinas agendadas foram desenvolvidos no ambiente de produção privado. Nesta versão pública e demonstrativa, os triggers de cloud functions e mensageria push permanecem desacoplados para manter o repositório 100% autônomo e sem custos fixos de infraestrutura.",
                              style: TextStyle(fontSize: 13, color: Color(0xFF1967D2), height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Section 7: Recovery
                  _buildGuideCard(
                    icon: Icons.lock_reset_outlined,
                    title: "7. Redefinição de Senha",
                    children: [
                      _buildGuideTextRow(
                        "Procedimento de Recuperação",
                        "A redefinição de credenciais pode ser feita pela opção de segurança na tela Conta ou diretamente na tela de autenticação do aplicativo. O sistema enviará um link de validação para o e-mail cadastrado.",
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9E6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFE599)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.mark_email_unread_outlined, color: Color(0xFFB78103), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Verificação de Caixa de Mensagens:\nCaso o link de alteração não chegue à Caixa de Entrada em até 2 minutos, verifique as pastas de Spam ou Lixo Eletrônico do provedor de e-mail.",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF7F5A01), height: 1.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 4),
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Builder(
        builder: (context) => Theme(
          data: ThemeData().copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(icon, color: KinColors.text, size: 22),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: KinColors.text, fontSize: 14)),
            iconColor: Colors.grey,
            collapsedIconColor: Colors.grey,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildGuideTextRow(String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: KinColors.text)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.45)),
        ],
      ),
    );
  }

  Widget _buildGuideStatusRow(IconData icon, String status, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: KinColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: KinColors.text, height: 1.45),
                children: [
                  TextSpan(text: "$status: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}