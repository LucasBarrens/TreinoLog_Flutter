# Changelog - TreinoLog Flutter

## [1.0.0] - 2026-05-29

### ✅ Implementado - Fase 1: Fluxo Principal

#### Telas Principais
- **HomeScreen** - Dashboard com resumo, lista de treinos, treino em andamento
  - CRUD de treinos (criar, editar, deletar)
  - Card de treino em andamento com continuar
  - Resumo com métrica de treinos registrados
  - Navegação para SavedWorkoutsScreen
  - Navegação para PreWorkoutScreen

- **PreWorkoutScreen** - Preview de treino
  - Listar exercícios do template
  - CRUD de exercícios (criar, editar, deletar)
  - Botão "Iniciar treino"
  - Recuperação de treino em progresso

- **WorkoutExecutionScreen** - Execução do treino
  - List de exercícios com status (não iniciado, em andamento, concluído)
  - Cards com icon de status, nome, séries
  - Resumo em tempo real: séries, exercícios, volume, duração
  - Editar observações do treino
  - Finalizar treino (com validação: requer ≥1 série)
  - Descartar treino (com confirmação)
  - Navegação para ExerciseLogScreen

- **ExerciseLogScreen** - Registro de séries
  - Card de sugestão de progressão
  - REST TIMER com presets (60s, 90s, 120s, 180s)
  - Timer com pause/continue/reset
  - Lista de séries com editor inline
  - Campo de carga (kg) com sanitização
  - Campo de repetições
  - Dropdown de EffortType (7 tipos)
  - Campo de observação por série
  - Botão + Série (auto-incrementa número)
  - Duplicar última série
  - Deletar série (auto-renumera)
  - Seção de observações do exercício
  - Finalizar exercício

- **WorkoutFinalSummaryScreen** - Resumo final
  - Exibe resumo do treino finalizado
  - Duração total
  - Total de séries
  - Exercícios iniciados
  - Volume total calculado
  - Botão "Concluir" (marca como finished e salva no banco)

- **SavedWorkoutsScreen** - Histórico
  - Lista de treinos finalizados com séries
  - Cards com nome, data, duração, volume
  - Modal bottom sheet com detalhes
  - Delete de sessão (com confirmação)

#### Funcionalidades Core
✅ Criar treino (workout template)  
✅ Editar treino (renomear, propaga para todas as sessões ativas)  
✅ Deletar treino (remove template e exercícios, preserva histórico)  
✅ Criar exercício (em um template)  
✅ Editar exercício (renomeia, atualiza histórico)  
✅ Deletar exercício (remove do template)  
✅ Iniciar treino (cria session com exercise logs)  
✅ Continuar treino em progresso (requer <12h ou séries registradas)  
✅ Registrar série (weight, reps, notes, effort type)  
✅ Editar série (inline, auto-save)  
✅ Deletar série (auto-renumera)  
✅ Duplicar série (próximo número, mesmos valores)  
✅ REST TIMER (60/90/120/180s, pause/continue/reset)  
✅ Finalizar exercício (marca isCompleted)  
✅ Finalizar treino (requer ≥1 série, marca isFinished)  
✅ Descartar treino (deleta session e todas as séries)  
✅ Calcular volume (peso × reps, somado)  
✅ Sugestão de progressão (baseado em último set)  

#### Persistência
✅ SQLite via sqflite  
✅ CRUD para todos os modelos  
✅ CASCADE DELETE para integridade  
✅ Seed data (4 treinos padrão)  
✅ Relações entre tabelas  

#### Utilities
✅ VolumeCalculator (8 métodos)  
✅ ExerciseKeyUtil (normalização)  
✅ RepRange (parser)  
✅ FormattingUtil (weight, parse, sanitize)  

#### UI/UX
✅ Material Design 3  
✅ Cards com status visual (cores)  
✅ Icons para status (circle, timer, check)  
✅ Loading states (CircularProgressIndicator)  
✅ Empty states (cards informativos)  
✅ Dialogs para confirmações  
✅ Modal sheets para detalhes  
✅ Responsive layout (SingleChildScrollView)  
✅ Navigation entre telas  
✅ AppBar com titles  
✅ Buttons variados (elevated, outlined, text)  

---

## ❌ Não Implementado (Fase 2+)

- State management avançado (Provider/Riverpod)
- Repositories pattern
- Unit tests
- Integration tests
- ExerciseHistoryScreen (histórico detalhado por exercício)
- Charts de progressão
- Export/Backup
- Dark mode
- Themes customizados
- Internacionalização completa (i18n)
- Animações
- Notifications
- Cloud sync
- Multi-device sync

---

## 🔧 Mudanças Técnicas

### Arquivos Alterados
- `lib/main.dart` - Simplificado, clean imports
- `pubspec.yaml` - Mantém dependencies (sqflite, uuid, intl, path)

### Arquivos Criados
- `lib/screens/index.dart` - Re-exports
- `lib/screens/home_screen.dart` (450+ linhas)
- `lib/screens/pre_workout_screen.dart` (300+ linhas)
- `lib/screens/workout_execution_screen.dart` (350+ linhas)
- `lib/screens/exercise_log_screen.dart` (500+ linhas)
- `lib/screens/workout_final_summary_screen.dart` (100+ linhas)

### Total
- ~2000 linhas de código de tela
- 5 telas principais
- Fluxo completo de execução
- Zero breaking changes
- Compatível com estrutura anterior

---

## 🎯 Status

✅ **FUNCIONAL** - App rodando com fluxo completo  
✅ **LOCAL-FIRST** - Sem backend  
✅ **UI SIMPLES** - Material Design padrão  
✅ **SEM FEATURES NOVAS** - Puro port do SwiftUI  

---

## 📝 Próximos Passos (Fase 2)

1. [ ] Implementar state management (Provider)
2. [ ] Adicionar ExerciseHistoryScreen
3. [ ] Refatorar FutureBuilder para providers
4. [ ] Adicionar unit tests
5. [ ] Adicionar integration tests
6. [ ] Melhorar UX com animações
7. [ ] Dark mode
8. [ ] i18n completo
9. [ ] Refinamento visual
10. [ ] Performance optimization
