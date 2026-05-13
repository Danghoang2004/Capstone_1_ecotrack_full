import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend_ecotrack/core/services/campaign_chat_service.dart';
import 'package:frontend_ecotrack/data/models/campaign_chat_message_model.dart';

class CampaignChatScreen extends StatefulWidget {
  final int campaignId;
  final String campaignTitle;
  final int participantCount;

  const CampaignChatScreen({
    super.key,
    required this.campaignId,
    required this.campaignTitle,
    required this.participantCount,
  });

  @override
  State<CampaignChatScreen> createState() => _CampaignChatScreenState();
}

class _CampaignChatScreenState extends State<CampaignChatScreen> {
  final CampaignChatService _chatService = CampaignChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<CampaignChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploadingAttachment = false;
  String? _error;
  bool _isPollingInProgress = false;
  bool _isLocked = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _syncPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncPolling() {
    _pollTimer?.cancel();
    if (_isLocked) {
      return;
    }

    _loadInitialMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollNewMessages();
    });
  }

  String _readableErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  Future<void> _loadInitialMessages() async {
    try {
      final messages = await _chatService.fetchMessages(
        campaignId: widget.campaignId,
        limit: 80,
      );
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
        _error = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      if (e is CampaignChatAccessException) {
        _handleAccessDenied(e.message);
        return;
      }
      setState(() {
        _isLoading = false;
        _error = _readableErrorMessage(e);
      });
    }
  }

  Future<void> _pollNewMessages() async {
    if (!mounted || _isLocked || _isPollingInProgress) {
      return;
    }

    _isPollingInProgress = true;
    try {
      final latestMessages = await _chatService.fetchMessages(
        campaignId: widget.campaignId,
        limit: 80,
      );
      if (!mounted) return;

      final oldLastId = _messages.isEmpty ? null : _messages.last.messageId;
      final latestLastId = latestMessages.isEmpty
          ? null
          : latestMessages.last.messageId;
      final hasNewMessage = oldLastId != latestLastId;

      setState(() {
        _messages = latestMessages;
      });

      if (hasNewMessage) {
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      if (e is CampaignChatAccessException) {
        _handleAccessDenied(e.message);
        return;
      }
      if (_messages.isEmpty) {
        setState(() {
          _error = _readableErrorMessage(e);
          _isLoading = false;
        });
      }
    } finally {
      _isPollingInProgress = false;
    }
  }

  void _handleAccessDenied(String message) {
    if (!mounted || _isLocked) return;
    _isLocked = true;
    _pollTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.lock_outline, color: Colors.orange, size: 34),
        title: const Text('Quyền truy cập'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Đóng',
              style: TextStyle(color: Color(0xFF2F6F3E)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending || _isLocked) return;

    setState(() => _isSending = true);
    try {
      final sent = await _chatService.sendMessage(
        campaignId: widget.campaignId,
        message: text,
      );
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _messages = [..._messages, sent];
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      if (e is CampaignChatAccessException) {
        _handleAccessDenied(e.message);
        return;
      }
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_readableErrorMessage(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickAndSendAttachment() async {
    if (_isUploadingAttachment || _isLocked) return;

    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
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
      final sent = await _chatService.sendAttachment(
        campaignId: widget.campaignId,
        filePath: filePath,
      );
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, sent];
        _isUploadingAttachment = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      if (e is CampaignChatAccessException) {
        _handleAccessDenied(e.message);
        return;
      }
      setState(() => _isUploadingAttachment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_readableErrorMessage(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _insertEmoji(String emoji) {
    if (_isLocked) return;

    final text = _messageController.text;
    final selection = _messageController.selection;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    final newText = text.replaceRange(start, end, emoji);

    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.campaignTitle;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 78,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Phòng chat chiến dịch',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.participantCount} thành viên',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4FBF8), Color(0xFFF4FBF8), Color(0xFFF4FBF8)],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(title),
            Expanded(child: _buildBody()),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.recycling_rounded,
              color: Color(0xFF2F9A5A),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.participantCount} thành viên',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Color(0xFF7A7A7A))),
                    const SizedBox(width: 8),
                    const Text(
                      'Đang diễn ra',
                      style: TextStyle(
                        color: Color(0xFF2F9A5A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Trao đổi nhanh trong chiến dịch',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey.shade400,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7FAE8C)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialMessages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7FAE8C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF2E7D32),
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chưa có tin nhắn nào',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Mở lời đầu tiên để kết nối với những người cùng tham gia chiến dịch.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 14),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final previous = index > 0 ? _messages[index - 1] : null;
        final showSenderHeader =
            previous == null || previous.senderUserId != message.senderUserId;
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
          child: _MessageBubble(
            message: message,
            showSenderHeader: showSenderHeader,
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFF79A98A).withOpacity(0.18))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: _isUploadingAttachment ? null : _pickAndSendAttachment,
              icon: _isUploadingAttachment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Color(0xFF2E7D32),
                    ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F3),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Nhắn một điều tích cực cho chiến dịch...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: _isSending ? null : _sendMessage,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final CampaignChatMessage message;
  final bool showSenderHeader;

  const _MessageBubble({
    required this.message,
    required this.showSenderHeader,
  });

  String _timeLabel(DateTime value) {
    return DateFormat('HH:mm').format(value);
  }

  String _avatarFallback(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : 'U';
    }
    final first = parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
    final last = parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';
    final initials = '$first$last'.trim();
    return initials.isEmpty ? 'U' : initials;
  }

  Widget _avatarText(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2F9A5A),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = message.senderAvatarUrl.trim();
    final fallback = _avatarFallback(message.senderFullName);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF1F8F3),
        border: Border.all(color: const Color(0xFFE1EAE4)),
      ),
      child: ClipOval(
        child: avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarText(fallback),
              )
            : _avatarText(fallback),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.mine ? const Color(0xFF2E7D32) : Colors.white;
    final textColor = message.mine ? Colors.white : const Color(0xFF243423);
    final borderRadius = message.mine
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          );

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.76,
      ),
      child: Column(
        crossAxisAlignment: message.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSenderHeader && !message.mine)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 4),
              child: Text(
                message.senderFullName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.message.trim().isNotEmpty)
                  Text(
                    message.message,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                if (message.hasAttachment) ...[
                  if (message.message.trim().isNotEmpty) const SizedBox(height: 8),
                  _AttachmentPreview(message: message),
                ],
                const SizedBox(height: 6),
                Text(
                  _timeLabel(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: message.mine ? Colors.white70 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (message.mine) {
      return Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            bubble,
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 10),
          bubble,
        ],
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final CampaignChatMessage message;

  const _AttachmentPreview({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isImageAttachment) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          message.attachmentUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.broken_image_outlined),
                SizedBox(width: 8),
                Text('Không tải được ảnh đính kèm'),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
