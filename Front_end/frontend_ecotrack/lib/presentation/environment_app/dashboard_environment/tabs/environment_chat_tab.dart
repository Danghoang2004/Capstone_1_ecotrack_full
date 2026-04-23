import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend_ecotrack/core/services/environment_team_chat_service.dart';
import 'package:frontend_ecotrack/data/models/environment_team_chat_message_model.dart';
import 'package:frontend_ecotrack/data/models/environment_my_team_info_model.dart';

class EnvironmentChatTab extends StatefulWidget {
  final EnvironmentMyTeamInfo? myTeamInfo;
  final bool isActive;

  const EnvironmentChatTab({
    super.key,
    required this.myTeamInfo,
    required this.isActive,
  });

  @override
  State<EnvironmentChatTab> createState() => _EnvironmentChatTabState();
}

class _EnvironmentChatTabState extends State<EnvironmentChatTab> {
  final EnvironmentTeamChatService _chatService = EnvironmentTeamChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<EnvironmentTeamChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploadingAttachment = false;
  String? _error;
  Timer? _pollTimer;
  int _consecutiveErrors = 0;
  bool _isKickedOut = false;
  bool _isPollingInProgress = false;

  @override
  void initState() {
    super.initState();
    _syncPollingState();
  }

  @override
  void didUpdateWidget(covariant EnvironmentChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.myTeamInfo != widget.myTeamInfo) {
      _syncPollingState();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncPollingState() {
    _pollTimer?.cancel();
    _pollTimer = null;

    if (!widget.isActive || widget.myTeamInfo == null || _isKickedOut) {
      return;
    }

    _consecutiveErrors = 0;
    _loadInitialMessages();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollNewMessages(),
    );
  }

  String _readableErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  bool _isTransientNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('timeoutexception') ||
        message.contains('clientexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('network is unreachable') ||
        message.contains('timed out');
  }

  Future<void> _loadInitialMessages() async {
    try {
      final messages = await _chatService.fetchMessages(limit: 80);
      if (!mounted || !widget.isActive) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
        _error = null;
        _consecutiveErrors = 0;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      // Check if user was kicked out
      if (e is MembershipRevokedException) {
        _handleMembershipRevoked(e.message);
        return;
      }
      final message = _readableErrorMessage(e);
      setState(() {
        _isLoading = false;
        _error = message;
      });
    }
  }

