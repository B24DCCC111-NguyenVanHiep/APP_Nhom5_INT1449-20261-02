// FILE NÀY ĐỂ LÀM GÌ: Ba giao diện dùng chung: đang tải, lỗi, chưa có dữ liệu.
// Người phụ trách: Người 3

import 'package:flutter/material.dart';

import '../strings.dart';

/// NGƯỜI 3. Ba trạng thái bắt buộc của rubric, dùng chung cho mọi màn hình.
/// Quy ước giữ ổn định cho Người 4, 5: tên lớp và tham số cũ KHÔNG đổi,
/// chỉ thêm tham số tuỳ chọn. Mỗi trạng thái lỗi/trống đều có lối ra (nút >= 48dp).

/// Căn giữa nội dung; nếu có chiều cao giới hạn thì cho cuộn để KHÔNG tràn khi
/// người dùng phóng to chữ (textScale lớn) hoặc màn hình nhỏ.
class _CenteredScrollable extends StatelessWidget {
  const _CenteredScrollable({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Padding(
          padding: const EdgeInsets.all(24),
          child: child,
        );
        // Đặt trong ListView (chiều cao vô hạn) thì chỉ cần co theo nội dung.
        if (!constraints.hasBoundedHeight) return Center(child: content);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = AppStrings.loading});
  final String message;

  @override
  Widget build(BuildContext context) {
    return _CenteredScrollable(
      // MergeSemantics: trình đọc màn hình đọc "Đang tải…" một lần, không đọc vòng xoay.
      child: MergeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.error_outline_rounded,
  });
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _CenteredScrollable(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 56, color: cs.error)),
          const SizedBox(height: 16),
          // liveRegion: khi lỗi xuất hiện, trình đọc màn hình đọc ngay.
          Semantics(
            liveRegion: true,
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.hint,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.directions_walk_rounded,
  });
  final String message;
  final String? hint;

  /// Tuỳ chọn: nút hành động (chỉ hiện khi có CẢ actionLabel lẫn onAction).
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = actionLabel;
    final action = onAction;
    return _CenteredScrollable(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 56, color: cs.primary)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
          if (label != null && action != null) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: action,
              style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
              child: Text(label),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dải báo lỗi nhỏ nằm trong form (đăng nhập/đăng ký). Thêm mới, không ảnh hưởng chỗ khác.
class InlineErrorBanner extends StatelessWidget {
  const InlineErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: cs.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: TextStyle(color: cs.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
  }
}
