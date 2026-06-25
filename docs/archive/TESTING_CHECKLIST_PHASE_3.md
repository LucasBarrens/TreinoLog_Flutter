# Phase 3 Testing Checklist

## Pre-Test Verification

- [ ] No syntax errors: `flutter analyze`
- [ ] Dependencies installed: `flutter pub get`
- [ ] Build succeeds: `flutter build apk --debug` (or iOS equivalent)

## Feature Testing

### 1. Home Screen ✅
- [ ] Load screen (workouts list appears)
- [ ] Exercise count shows correctly
- [ ] "In progress" card appears if session exists
- [ ] View saved workouts button works
- [ ] Create new workout button works
- [ ] Edit workout button works
- [ ] Delete workout button works (with confirmation)

### 2. Pre-Workout Screen ✅
- [ ] Load screen (exercises list appears)
- [ ] Exercise count shows correctly
- [ ] Add exercise button works
- [ ] Edit exercise button works
- [ ] Delete exercise button works
- [ ] "Iniciar treino" button creates session and starts workout

### 3. Workout Execution Screen ✅
- [ ] Load screen (exercises appear with status)
- [ ] Summary metrics update correctly
- [ ] Click exercise opens ExerciseLogScreen
- [ ] Back from ExerciseLogScreen refreshes exercise list
- [ ] Edit notes button works
- [ ] Finish workout button works (shows summary if sets > 0)
- [ ] Discard workout button works (with confirmation)

### 4. Exercise Log Screen ✅
- [ ] Load screen (progression card + timer appear)
- [ ] Add set button works
- [ ] Duplicate set button works (only if sets exist)
- [ ] Edit set button works (inline)
- [ ] Delete set button works (renumbers remaining)
- [ ] Rest timer presets work (60/90/120/180s)
- [ ] Timer pause/resume works
- [ ] Timer reset works
- [ ] Timer completion alert appears
- [ ] Finish exercise button marks as completed

### 5. Workout Final Summary Screen ✅
- [ ] Load screen (summary appears)
- [ ] Metrics calculated correctly (duration, sets, exercises, volume)
- [ ] Conclude button saves session and returns to home

### 6. Exercise History Screen ✅
- [ ] Load screen (history appears for exercise)
- [ ] Summary stats show (best set, total sessions, last volume)
- [ ] Session cards display correctly
- [ ] Set details show (weight, reps, effort, notes)
- [ ] Volume calculation is correct
- [ ] Empty state shows when no history

### 7. Saved Workouts Screen ✅
- [ ] Load screen (grouped by date)
- [ ] Sessions appear with correct times
- [ ] "Ver treinos registrados" button works from home
- [ ] Session details sheet opens with summary
- [ ] Delete session button works (with confirmation)
- [ ] Empty state shows when no sessions

### 8. Dark Mode ✅
- [ ] Theme toggle switches light/dark
- [ ] All screens render correctly in dark mode
- [ ] Text remains readable
- [ ] Buttons visible in dark mode
- [ ] Status bar adapts to theme

## Data Integrity Tests

- [ ] New workout persists after creation
- [ ] Exercise CRUD operations persist
- [ ] Set CRUD operations persist
- [ ] Session completion persists
- [ ] Exercise history loads correct sets
- [ ] Volume calculations accurate
- [ ] Date/time stamps correct

## Navigation Tests

- [ ] Home → Pre-workout → Workout execution → Exercise log → back
- [ ] Home → Saved workouts → Details → back
- [ ] Home → Pre-workout → Start workout (new session) → Success
- [ ] Home → Pre-workout → Start workout (in-progress) → Continue
- [ ] Exercise log → See history → back to log

## Performance Tests

- [ ] App starts in <2 seconds
- [ ] Screen transitions smooth (<500ms)
- [ ] Exercise history loads in <1 second
- [ ] No memory leaks (profile with DevTools)

## Edge Cases

- [ ] Empty workout (0 exercises) start behavior
- [ ] Set without weight/reps saved correctly
- [ ] Exercise with no sets shows empty
- [ ] Timer continues after exercise edit
- [ ] Navigate away and back (timer resets - expected)
- [ ] Very long notes don't break layout
- [ ] Exercise names with special characters

## Error Handling

- [ ] Delete in-progress session works
- [ ] Delete with orphaned exercise logs
- [ ] Recovery from app crash (in-progress session recoverable)
- [ ] Corrupted database handling (unlikely)

## Device Testing

- [ ] iOS (if available)
- [ ] Android (API 21+)
- [ ] Tablet layout (if different)
- [ ] Landscape mode

## Test Log Template

```
Date: ____________________
Device: ___________________
OS Version: _________________
App Version: ________________

Feature: ___________________
Result: ✅ PASS / ❌ FAIL
Notes: ______________________
```

## Pass/Fail Criteria

**PASS**: 
- ✅ All critical features work
- ✅ No crashes or exceptions
- ✅ Data persists correctly
- ✅ Dark mode renders properly

**FAIL**:
- ❌ Any screen crashes
- ❌ Data doesn't persist
- ❌ Navigation broken
- ❌ Critical feature fails

## Sign-Off

- [ ] Phase 3 testing complete
- [ ] All features verified
- [ ] Documentation updated
- [ ] Ready for Phase 4

---

**Testing Date**: _____________  
**Tester**: __________________  
**Result**: ✅ PASS / ❌ FAIL  
**Notes**: __________________  
