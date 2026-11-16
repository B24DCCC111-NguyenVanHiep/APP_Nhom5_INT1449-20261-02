// FILE NÀY ĐỂ LÀM GÌ: Màn hình biểu đồ 7 ngày và 30 ngày.
// Người phụ trách: Người 4
import 'dart:math' as math;
import 'package:flutter/gestures.dart' show PointerHoverEvent;
import 'package:flutter/material.dart';

import '../data/step_repository.dart';
import '../models/daily_steps.dart';
import '../logic/stats_calculator.dart';

// Màu nhất quán trong cả biểu đồ, chú thích và tooltip.
const Color _achievedColor = Color(0xFF16A34A); // Xanh: đạt >= 100%.
const Color _nearColor = Color(0xFFF59E0B); // Vàng: >= 80% và < 100%.
const Color _lowColor = Color(0xFFDC2626); // Đỏ: < 80%.

Color _colorForLevel(StepGoalLevel level) {
  switch (level) {
    case StepGoalLevel.achieved:
      return _achievedColor;
    case StepGoalLevel.near:
      return _nearColor;
    case StepGoalLevel.low:
      return _lowColor;
  }
}

/// Người 4: màn hình 7/30 ngày; sử dụng hợp đồng StepRepository của nhóm.
/// - repository.getRange(from, to): trả về List<DailySteps>, bao gồm 2 đầu mút.
/// - repository.getGoal(): lấy mục tiêu bước chân hiện tại.
/// Cả SQLite và InMemory repository đều có thể được truyền vào màn hình này.
class ChartScreen extends StatefulWidget {
  const ChartScreen({
    super.key,
    this.repository,
    this.referenceDate,
  });

  /// Tùy chọn để giữ tương thích với trang placeholder ChartScreen() hiện có.
  /// Khi tích hợp, app.dart phải truyền repository thật/dữ liệu demo vào.
  final StepRepository? repository;

