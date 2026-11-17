// FILE NÀY ĐỂ LÀM GÌ: Màn hình đặt mục tiêu bước mỗi ngày.
// Người phụ trách: Người 3

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/step_repository.dart';
import '../logic/steps_controller.dart';
import 'formatters.dart';
import 'strings.dart';

/// NGƯỜI 3. Màn đặt mục tiêu: 3 mục tiêu gợi ý + nhập tay, kiểm tra 1–100.000.
/// StatefulWidget vì giữ TextEditingController (dispose đủ) và trạng thái đang lưu / lỗi.
/// Quy tắc hợp lệ nằm ở StepsController.validateGoal, màn này chỉ hiển thị kết quả.
class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  static const _presets = <int>[5000, 7500, 10000];

  late final TextEditingController _input;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // read (không watch) trong initState: chỉ lấy giá trị ban đầu một lần.
    _input = TextEditingController(
      text: context.read<StepsController>().goal.toString(),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _pickPreset(int value) {
    setState(() {
      _input.text = value.toString();
      _error = null;
    });
  }

  Future<void> _save() async {
    final text = _input.text.trim();
    if (text.isEmpty) {
      setState(() => _error = AppStrings.goalEmpty);
      return;
    }
    final value = int.tryParse(text);
    final problem = value == null
        ? AppStrings.goalOutOfRange
        : StepsController.validateGoal(value);
    if (value == null || problem != null) {
      setState(() => _error = problem);
      return;
    }

    final controller = context.read<StepsController>();
    setState(() {
      _saving = true;
      _error = null;
    });
    String? failure;
    try {
      await controller.setGoal(value);
    } on InvalidGoalException catch (e) {
      failure = e.message;
    } on StepRepositoryException catch (e) {
      failure = e.message;
    } catch (_) {
      failure = AppStrings.goalSaveFailed;
    }
    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _saving = false;
        _error = failure;
      });
      return;
    }
    Navigator.of(context).pop(true); // true => màn chính hiện thông báo đã lưu
  }

  @override
  Widget build(BuildContext context) {
    final current = int.tryParse(_input.text.trim());
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.goalTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(AppStrings.goalIntro),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.goalPresetsLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final p in _presets)
                        _PresetButton(
                          label: formatSteps(p),
                          selected: current == p,
                          onPressed: _saving ? null : () => _pickPreset(p),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _input,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(7),
                    ],
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: AppStrings.goalFieldLabel,
                      helperText: AppStrings.goalFieldHelper,
                      suffixText: AppStrings.goalFieldSuffix,
                      errorText: _error,
                      errorMaxLines: 3,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.save),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const size = Size(96, 48); // vùng chạm >= 48dp
    return Semantics(
      selected: selected,
      child: selected
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(minimumSize: size),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(minimumSize: size),
              child: Text(label),
            ),
    );
  }
}
