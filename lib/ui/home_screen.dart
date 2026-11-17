// FILE NÀY ĐỂ LÀM GÌ: Màn hình chính: số bước và vòng tròn tiến độ.
// Người phụ trách: Người 3

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/insight_provider.dart';
import '../logic/steps_controller.dart';
import 'chart_screen.dart';
import 'formatters.dart';
import 'friends_screen.dart';
import 'goal_screen.dart';
import 'strings.dart';
import 'widgets/account_sheet.dart';
import 'widgets/auth_gate.dart';
import 'widgets/state_views.dart';

/// NGƯỜI 3. Màn hình chính theo mockup StepFlow.
/// - Chỉ HIỂN THỊ: mọi số liệu lấy từ StepsController (context.watch), không có IO trong build().
/// - Chọn nội dung bằng switch theo StepsStatus nên không bao giờ có màn trắng.
/// - [insightProvider] có giá trị mặc định nên `const HomeScreen()` vẫn dùng được.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.insightProvider = const StaticInsightProvider(),
  });

  final InsightProvider insightProvider;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<StepsController>();
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF3F8F3) : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            tooltip: AppStrings.accountTooltip,
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => showAccountSheet(context),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, c)),
    );
  }

  Widget _buildBody(BuildContext context, StepsController c) {
    switch (c.status) {
      case StepsStatus.loading:
        return const LoadingView();
      case StepsStatus.noPermission:
        return ErrorView(
          message: c.errorMessage ?? AppStrings.noPermissionMessage,
          actionLabel: AppStrings.grantPermission,
          onAction: c.requestPermissionAndStart,
          icon: Icons.directions_walk_rounded,
        );
      case StepsStatus.error:
        return ErrorView(
          message: c.errorMessage ?? AppStrings.errorGeneric,
          actionLabel: AppStrings.retry,
          onAction: c.retry,
        );
      case StepsStatus.ready:
        return _ReadyBody(controller: c, insightProvider: insightProvider);
    }
  }
}

// ---------------------------------------------------------------------------

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.controller, required this.insightProvider});
  final StepsController controller;
  final InsightProvider insightProvider;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final now = DateTime.now();
    final insight = insightProvider.insightFor(
      InsightInput(steps: c.todaySteps, goal: c.goal, progress: c.progress),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          formatDateVi(now),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          greetingFor(now.hour),
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Chưa có bước: dùng EmptyView nhưng vẫn giữ lối đi sang các màn khác bên dưới.
        if (c.isEmptyToday)
          const _SoftCard(
            child: EmptyView(
              message: AppStrings.emptyTitle,
              hint: AppStrings.emptyHint,
            ),
          )
        else
          _ProgressRing(
            steps: c.todaySteps,
            goal: c.goal,
            progress: c.progress,
            percent: c.percent,
          ),
        const SizedBox(height: 12),
        _GoalRow(goal: c.goal, onChange: () => _openGoal(context)),
        if (!c.isEmptyToday) ...[
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.route_rounded,
                    value: formatDecimal(c.estimatedKm),
                    label: AppStrings.kmLabel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    value: formatSteps(c.estimatedKcal.round()),
                    label: AppStrings.kcalLabel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.timer_outlined,
                    value: formatSteps(c.estimatedMinutes),
                    label: AppStrings.minutesLabel,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.estimateNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          _InsightCard(text: insight),
        ],
        const SizedBox(height: 16),
        _NavTile(
          icon: Icons.bar_chart_rounded,
          title: AppStrings.chartTileTitle,
          subtitle: AppStrings.chartTileSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ChartScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _NavTile(
          icon: Icons.emoji_events_outlined,
          title: AppStrings.challengeTileTitle,
          subtitle: AppStrings.challengeTileSubtitle,
          // Chỉ màn Thử thách cần tài khoản: bọc bằng AuthGate TẠI ĐÂY,
          // không sửa friends_screen.dart (của Người 5).
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AuthGate(child: FriendsScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openGoal(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const GoalScreen()),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(AppStrings.goalSaved)));
    }
  }
}

/// Thẻ trắng bo góc lớn dùng chung trong màn chính.
class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child, this.padding = EdgeInsets.zero});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.steps,
    required this.goal,
    required this.progress,
    required this.percent,
  });
  final int steps;
  final int goal;
  final double progress;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final side = math.min(MediaQuery.of(context).size.width * 0.62, 260.0);
    return _SoftCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        // Một nhãn đọc to cho trình đọc màn hình; phần vẽ bên trong bị loại khỏi cây ngữ nghĩa.
        child: Semantics(
          label: AppStrings.ringSemantics(
            formatSteps(steps),
            percent,
            formatSteps(goal),
          ),
          child: ExcludeSemantics(
            child: SizedBox(
              width: side,
              height: side,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: progress,
                  color: cs.primary,
                  trackColor: cs.primary.withOpacity(0.15),
                  strokeWidth: side * 0.07,
                ),
                child: Padding(
                  padding: EdgeInsets.all(side * 0.16),
                  // FittedBox: chữ tự co lại, không tràn vòng khi textScale lớn.
                  child: FittedBox(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatSteps(steps),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Text(AppStrings.stepsUnit),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppStrings.percentOfGoal(percent),
                            style: TextStyle(color: cs.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final p = progress < 0 ? 0.0 : (progress > 1 ? 1.0 : progress);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );
    if (p > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // bắt đầu từ 12 giờ
        2 * math.pi * p,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal, required this.onChange});
  final int goal;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(AppStrings.goalLabel(formatSteps(goal)))),
          TextButton.icon(
            onPressed: onChange,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text(AppStrings.changeGoal),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: '$value $label',
      child: ExcludeSemantics(
        child: _SoftCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: cs.primary),
              const SizedBox(height: 6),
              FittedBox(
                child: Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 2),
              // maxLines + ellipsis: nhãn không tràn khi chữ phóng to.
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: cs.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: cs.onPrimaryContainer)),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64), // vùng chạm >= 48dp
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(icon, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
