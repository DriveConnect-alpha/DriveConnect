// EXEMPLO DE COMO USAR OS NOVOS WIDGETS DE CHAT
// Este arquivo mostra como implementar os componentes reutilizáveis

import 'package:flutter/material.dart';
import '../widgets/chat_bubble.dart';
import '../models/whatsapp_message.dart';

/// Exemplo completo de como usar os novos widgets de chat
/// Este padrão pode ser aplicado em qualquer tela de conversa
class ChatScreenExample {
  /// Exemplo 1: Renderizando lista de mensagens com ChatBubble
  static Widget buildChatList(List<WhatsAppMessage> messages, ScrollController controller) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isIncoming = message.direction == 'IN';

        // Verificar se deve mostrar separador de data
        bool showDateSeparator = false;
        if (index == 0) {
          showDateSeparator = true;
        } else {
          final prevDate = DateTime(
            messages[index - 1].createdAt.year,
            messages[index - 1].createdAt.month,
            messages[index - 1].createdAt.day,
          );
          final currentDate = DateTime(
            message.createdAt.year,
            message.createdAt.month,
            message.createdAt.day,
          );
          showDateSeparator = !prevDate.isAtSameMomentAs(currentDate);
        }

        return Column(
          children: [
            if (showDateSeparator)
              DateSeparator(date: message.createdAt),
            ChatBubble(
              text: message.text,
              timestamp: message.createdAt,
              isOutgoing: !isIncoming,
              status: message.status,
              senderLabel: isIncoming ? 'Cliente' : 'Bot',
            ),
          ],
        );
      },
    );
  }

  /// Exemplo 2: Usando ChatInputField para campo de entrada
  static Widget buildChatInput(
    TextEditingController controller,
    VoidCallback onSendPressed,
    bool isLoading,
  ) {
    return ChatInputField(
      controller: controller,
      onSendPressed: onSendPressed,
      isLoading: isLoading,
    );
  }

  /// Exemplo 3: Estrutura completa de uma tela de chat
  static Widget buildCompleteChat(
    List<WhatsAppMessage> messages,
    ScrollController scrollController,
    TextEditingController inputController,
    bool isLoading,
    VoidCallback onSendPressed,
  ) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: const Text(
            'Chat Title',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),

        // Messages List
        Expanded(
          child: messages.isEmpty
              ? const Center(child: Text('Sem mensagens'))
              : buildChatList(messages, scrollController),
        ),

        // Input Field
        buildChatInput(inputController, onSendPressed, isLoading),
      ],
    );
  }
}

/// Classe auxiliar para customizar ChatBubble se necessário
class CustomChatBubbleExample {
  /// Exemplo: Chat bubble com imagem de perfil customizada
  static Widget buildCustomBubble(
    String text,
    DateTime timestamp,
    bool isOutgoing,
    ImageProvider? avatar,
  ) {
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: const BoxConstraints(maxWidth: 350),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isOutgoing && avatar != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  backgroundImage: avatar,
                  radius: 16,
                ),
              ),
            // ... resto do bubble customizado
          ],
        ),
      ),
    );
  }
}

/// Dicas de Customização:
/// 
/// 1. Para mudar cores dos bubbles:
///    Editar na classe ChatBubble: 
///    - color: Theme.of(context).colorScheme.primary (para outgoing)
///    - color: Theme.of(context).colorScheme.surfaceContainerHighest (para incoming)
///
/// 2. Para ajustar tamanho do bubble:
///    Editar constraints: const BoxConstraints(maxWidth: 350)
///    Aumentar/diminuir conforme necessário
///
/// 3. Para mudar formato do horário:
///    Editar _formatTime() na classe ChatBubble
///
/// 4. Para adicionar mais ícones de status:
///    Editar _getStatusIcon() com novos valores de status
///
/// 5. Para customizar DateSeparator:
///    Editar formato de data em _formatDate()
///    Adicionar mais lógica para períodos customizados