  Future<void> _pollNewMessages() async {
    if (!mounted || !widget.isActive || _isKickedOut || _isPollingInProgress) {
      return;
    }

    if (_messages.isEmpty && _isLoading) return;

    _isPollingInProgress = true;

    try {
      final latestMessages = await _chatService.fetchMessages(limit: 80);
      if (!mounted || !widget.isActive) return;

      final int? oldLastId = _messages.isEmpty
          ? null
          : _messages.last.messageId;
      final int? latestLastId = latestMessages.isEmpty
          ? null
          : latestMessages.last.messageId;
      final hasNewMessage = oldLastId != latestLastId;

      setState(() => _consecutiveErrors = 0);

      setState(() {
        _messages = latestMessages;
      });

      if (hasNewMessage) {
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted || !widget.isActive) return;

      // Check if user was kicked out
      if (e is MembershipRevokedException) {
        _handleMembershipRevoked(e.message);
        return;
      }

      final message = _readableErrorMessage(e);

      if (!_isTransientNetworkError(e)) {
        _pollTimer?.cancel();
        if (_messages.isEmpty) {
          setState(() {
            _error = message;
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }

      // Increment error counter
      setState(() => _consecutiveErrors++);

      // If repeated poll errors persist, surface a connection warning.
      if (_consecutiveErrors >= 4) {
        _handlePollFailure();
      }
    } finally {
      _isPollingInProgress = false;
    }
  }

  void _handleMembershipRevoked(String message) {
    if (!mounted) return;
    setState(() => _isKickedOut = true);
    _pollTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.info_outline, color: Colors.orange, size: 32),
        title: const Text('Thông báo'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF2F6F3E))),
          ),
        ],
      ),
    );
  }

  void _handlePollFailure() {
    if (!mounted || !widget.isActive) return;
    _pollTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 32,
        ),
        title: const Text('Kết nối không ổn định'),
        content: const Text(
          'Không thể kết nối đến nhóm chat. Vui lòng kiểm tra kết nối mạng.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF2F6F3E))),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final sent = await _chatService.sendMessage(text);
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _messages = [..._messages, sent];
        _isSending = false;
        _consecutiveErrors = 0;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      // Check if user was kicked out
      if (e is MembershipRevokedException) {
        _handleMembershipRevoked(e.message);
        return;
      }

      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickAndSendAttachment() async {
    if (_isUploadingAttachment || _isKickedOut) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    final filePath = picked.path;
    if (filePath == null || filePath.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể đọc tệp đã chọn.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isUploadingAttachment = true);
    try {
      final sent = await _chatService.sendAttachment(filePath);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, sent];
        _isUploadingAttachment = false;
        _consecutiveErrors = 0;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      if (e is MembershipRevokedException) {
        _handleMembershipRevoked(e.message);
        return;
      }
      setState(() => _isUploadingAttachment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamName = widget.myTeamInfo?.teamName ?? 'Nhóm môi trường';
    final memberCount = widget.myTeamInfo?.memberCount;

    return Container(
      color: const Color(0xFFF4F7F3),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFEAF5E4),
                  child: Icon(
                    Icons.groups_2_outlined,
                    color: Color(0xFF2F6F3E),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF1F2D1D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        memberCount == null
                            ? 'Kênh chat nội bộ của đội'
                            : 'Kênh chat nội bộ • $memberCount thành viên',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
            const SizedBox(height: 10),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadInitialMessages,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text('Chưa có tin nhắn. Hãy bắt đầu cuộc trao đổi trong nhóm.'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final item = _messages[index];
        final isMine = item.mine;

        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMine ? const Color(0xFF5EAC24) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      item.senderFullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2F6F3E),
                        fontSize: 12,
                      ),
                    ),
                  ),
                Text(
                  item.messageType == 'TEXT'
                      ? item.message
                      : item.attachmentName,
                  style: TextStyle(
                    color: isMine ? Colors.white : const Color(0xFF1F2937),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                if (item.attachmentUrl.isNotEmpty &&
                    item.messageType == 'IMAGE')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.attachmentUrl,
                        width: 220,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) => Container(
                          width: 220,
                          height: 80,
                          alignment: Alignment.center,
                          color: Colors.black12,
                          child: const Text('Không tải được ảnh'),
                        ),
                      ),
                    ),
                  ),
                if (item.attachmentUrl.isNotEmpty && item.messageType == 'FILE')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isMine
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: isMine
                                ? Colors.white
                                : const Color(0xFF374151),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item.attachmentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isMine
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('HH:mm dd/MM').format(item.sentAt),
                  style: TextStyle(
                    color: isMine
                        ? Colors.white.withOpacity(0.85)
                        : const Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
                if (isMine && item.seenByCount > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.seenByAll == true
                          ? 'Đã xem'
                          : 'Đã xem bởi ${item.seenByCount - 1}',
                      style: TextStyle(
                        color: isMine
                            ? Colors.white.withOpacity(0.9)
                            : const Color(0xFF6B7280),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    // Disable composer if kicked out
    final isDisabled = _isKickedOut;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Gửi ảnh/tệp',
            onPressed: (_isUploadingAttachment || isDisabled)
                ? null
                : _pickAndSendAttachment,
            icon: _isUploadingAttachment
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file_rounded),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              enabled: !isDisabled,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: isDisabled
                    ? 'Bạn đã bị xóa khỏi nhóm'
                    : 'Nhập tin nhắn cho đội...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                filled: true,
                fillColor: isDisabled
                    ? const Color(0xFFEFEFEF)
                    : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 46,
            width: 46,
            child: ElevatedButton(
              onPressed: (_isSending || _isUploadingAttachment || isDisabled)
                  ? null
                  : _sendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5EAC24),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
