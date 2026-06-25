import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/index.dart';
import '../providers/index.dart';
import '../theme/app_theme.dart';
import '../utils/index.dart';

class BodyMeasurementFormScreen extends ConsumerStatefulWidget {
  final BodyMeasurement? existing;

  const BodyMeasurementFormScreen({Key? key, this.existing}) : super(key: key);

  @override
  ConsumerState<BodyMeasurementFormScreen> createState() =>
      _BodyMeasurementFormScreenState();
}

class _BodyMeasurementFormScreenState
    extends ConsumerState<BodyMeasurementFormScreen> {
  late DateTime _date;
  late BodySex _sex;

  late final TextEditingController _weight;
  late final TextEditingController _height;
  late final TextEditingController _bicepsR;
  late final TextEditingController _bicepsL;
  late final TextEditingController _chest;
  late final TextEditingController _waist;
  late final TextEditingController _abdomen;
  late final TextEditingController _hip;
  late final TextEditingController _glutes;
  late final TextEditingController _thighR;
  late final TextEditingController _thighL;
  late final TextEditingController _calfR;
  late final TextEditingController _calfL;
  late final TextEditingController _notes;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _date = m?.date ?? DateTime.now();
    _sex = m?.sex ?? BodySex.unspecified;
    _weight = TextEditingController(text: _fmt(m?.weightKg));
    _height = TextEditingController(text: _fmt(m?.heightCm));
    _bicepsR = TextEditingController(text: _fmt(m?.bicepsRightCm));
    _bicepsL = TextEditingController(text: _fmt(m?.bicepsLeftCm));
    _chest = TextEditingController(text: _fmt(m?.chestCm));
    _waist = TextEditingController(text: _fmt(m?.waistCm));
    _abdomen = TextEditingController(text: _fmt(m?.abdomenCm));
    _hip = TextEditingController(text: _fmt(m?.hipCm));
    _glutes = TextEditingController(text: _fmt(m?.glutesCm));
    _thighR = TextEditingController(text: _fmt(m?.thighRightCm));
    _thighL = TextEditingController(text: _fmt(m?.thighLeftCm));
    _calfR = TextEditingController(text: _fmt(m?.calfRightCm));
    _calfL = TextEditingController(text: _fmt(m?.calfLeftCm));
    _notes = TextEditingController(text: m?.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _weight,
      _height,
      _bicepsR,
      _bicepsL,
      _chest,
      _waist,
      _abdomen,
      _hip,
      _glutes,
      _thighR,
      _thighL,
      _calfR,
      _calfL,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(double? v) {
    if (v == null) return '';
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toString();
  }

  double? _parse(TextEditingController c) {
    final raw = c.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final actions = ref.read(bodyMeasurementActionsProvider);

    final base = widget.existing ??
        BodyMeasurement(id: const Uuid().v4(), date: _date);

    final updated = BodyMeasurement(
      id: base.id,
      date: _date,
      sex: _sex,
      weightKg: _parse(_weight),
      heightCm: _parse(_height),
      bicepsRightCm: _parse(_bicepsR),
      bicepsLeftCm: _parse(_bicepsL),
      chestCm: _parse(_chest),
      waistCm: _parse(_waist),
      abdomenCm: _parse(_abdomen),
      hipCm: _parse(_hip),
      glutesCm: _parse(_glutes),
      thighRightCm: _parse(_thighR),
      thighLeftCm: _parse(_thighL),
      calfRightCm: _parse(_calfR),
      calfLeftCm: _parse(_calfL),
      notes: _notes.text.trim(),
    );

    try {
      if (widget.existing == null) {
        await actions.create(updated);
      } else {
        await actions.update(updated);
      }
      ref.invalidate(bodyMeasurementsProvider);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Falha ao salvar: $e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar medição' : 'Nova medição'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _SectionLabel('Informações gerais'),
          const SizedBox(height: 8),
          _DateTile(date: _date, onTap: _pickDate),
          const SizedBox(height: 12),
          _SexSelector(
            value: _sex,
            onChanged: (v) => setState(() => _sex = v),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Composição'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberField(controller: _weight, label: 'Peso', suffix: 'kg'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(controller: _height, label: 'Altura', suffix: 'cm'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel('Tronco (cm)'),
          const SizedBox(height: 8),
          _NumberField(controller: _chest, label: 'Tórax', suffix: 'cm'),
          const SizedBox(height: 12),
          _NumberField(controller: _waist, label: 'Cintura', suffix: 'cm'),
          const SizedBox(height: 12),
          _NumberField(controller: _abdomen, label: 'Abdômen', suffix: 'cm'),
          const SizedBox(height: 12),
          _NumberField(controller: _hip, label: 'Quadril', suffix: 'cm'),
          const SizedBox(height: 12),
          _NumberField(controller: _glutes, label: 'Glúteos', suffix: 'cm'),
          const SizedBox(height: 24),
          _SectionLabel('Braços (cm)'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: _bicepsL,
                  label: 'Bíceps esq.',
                  suffix: 'cm',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  controller: _bicepsR,
                  label: 'Bíceps dir.',
                  suffix: 'cm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel('Pernas (cm)'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: _thighL,
                  label: 'Coxa esq.',
                  suffix: 'cm',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  controller: _thighR,
                  label: 'Coxa dir.',
                  suffix: 'cm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: _calfL,
                  label: 'Panturrilha esq.',
                  suffix: 'cm',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  controller: _calfR,
                  label: 'Panturrilha dir.',
                  suffix: 'cm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel('Observações'),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Opcional',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(isEditing ? 'Salvar alterações' : 'Adicionar medição'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateTile({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatted = FormattingUtil.formatDate(date);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                formatted,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SexSelector extends StatelessWidget {
  final BodySex value;
  final ValueChanged<BodySex> onChanged;

  const _SexSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<BodySex>(
      segments: const [
        ButtonSegment(value: BodySex.male, label: Text('Homem')),
        ButtonSegment(value: BodySex.female, label: Text('Mulher')),
        ButtonSegment(value: BodySex.unspecified, label: Text('Não informado')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      style: const TextStyle(fontWeight: FontWeight.w600),
      // Color hint inherited from theme — keeps visual identity intact.
      cursorColor: AppColors.primary,
    );
  }
}
