# TreinoLog - Flutter

Transcrição funcional do app TreinoLog de SwiftUI para Flutter. Aplicação local-first para registro e acompanhamento de treinos.

## 🎯 Objetivo

Manter a funcionalidade do app original em Swift/SwiftData, portando para Flutter com persistência local via SQLite.

## ✨ Funcionalidades Previstas

- ✅ Criar e gerenciar templates de treinos
- ✅ Registrar sessões de treino
- ✅ Log de séries (peso, reps, esforço)
- ✅ Timer de descanso entre séries
- ✅ Histórico de treinos
- ✅ Sugestão de progressão
- ✅ Cálculo de volume total
- 🚧 (Em desenvolvimento)

## 📦 Dependências

- `sqflite`: Persistência local em SQLite
- `path`: Gerenciamento de paths
- `intl`: Internacionalização (pt_BR)
- `uuid`: Geração de UUIDs

## 🚀 Como Executar

```bash
# Instalar dependências
flutter pub get

# Executar app
flutter run

# Análise de código
flutter analyze

# Testes
flutter test
```

## 📁 Estrutura

Ver `STRUCTURE.md` para detalhes completos da estrutura de diretórios e modelos.

## 🔒 Local-First

Todos os dados são armazenados localmente em SQLite. Nenhuma sincronização com cloud. Pronto para ser estendido com Firestore/Supabase depois se necessário.

## ⚠️ Limitações Atuais

- Sem state management avançado (Provider/Riverpod) - usar FutureBuilder por enquanto
- Sem telas UI implementadas ainda
- Sem persistência de timer na sessão
- Sem backup/export de dados

## 📝 Status

**v1.0.0-alpha**
- [x] Estrutura de modelos
- [x] Database service
- [x] Seed data
- [x] Utils (volume, formatting, etc)
- [x] Análise lint
- [ ] Telas principais
- [ ] State management
- [ ] Widgets reutilizáveis
- [ ] Tests

## 🔗 Referência

Mapeamento do app original SwiftUI para Flutter em `../TreinoLog/` (projeto macOS/iOS).
