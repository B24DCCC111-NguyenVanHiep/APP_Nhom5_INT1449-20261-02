// FILE NÀY ĐỂ LÀM GÌ: Màn hình bảng xếp hạng bạn bè (tự động ghi nhớ tên và nhóm khi tắt app).
// Người phụ trách: Người 5

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/friends_repository.dart';

/// NGƯỜI 5. Bảng xếp hạng bạn bè theo mã nhóm.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({
    super.key,
    this.repository,
    this.initialGroupCode = 'DEMO',
    this.myUserId = 'current_user_id',
  });

  final FriendsRepository? repository;
  final String initialGroupCode;
  final String myUserId;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

enum _ScreenStatus { initial, loading, success, empty, error }

class _FriendsScreenState extends State<FriendsScreen> {
  late final TextEditingController _groupController;
  late final TextEditingController _nameController;
  late final TextEditingController _stepsController;

  _ScreenStatus _status = _ScreenStatus.initial;
  List<FriendEntry> _leaderboard = <FriendEntry>[];
  String? _errorMessage;

  FriendsRepository get _repo =>
      widget.repository ??
      tryReadProvider<FriendsRepository>() ??
      FakeFriendsRepository();

  FriendsRepository? tryReadProvider<T>() {
    try {
      return Provider.of<FriendsRepository>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _groupController = TextEditingController(text: widget.initialGroupCode);
    _nameController = TextEditingController(text: 'Văn Hiệp');
    _stepsController = TextEditingController(text: '8000');

    // Tải thông tin người dùng đã lưu từ lần mở app trước
    _loadSavedUserProfile();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_groupController.text.trim().isNotEmpty) {
        _loadLeaderboard();
      }
    });
  }

  Future<File?> _getProfileFile() async {
    try {
      final dbPath = await getDatabasesPath();
      return File(p.join(dbPath, 'user_profile.json'));
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadSavedUserProfile() async {
    try {
      final file = await _getProfileFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              if (data['name'] != null && (data['name'] as String).isNotEmpty) {
                _nameController.text = data['name'] as String;
              }
              if (data['groupCode'] != null &&
                  (data['groupCode'] as String).isNotEmpty) {
                _groupController.text = data['groupCode'] as String;
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveUserProfile() async {
    try {
      final file = await _getProfileFile();
      if (file == null) return;
      final data = {
        'name': _nameController.text.trim(),
        'groupCode': _groupController.text.trim(),
      };
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  @override
  void dispose() {
    _groupController.dispose();
    _nameController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    final groupCode = _groupController.text.trim();
    if (groupCode.isEmpty) {
      setState(() {
        _status = _ScreenStatus.error;
        _errorMessage = 'Vui lòng nhập mã nhóm để xem bảng xếp hạng.';
      });
      return;
    }

    setState(() {
      _status = _ScreenStatus.loading;
      _errorMessage = null;
    });

    try {
      final list = await _repo.leaderboard(groupCode);
      if (!mounted) return;
      setState(() {
        _leaderboard = list;
        _status = list.isEmpty ? _ScreenStatus.empty : _ScreenStatus.success;
      });
      // Lưu lại mã nhóm cuối cùng người dùng tra cứu
      _saveUserProfile();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _ScreenStatus.error;
        _errorMessage = 'Không thể tải bảng xếp hạng: $e';
      });
    }
  }

  Future<void> _submitSteps() async {
    final groupCode = _groupController.text.trim();
    final name = _nameController.text.trim();
    final steps = int.tryParse(_stepsController.text.trim()) ?? 0;

    if (groupCode.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ mã nhóm và tên.')),
      );
      return;
    }

    try {
      await _repo.submitMySteps(groupCode, widget.myUserId, name, steps);
      await _saveUserProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật $steps bước cho "$name"!')),
      );
      await _loadLeaderboard();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi số bước: $e')),
      );
    }
  }

  void _showSubmitDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật số bước của bạn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên hiển thị (tự nhớ khi tắt app)',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stepsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số bước chân',
                prefixIcon: Icon(Icons.directions_walk),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ID máy: ${widget.myUserId}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(64, 48), // Vùng chạm >= 48dp
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(88, 48), // Vùng chạm >= 48dp
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _submitSteps();
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _groupController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Mã nhóm thử thách',
                  hintText: 'VD: DEMO, NHOM5...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.group),
                ),
                onSubmitted: (_) => _loadLeaderboard(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Tìm kiếm',
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48), // Vùng chạm >= 48dp
              ),
              onPressed: _loadLeaderboard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_status) {
      case _ScreenStatus.initial:
      case _ScreenStatus.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải bảng xếp hạng...'),
            ],
          ),
        );

      case _ScreenStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Đã xảy ra lỗi khi tải dữ liệu.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(120, 48), // Vùng chạm >= 48dp
                  ),
                  onPressed: _loadLeaderboard,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        );

      case _ScreenStatus.empty:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_off_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'Chưa có ai trong nhóm "${_groupController.text.trim()}".',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hãy là người đầu tiên tham gia và gửi số bước của mình!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(140, 48), // Vùng chạm >= 48dp
                  ),
                  onPressed: _showSubmitDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Gửi số bước ngay'),
                ),
              ],
            ),
          ),
        );

      case _ScreenStatus.success:
        return RefreshIndicator(
          onRefresh: _loadLeaderboard,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _leaderboard.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = _leaderboard[index];
              final isMe = entry.id == widget.myUserId;
              return _buildRankCard(index + 1, entry, isMe);
            },
          ),
        );
    }
  }

  Widget _buildRankCard(int rank, FriendEntry entry, bool isMe) {
    Widget leadingWidget;
    Color? medalColor;

    if (rank == 1) {
      medalColor = Colors.amber;
      leadingWidget = const Icon(Icons.emoji_events, color: Colors.amber, size: 32);
    } else if (rank == 2) {
      medalColor = Colors.blueGrey.shade300;
      leadingWidget = Icon(Icons.military_tech, color: medalColor, size: 30);
    } else if (rank == 3) {
      medalColor = Colors.brown.shade300;
      leadingWidget = Icon(Icons.military_tech, color: medalColor, size: 28);
    } else {
      leadingWidget = CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.shade200,
        child: Text(
          '$rank',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      );
    }

    return Card(
      elevation: isMe ? 4 : (rank <= 3 ? 3 : 1),
      color: isMe ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isMe
            ? const BorderSide(color: Colors.green, width: 2)
            : (rank == 1
                ? const BorderSide(color: Colors.amber, width: 1.5)
                : BorderSide.none),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: SizedBox(
          width: 40,
          child: Center(child: leadingWidget),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                entry.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: (rank <= 3 || isMe) ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Tôi',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_walk, size: 20, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              '${entry.steps} bước',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thử thách bạn bè'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48), // Vùng chạm >= 48dp
            ),
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitDialog,
        icon: const Icon(Icons.cloud_upload),
        label: const Text('Gửi bước của tôi'),
      ),
    );
  }
}