  /// Dùng để cố định ngày trong test; mặc định là hôm nay.
  final DateTime? referenceDate;

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int _selectedDays = 7;
  List<DailySteps> _records = const [];
  bool _loading = true;
  Object? _error;
  int _requestId = 0;
  int _goal = 8000;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _endDate = StatsCalculator.dateOnly(widget.referenceDate ?? DateTime.now());
    _load();
  }

  @override
  void didUpdateWidget(covariant ChartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.referenceDate != widget.referenceDate) {
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_requestId;
    final end =
        StatsCalculator.dateOnly(widget.referenceDate ?? DateTime.now());
    final start = StatsCalculator.startDateFor(end, _selectedDays);
    final repo = widget.repository;
    setState(() {
      _endDate = end;
      _loading = repo != null;
      _error = null;
      _records = const [];
    });
    if (repo == null) return;

    try {
      // getRange() là tên API thật của nhóm, không phải getStepsHistory().
      final history = await repo.getRange(start, end);
      final goal = await repo.getGoal();
      // Xác nhận dữ liệu hợp lệ trước khi chuyển sang trạng thái thành công.
      StatsCalculator.calculate(
        records: history,
        numberOfDays: _selectedDays,
        dailyGoal: goal,
        referenceDate: end,
      );
      if (!mounted || request != _requestId) return;
      setState(() {
        _records = history;
        _goal = goal;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _requestId) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _changeDays(int days) {
    if (days == _selectedDays) return;
    setState(() => _selectedDays = days);
    _load();
  }

  @override
  void dispose() {
    _requestId++; // Không cập nhật giao diện khi đã huỷ màn hình.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê bước chân'),
        actions: [
          IconButton(
            tooltip: 'Tải lại lịch sử',
            onPressed: _loading || widget.repository == null ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Text('Tổng quan hoạt động', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('7 ngày'),
                    selected: _selectedDays == 7,
                    onSelected: (_) => _changeDays(7),
                  ),
                  ChoiceChip(
                    label: const Text('30 ngày'),
                    selected: _selectedDays == 30,
                    onSelected: (_) => _changeDays(30),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.repository == null)
                const _MessagePanel(
                  icon: Icons.storage_outlined,
                  title: 'Chưa kết nối dữ liệu bước chân',
                  detail:
                      'Màn hình cần StepRepository từ app.dart hoặc controller.',
                )
              else if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _MessagePanel(
                  icon: Icons.error_outline,
                  title: 'Không tải được lịch sử bước chân',
                  detail: 'Kiểm tra kho dữ liệu rồi thử lại.',
                  action: TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                )
              else
                _buildStatistics(context, colors, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics(
    BuildContext context,
    ColorScheme colors,
    ThemeData theme,
  ) {
    final stats = StatsCalculator.calculate(
      records: _records,
      numberOfDays: _selectedDays,
      dailyGoal: _goal,
      referenceDate: _endDate,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_formatDate(stats.startDate)} – ${_formatDate(stats.endDate)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) {
          final cardWidth = math.max(0.0, (constraints.maxWidth - 12) / 2);
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                width: cardWidth,
                title: 'Tổng số bước',
                value: _formatNumber(stats.totalSteps),
                icon: Icons.directions_walk,
              ),
              _StatCard(
                width: cardWidth,
                title: 'Trung bình/ngày',
                value: _formatNumber(stats.averageSteps.round()),
                icon: Icons.bar_chart,
              ),
              _StatCard(
                width: cardWidth,
                title: 'Ngày đạt mục tiêu',
                value: '${stats.daysReachedGoal}/${stats.numberOfDays}',
                icon: Icons.flag_outlined,
              ),
              _StatCard(
                width: cardWidth,
                title: 'Ngày nhiều nhất',
                value: _formatNumber(stats.bestDaySteps),
                subtitle: stats.bestDayDate == null
                    ? 'Chưa có dữ liệu'
                    : _formatDate(stats.bestDayDate!),
                icon: Icons.emoji_events_outlined,
              ),
            ],
          );
        }),
        if (stats.totalSteps == 0) ...[
          const SizedBox(height: 16),
          const _MessagePanel(
            icon: Icons.info_outline,
            title: 'Chưa có lịch sử bước chân',
            detail: 'Các ngày chưa ghi nhận sẽ hiển thị 0 bước.',
          ),
        ],
        const SizedBox(height: 24),
        Text('Biểu đồ $_selectedDays ngày gần nhất',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 5),
        Text('Mục tiêu: ${_formatNumber(_goal)} bước/ngày',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            final chartWidth = math.max(
              constraints.maxWidth,
              stats.days.length * (_selectedDays == 7 ? 43.0 : 28.0) + 65,
            );
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                height: 270,
                child: _InteractiveStepsChart(
                  days: stats.days,
                  recordedDates:
                      _records.map((day) => DailySteps.dayOf(day.date)).toSet(),
                  dailyGoal: _goal,
                  goalColor: colors.onSurfaceVariant,
                  gridColor: colors.outlineVariant,
                  labelColor: colors.onSurfaceVariant,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 8, children: [
          const _Legend(color: _achievedColor, label: 'Đạt (100%+)'),
          const _Legend(color: _nearColor, label: 'Gần đạt (80–99%)'),
          const _Legend(color: _lowColor, label: 'Thấp (<80%)'),
          _Legend(color: colors.onSurfaceVariant, label: 'Đường mục tiêu'),
        ]),
        const SizedBox(height: 12),
        Text(
          'Cột xanh: đạt mục tiêu; vàng: gần đạt (từ 80%); '
          'đỏ: dưới 80%. Ngày thiếu dữ liệu được tính là 0 bước '
          'và đánh dấu đỏ ở chân biểu đồ. '
          'Chạm vào từng ngày để xem chi tiết; vuốt ngang khi xem 30 ngày.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Icon(icon, size: 32, color: colors.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(detail, textAlign: TextAlign.center),
          if (action != null) action!,
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
  });

  final double width;
  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: theme.textTheme.titleLarge),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      );
}

/// Chọn từng cột bằng cảm ứng/chuột, không dùng thư viện vẽ biểu đồ.
/// Ngày không có bản ghi được phân biệt với ngày có bản ghi 0 bước.
class _InteractiveStepsChart extends StatefulWidget {
  const _InteractiveStepsChart({
    required this.days,
    required this.recordedDates,
    required this.dailyGoal,
    required this.goalColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<DailySteps> days;
  final Set<DateTime> recordedDates;
  final int dailyGoal;
  final Color goalColor;
  final Color gridColor;
  final Color labelColor;

  @override
  State<_InteractiveStepsChart> createState() => _InteractiveStepsChartState();
}

class _InteractiveStepsChartState extends State<_InteractiveStepsChart> {
  int? _tappedIndex;
  int? _hoveredIndex;
  int? get _activeIndex => _hoveredIndex ?? _tappedIndex;

  @override
  void didUpdateWidget(covariant _InteractiveStepsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days != widget.days ||
        oldWidget.dailyGoal != widget.dailyGoal) {
      // Khi đổi khoảng 7/30 ngày hoặc tải lại dữ liệu, bỏ chọn ngày cũ.
      _tappedIndex = null;
      _hoveredIndex = null;
    }
  }

  int? _indexAt(Offset localPosition, Size size) {
    const left = 57.0;
    const right = 12.0;
    const top = 12.0;
    const bottom = 34.0;
    final graphWidth = size.width - left - right;
    if (widget.days.isEmpty ||
        graphWidth <= 0 ||
        localPosition.dx < left ||
        localPosition.dx >= size.width - right ||
        localPosition.dy < top ||
        localPosition.dy > size.height - bottom) {
      return null;
    }
    final ratio = (localPosition.dx - left) / graphWidth;
    return math.max(
        0,
        math.min(
          widget.days.length - 1,
          (ratio * widget.days.length).floor(),
        ));
  }

  void _onHover(PointerHoverEvent event, Size size) {
    final index = _indexAt(event.localPosition, size);
    if (index != _hoveredIndex) {
      setState(() => _hoveredIndex = index);
    }
  }

  void _onTap(TapDownDetails details, Size size) {
    final index = _indexAt(details.localPosition, size);
    if (index != null) {
      setState(() {
        _tappedIndex = index;
        _hoveredIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final active = _activeIndex;
      final graphWidth = size.width - 57.0 - 12.0;
      final cellWidth =
          widget.days.isEmpty ? 0.0 : graphWidth / widget.days.length;
      final center = active == null ? 0.0 : 57.0 + cellWidth * (active + 0.5);
      const tooltipWidth = 184.0;
      final tooltipX = math.max(
        4.0,
        math.min(center - tooltipWidth / 2, size.width - tooltipWidth - 4.0),
      );

      return MouseRegion(
        onHover: (event) => _onHover(event, size),
        onExit: (_) {
          if (_hoveredIndex != null) setState(() => _hoveredIndex = null);
        },
        child: GestureDetector(
          key: const Key('step-chart-interactive'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _onTap(details, size),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _StepsChartPainter(
                    days: widget.days,
                    dailyGoal: widget.dailyGoal,
                    goalColor: widget.goalColor,
                    gridColor: widget.gridColor,
                    labelColor: widget.labelColor,
                    selectedIndex: active,
                  ),
                ),
              ),
              if (active != null)
                Positioned(
                  left: tooltipX,
                  top: 4,
                  width: tooltipWidth,
                  child: IgnorePointer(
                    child: Material(
                      key: const Key('step-chart-tooltip'),
                      elevation: 4,
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        child: _chartDetail(widget.days[active]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _chartDetail(DailySteps day) {
    final recorded = widget.recordedDates.contains(
      DailySteps.dayOf(day.date),
    );
    final level = StatsCalculator.classifyGoalLevel(
      steps: day.steps,
      dailyGoal: widget.dailyGoal,
    );
    final status = !recorded
        ? 'Chưa ghi nhận dữ liệu'
        : switch (level) {
            StepGoalLevel.achieved => 'Đã đạt mục tiêu',
            StepGoalLevel.near => 'Gần đạt mục tiêu',
            StepGoalLevel.low => 'Mức vận động thấp',
          };
    final percent = (day.steps / widget.dailyGoal * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_formatDate(day.date),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text('${_formatNumber(day.steps)} bước',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Tiến độ: $percent% / ${_formatNumber(widget.dailyGoal)} bước',
            style: const TextStyle(fontSize: 11)),
        Text(status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _colorForLevel(level),
            )),
      ],
    );
  }
}

class _StepsChartPainter extends CustomPainter {
  _StepsChartPainter({
    required this.days,
    required this.dailyGoal,
    required this.goalColor,
    required this.gridColor,
    required this.labelColor,
    required this.selectedIndex,
  });

  final List<DailySteps> days;
  final int dailyGoal;
  final Color goalColor;
  final Color gridColor;
  final Color labelColor;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 57.0;
    const right = 12.0;
    const top = 12.0;
    const bottom = 34.0;
    final graph = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    if (days.isEmpty || graph.width <= 0 || graph.height <= 0) return;

    final highest = days.fold<int>(
      dailyGoal,
      (value, day) => math.max(value, day.steps),
    );
    final upperBound = math.max(1.0, highest * 1.15);
    final gridPen = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var tick = 0; tick <= 4; tick++) {
      final y = graph.bottom - graph.height * tick / 4;
      canvas.drawLine(Offset(graph.left, y), Offset(graph.right, y), gridPen);
      _paintLabel(
        canvas,
        _compactNumber((upperBound * tick / 4).round()),
        Offset(0, y - 7),
        width: left - 9,
        align: TextAlign.right,
      );
    }

    final cellWidth = graph.width / days.length;
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < days.length) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            graph.left + cellWidth * selectedIndex! + 2,
            graph.top,
            math.max(1.0, cellWidth - 4),
            graph.height,
          ),
          const Radius.circular(6),
        ),
        Paint()
          ..color = _colorForLevel(
            StatsCalculator.classifyGoalLevel(
              steps: days[selectedIndex!].steps,
              dailyGoal: dailyGoal,
            ),
          ).withValues(alpha: 0.12),
      );
    }
    final barWidth = math.min(24.0, cellWidth * .60);
    for (var index = 0; index < days.length; index++) {
      final day = days[index];
      final centerX = graph.left + cellWidth * (index + .5);
      final height = graph.height * day.steps / upperBound;
      final barPen = Paint()
        ..color = _colorForLevel(StatsCalculator.classifyGoalLevel(
          steps: day.steps,
          dailyGoal: dailyGoal,
        ));
      if (height > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              centerX - barWidth / 2,
              graph.bottom - height,
              barWidth,
              height,
            ),
            const Radius.circular(4),
          ),
          barPen,
        );
      } else {
        // 0 bước: không có cột, vẽ dấu đỏ ở chân trục để vẫn nhận biết ngày đó.
        canvas.drawCircle(
          Offset(centerX, graph.bottom - 3),
          math.min(3.5, cellWidth * 0.18),
          barPen,
        );
      }
      if (days.length <= 7 || index % 5 == 0 || index == days.length - 1) {
        _paintLabel(
          canvas,
          '${day.date.day}/${day.date.month}',
          Offset(centerX - cellWidth / 2, graph.bottom + 10),
          width: cellWidth,
          align: TextAlign.center,
        );
      }
    }
    final goalY = graph.bottom - graph.height * dailyGoal / upperBound;
    final goalPen = Paint()
      ..color = goalColor
      ..strokeWidth = 2;
    for (var x = graph.left; x < graph.right; x += 12) {
      canvas.drawLine(
        Offset(x, goalY),
        Offset(math.min(x + 6, graph.right), goalY),
        goalPen,
      );
    }
  }

  void _paintLabel(
    Canvas canvas,
    String value,
    Offset offset, {
    required double width,
    required TextAlign align,
  }) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: labelColor, fontSize: 10),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: width, maxWidth: width);
    text.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _StepsChartPainter oldDelegate) {
    if (selectedIndex != oldDelegate.selectedIndex ||
        dailyGoal != oldDelegate.dailyGoal ||
        goalColor != oldDelegate.goalColor ||
        gridColor != oldDelegate.gridColor ||
        labelColor != oldDelegate.labelColor ||
        days.length != oldDelegate.days.length) {
      return true;
    }
    for (var i = 0; i < days.length; i++) {
      if (days[i].date != oldDelegate.days[i].date ||
          days[i].steps != oldDelegate.days[i].steps) {
        return true;
      }
    }
    return false;
  }
}

String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

String _compactNumber(int value) {
  if (value < 1000) return '$value';
  final k = value / 1000;
  return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
}

String _formatNumber(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
