// FILE NÀY ĐỂ LÀM GÌ: Màn hình bảng xếp hạng bạn bè (BẮT BUỘC ĐĂNG NHẬP, Khách không được vào).
// Người phụ trách: Người 5

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/friends_repository.dart';
import 'auth_screen.dart';

/// NGƯỜI 5. Bảng xếp hạng bạn bè theo mã nhóm (Bắt buộc phải có tài khoản).
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({
    super.key,
    this.repository,
    this.initialGroupCode = 'DEMO',
  });

  final FriendsRepository? repository;
  final String initialGroupCode;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

enum _ScreenStatus { initial, loading, success, empty, error }

class _FriendsScreenState extends State<FriendsScreen> {
  late final TextEditingController _groupController;
  late final TextEditingController _stepsController;

  AppUser? _currentUser;
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
    _stepsController = TextEditingController(text: '8000');

    _checkLoginSession();
  }

  Future<File?> _getProfileFile() async {
    try {
      final dbPath = await getDatabasesPath();
      return File(p.join(dbPath, 'user_profile.json'));
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkLoginSession() async {
    try {
      final file = await _getProfileFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          final user = AppUser.fromJson(data);
          // Chỉ mở khóa nếu là tài khoản thật (không phải Khách)
          if (!user.isGuest && user.email.isNotEmpty) {
            if (mounted) {
              setState(() {
                _currentUser = user;
                if (data['groupCode'] != null &&
                    (data['groupCode'] as String).isNotEmpty) {
                  _groupController.text = data['groupCode'] as String;
                }
              });
              _loadLeaderboard();
            }
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _currentUser = null;
      });
    }
  }

  Future<void> _saveCurrentGroup(String groupCode) async {
    if (_currentUser == null) return;
    try {
      final file = await _getProfileFile();
      if (file == null) return;
      final data = _currentUser!.toJson();
      data['groupCode'] = groupCode;
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text(
            'Bạn có chắc muốn đăng xuất? Khi đăng xuất bạn sẽ cần đăng nhập lại để xem thử thách.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final file = await _getProfileFile();
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    setState(() {
      _currentUser = null;
      _leaderboard.clear();
      _status = _ScreenStatus.initial;
    });
  }

  /// Mở màn hình đăng nhập (không có nút Bỏ qua dạng khách vì thử thách bắt buộc tài khoản)
  Future<void> _openAuthScreen() async {
    await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(
        builder: (_) => const AuthScreen(allowGuest: false),
      ),
    );
    _checkLoginSession();
  }

  @override
  void dispose() {
    _groupController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    if (_currentUser == null) return;

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
      _saveCurrentGroup(groupCode);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _ScreenStatus.error;
        _errorMessage = 'Không thể tải bảng xếp hạng: $e';
      });
    }
  }

  Future<void> _submitSteps() async {
    if (_currentUser == null) return;

    final groupCode = _groupController.text.trim();
    final steps = int.tryParse(_stepsController.text.trim()) ?? 0;

    if (groupCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã nhóm.')),
      );
      return;
    }

    try {
      await _repo.submitMySteps(
        groupCode,
        _currentUser!.id,
        _currentUser!.name,
        steps,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Đã cập nhật $steps bước cho tài khoản "${_currentUser!.name}"!'),
        ),
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
    if (_currentUser == null) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật bước lên nhóm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tài khoản: ${_currentUser!.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stepsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số bước chân hôm nay',
                prefixIcon: Icon(Icons.directions_walk),
              ),
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

  /// GIAO DIỆN BẮT BUỘC ĐĂNG NHẬP KHI VÀO THỬ THÁCH
  Widget _buildRequireLoginView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                size: 70,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bắt buộc có tài khoản',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Chế độ Thử thách bạn bè yêu cầu phải có tài khoản để ghi nhận kết quả và vinh danh trên bảng xếp hạng.\n\nNgười dùng ở dạng Khách không thể tham gia mục này.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52), // Vùng chạm >= 48dp
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _openAuthScreen,
              icon: const Icon(Icons.login_rounded),
              label: const Text(
                'Đăng nhập / Đăng ký để tiếp tục',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thanh tài khoản của người dùng khi đã đăng nhập
  Widget _buildAccountBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade700,
            radius: 18,
            child: Text(
              _currentUser!.name.isNotEmpty
                  ? _currentUser!.name[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _currentUser!.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              minimumSize: const Size(48, 48), // Vùng chạm >= 48dp
            ),
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                const Icon(Icons.error_outline,
                    size: 56, color: Colors.redAccent),
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hãy là người đầu tiên gửi số bước của mình lên nhóm!',
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
              final isMe =
                  _currentUser != null && entry.id == _currentUser!.id;
              return _buildRankCard(index + 1, entry, isMe);
            },
          ),
        );
    }
  }

  Widget _buildRankCard(int rank, FriendEntry entry, bool isMe) {
    Widget leadingWidget;

    if (rank == 1) {
      leadingWidget =
          const Icon(Icons.emoji_events, color: Colors.amber, size: 32);
    } else if (rank == 2) {
      leadingWidget =
          Icon(Icons.military_tech, color: Colors.blueGrey.shade300, size: 30);
    } else if (rank == 3) {
      leadingWidget =
          Icon(Icons.military_tech, color: Colors.brown.shade300, size: 28);
    } else {
      leadingWidget = CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.shade200,
        child: Text(
          '$rank',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black87),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  fontWeight:
                      (rank <= 3 || isMe) ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Tôi',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
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
    final isLoggedIn = _currentUser != null && !_currentUser!.isGuest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thử thách bạn bè'),
        actions: [
          if (isLoggedIn)
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
        child: isLoggedIn
            ? Column(
                children: [
                  _buildAccountBar(),
                  _buildSearchBar(),
                  Expanded(child: _buildContent()),
                ],
              )
            : _buildRequireLoginView(),
      ),
      floatingActionButton: isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: _showSubmitDialog,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Gửi bước của tôi'),
            )
          : null,
    );
  }
}
