# Criação de Reserva por Gerente

## Goal
Permitir que Gerentes e Administradores criem reservas para clientes, selecionando veículo, período, cliente e método de pagamento (incluindo link).

## Tasks
- [x] **Task 0:** Criar plano de execução → Verify: Arquivo `reserva-creation-gerente.md` criado.
- [x] **Task 1 (Backend):** Atualizar `registrarReserva` em `reserva.routes.ts` para suportar `GERENTE`/`ADMIN` e `cliente_id` opcional. → Verify: `POST /reservas` aceita `cliente_id` de um Gerente.
- [x] **Task 2 (Frontend):** Atualizar `reservations_service.dart` para incluir método de criação. → Verify: Código compilando e apontando para endpoint correto.
- [x] **Task 3 (Frontend):** Criar `create_reservation_screen.dart` com formulário completo. → Verify: Tela abre e valida campos obrigatórios.
- [x] **Task 4 (Frontend):** Adicionar Autocomplete de Clientes na tela de criação. → Verify: Busca clientes via API enquanto digita.
- [x] **Task 5 (Frontend):** Adicionar Seleção de Veículos disponíveis por período. → Verify: Filtra veículos que não estão ocupados.
- [x] **Task 6 (Frontend):** Integrar com FAB na `ReservasScreen`. → Verify: Botão "+" visível e funcional.

## Done When
- [x] Gerente consegue criar reserva do início ao fim no app.
- [x] Link de pagamento é gerado corretamente pela InfinitePay se selecionado.
