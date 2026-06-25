# Estrutura do Projeto TreinoLog (Flutter)

## 📁 Estrutura de Diretórios

```
lib/
├── main.dart                 # Entry point do app
├── models/                   # Modelos de dados
│   ├── enums.dart           # EffortType, ExerciseStatus
│   ├── exercise_log.dart    # ExerciseLog
│   ├── exercise_template.dart # ExerciseTemplate
│   ├── set_log.dart         # SetLog
│   ├── workout_session.dart # WorkoutSession
│   ├── workout_template.dart # WorkoutTemplate
│   └── index.dart           # Exports
├── services/                # Serviços de negócio
│   ├── database_service.dart # Sqflite operations
│   ├── seed_data_service.dart # Dados iniciais
│   └── index.dart           # Exports
├── utils/                   # Utilities
│   ├── exercise_key.dart    # Gerador de chaves (normalização)
│   ├── formatting.dart      # Formatação de peso
│   ├── rep_range.dart       # Parser de rep range
│   ├── volume_calculator.dart # Cálculos de volume/stats
│   └── index.dart           # Exports
├── screens/                 # Telas (implementar depois)
├── widgets/                 # Widgets reutilizáveis (implementar depois)
└── repositories/            # Repositories (implementar depois)
```

## 🗂️ Modelos Implementados

### `WorkoutTemplate`
- `id`: String (UUID)
- `name`: String
- `order`: int

### `ExerciseTemplate`
- `id`: String (UUID)
- `name`: String
- `exerciseKey`: String (normalizado)
- `workoutName`: String (FK)
- `order`: int
- `defaultRepRange`: String (ex: "5-8")
- `defaultNotes`: String

### `WorkoutSession`
- `id`: String (UUID)
- `workoutName`: String
- `date`: DateTime (início)
- `finishedAt`: DateTime? (quando finalizado)
- `notes`: String
- `isFinished`: bool
- `exerciseLogs`: List<ExerciseLog> (em memória)

### `ExerciseLog`
- `id`: String (UUID)
- `exerciseName`: String
- `exerciseKey`: String (normalizado)
- `order`: int
- `notes`: String
- `isCompleted`: bool
- `workoutSessionId`: String? (FK)
- `status`: ExerciseStatus (computed: notStarted/inProgress/completed)
- `sets`: List<SetLog> (em memória)

### `SetLog`
- `id`: String (UUID)
- `setNumber`: int
- `weightKg`: double
- `reps`: int
- `note`: String
- `effortType`: EffortType
- `exerciseLogId`: String? (FK)

### `Enums`
- **EffortType**: none, warmUp, technicalFailure, totalFailure, rir, cluster, backoff
- **ExerciseStatus**: notStarted, inProgress, completed

## 🛠️ Utilities Implementadas

### `ExerciseKeyUtil.make(String)`
Normaliza nomes de exercício removendo acentos e espaços
- "Supino Inclinado" → "supino-inclinado"

### `RepRange.parse(String)`
Parser de faixa de repetições
- "5-8" → RepRange(min: 5, max: 8)
- "8" → RepRange(min: 8, max: 8)

### `VolumeCalculator`
- `calculateSessionVolume()`: Σ(peso × reps)
- `calculateExerciseVolume()`: Σ(peso × reps) por exercício
- `countTotalSets()`: Total de séries
- `countStartedExercises()`: Exercícios com séries
- `hasRegisteredSets()`: Se tem séries registradas
- `isRecoverableInProgress()`: Se está em progresso recuperável
- `formatDuration()`: Formata duração em tempo legível

### `FormattingUtil`
- `formatWeight()`: Double → "80.5" (remove zeros desnecessários)
- `sanitizeWeightInput()`: Valida entrada de peso
- `parseWeight()`: String → Double

## 💾 Persistência

**Banco**: SQLite via sqflite

### Tabelas criadas:
1. `workout_templates`
2. `exercise_templates`
3. `workout_sessions`
4. `exercise_logs`
5. `set_logs`

Relacionamentos com **CASCADE DELETE** para manter integridade.

## 📋 Seed Data

Dados iniciais com 4 treinos padrão:
- Upper A (7 exercícios)
- Lower A (5 exercícios)
- Upper B (8 exercícios)
- Lower B (6 exercícios)

Cada exercício tem rep range padrão atribuído automaticamente.

## ⏳ Status

✅ **Estrutura criada**
✅ **Modelos implementados**
✅ **Database service completo**
✅ **Seed data implementado**
✅ **Utils implementados**
✅ **main.dart básico rodando**

❌ **Telas não implementadas ainda**
❌ **Widgets não implementados ainda**
❌ **Repositories não implementados ainda**

## 🚀 Próximos Passos

1. Implementar telas (HomeScreen, PreWorkoutScreen, etc)
2. Implementar widgets reutilizáveis
3. Criar repositories para abstrair DatabaseService
4. Implementar state management (Provider/Riverpod)
5. Testes unitários e de integração
