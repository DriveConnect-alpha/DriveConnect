/**
 * Exemplo: Sistema de Fotos via WhatsApp
 * O bot envia APENAS a foto principal quando o cliente pedir
 */

import { atenderClienteComAgent } from './agent.js';
import { sendImageByUrl } from '../services/whatsapp-media.service.js';

// Simular uma conversa onde o cliente pede fotos
async function exemploPedidoDeFotos() {
  console.log('\n📸 EXEMPLO 1: Cliente pede foto de um carro\n');

  // Cliente: "Pode enviar a foto do Gol?"
  const resultado = await atenderClienteComAgent(
    'Mostre a foto do Gol',
    {
      telefone: '+5511999999999',
      clienteId: 'cliente-123',
    }
  );

  console.log('Intenção detectada:', resultado.intencao);
  console.log('Tools usadas:', resultado.tools_usadas);
  console.log('Resposta:', resultado.resposta);
  console.log('Foto para enviar:', resultado.fotos?.[0]);

  // Na prática, o WhatsApp service faria:
  if (resultado.fotos && resultado.fotos.length > 0) {
    console.log(`\n✅ Enviando 1 foto do Gol...`);
    // await sendImageByUrl('+5511999999999', resultado.fotos[0]);
  }
}

async function exemploListagemComFotos() {
  console.log('\n📸 EXEMPLO 2: Listagem de carros (sem fotos automáticas)\n');

  // Cliente: "Quais carros SUV disponíveis?"
  const resultado = await atenderClienteComAgent(
    'Quais SUVs vocês têm disponível para fins de semana?',
    {
      telefone: '+5511999999999',
      clienteId: 'cliente-456',
    }
  );

  console.log('Intenção detectada:', resultado.intencao);
  console.log('Tools usadas:', resultado.tools_usadas);
  console.log('Resposta:\n', resultado.resposta);

  if (resultado.fotos && resultado.fotos.length > 0) {
    console.log(`\n⚠️  Nenhuma foto será enviada automaticamente na listagem`);
    console.log(`Cliente pode pedir: "Foto do Tiguan" ou "Mostre foto do Sportage"`);
  }
}

async function exemploIntegracaoCompleta() {
  console.log('\n📸 EXEMPLO 3: Fluxo completo - pedido de foto\n');

  const telefone = '+5511999999999';
  const mensagem = 'Mostre a foto do Corolla';

  // 1. Agent processa mensagem
  console.log(`Cliente: "${mensagem}"`);
  const resultado = await atenderClienteComAgent(mensagem, {
    telefone,
    clienteId: 'cliente-789',
  });

  // 2. Enviar resposta de texto
  console.log(`\nBot: ${resultado.resposta}`);

  // 3. Se houver foto, enviar via WhatsApp
  if (resultado.fotos && resultado.fotos.length > 0) {
    console.log(`\n📸 Enviando 1 foto...`);
    
    // Em produção seria:
    // const { sendImageByUrl } = await import('../services/whatsapp-media.service.js');
    // await sendImageByUrl(telefone, resultado.fotos[0]);
    
    // Para demo:
    console.log(`✅ Foto enviada: ${resultado.fotos[0]}`);
  }

  console.log('\n✨ Conversa finalizada!');
}

// Teste local: descomente para rodar
// (async () => {
//   try {
//     await exemploPedidoDeFotos();
//     await exemploListagemComFotos();
//     await exemploIntegracaoCompleta();
//   } catch (err) {
//     console.error('Erro:', err);
//   }
// })();

export { exemploPedidoDeFotos, exemploListagemComFotos, exemploIntegracaoCompleta };
