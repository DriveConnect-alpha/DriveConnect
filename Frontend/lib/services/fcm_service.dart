import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../calls/notification.call.dart';
import '../calls/api_core.dart' show isAuthenticated, currentUserId;
import '../core/router/app_router.dart';

const _kPendingRemovalKey = 'fcm_pending_removal_token';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  String? _currentToken;
  String? _lastRegisteredToken;
  String? _lastRegisteredUserId;

  Future<void> init() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('[FCM] Permissão de notificação negada.');
      return;
    }

    _currentToken = await _fcm.getToken();
    debugPrint('[FCM] Token obtido: ${_currentToken != null ? '...${_currentToken!.substring(_currentToken!.length - 8)}' : 'null'}');

    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token atualizado.');
      _currentToken = newToken;
      _registerIfAuthenticated();
    });

    // Foreground messages → show in-app banner
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Tenta flush de remoções pendentes (offline logout anterior)
    await _flushPendingRemoval();
  }

  // ─── Foreground notification banner ───────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Mensagem foreground: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    final theme = Theme.of(context);
    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _InAppNotificationBanner(
        title: notification.title ?? 'Notificação',
        body: notification.body ?? '',
        theme: theme,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  // ─── Token registration ───────────────────────────────────────────────────

  Future<void> _registerIfAuthenticated() async {
    if (!isAuthenticated || _currentToken == null) return;

    final userId = currentUserId;
    // Skip only if same token AND same user
    if (_lastRegisteredToken == _currentToken && _lastRegisteredUserId == userId) {
      return;
    }

    await saveFcmToken(
      token: _currentToken!,
      plataforma: Platform.isAndroid ? 'android' : 'ios',
      onSuccess: () {
        debugPrint('[FCM] Token registrado para user $userId');
        _lastRegisteredToken = _currentToken;
        _lastRegisteredUserId = userId;
      },
      onError: (err) => debugPrint('[FCM] Erro ao registrar token: $err'),
    );
  }

  /// Called after login or session restore to register the FCM token
  /// for the currently authenticated user.
  Future<void> onUserAuthenticated() async {
    // Flush any pending removal from a previous logout that failed offline
    await _flushPendingRemoval();

    // Force re-registration even if the device token is the same,
    // because the user changed.
    _lastRegisteredToken = null;
    _lastRegisteredUserId = null;

    if (_currentToken == null) {
      _currentToken = await _fcm.getToken();
    }

    await _registerIfAuthenticated();
  }

  /// Called on logout. Removes the token from backend so the old user
  /// stops receiving notifications on this device.
  Future<void> onUserLogout() async {
    final token = _currentToken ?? _lastRegisteredToken;
    _lastRegisteredToken = null;
    _lastRegisteredUserId = null;

    if (token == null || token.isEmpty) return;

    try {
      await removeFcmToken(
        token: token,
        onSuccess: () => debugPrint('[FCM] Token removido do backend no logout.'),
        onError: (err) {
          debugPrint('[FCM] Falha ao remover token (enfileirando): $err');
          _enqueuePendingRemoval(token);
        },
      );
    } catch (_) {
      // Network failure — queue for later
      _enqueuePendingRemoval(token);
    }
  }

  // ─── Pending removal queue (offline logout) ───────────────────────────────

  Future<void> _enqueuePendingRemoval(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPendingRemovalKey, token);
      debugPrint('[FCM] Token enfileirado para remoção futura.');
    } catch (_) {}
  }

  Future<void> _flushPendingRemoval() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingToken = prefs.getString(_kPendingRemovalKey);
      if (pendingToken == null || pendingToken.isEmpty) return;

      if (!isAuthenticated) return; // need auth to call the API

      await removeFcmToken(
        token: pendingToken,
        onSuccess: () async {
          await prefs.remove(_kPendingRemovalKey);
          debugPrint('[FCM] Token pendente removido com sucesso.');
        },
        onError: (err) => debugPrint('[FCM] Ainda não conseguiu remover token pendente: $err'),
      );
    } catch (_) {}
  }
}

// ─── In-App Notification Banner Widget ────────────────────────────────────────

class _InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final ThemeData theme;
  final VoidCallback onDismiss;

  const _InAppNotificationBanner({
    required this.title,
    required this.body,
    required this.theme,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<_InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.theme.colorScheme;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy < -100) _dismiss();
            },
            onTap: _dismiss,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.inverseSurface,
              shadowColor: Colors.black26,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: colorScheme.onInverseSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.body.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.body,
                              style: TextStyle(
                                color: colorScheme.onInverseSurface.withOpacity(0.8),
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.close_rounded,
                      color: colorScheme.onInverseSurface.withOpacity(0.5),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
