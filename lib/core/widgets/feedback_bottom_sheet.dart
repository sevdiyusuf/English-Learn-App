import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/auth/logic/auth_controller.dart';

class FeedbackBottomSheet extends ConsumerStatefulWidget {
  final String pageName;

  const FeedbackBottomSheet({super.key, required this.pageName});

  static Future<void> show(BuildContext context, {required String pageName}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FeedbackBottomSheet(pageName: pageName),
    );
  }

  @override
  ConsumerState<FeedbackBottomSheet> createState() =>
      _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends ConsumerState<FeedbackBottomSheet> {
  final _controller = TextEditingController();
  bool _isSending = false;
  bool _isSent = false;

  static const _botToken = '8595706735:AAHWqiWzgN-XiHmLnJtiC-jzMeNKvO5Ajv4';
  static const _chatId = '8130166874';

  Future<void> _sendFeedback() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Get App Version
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      // Get Device Info
      final deviceInfo = DeviceInfoPlugin();
      String deviceModel = 'Bilinmiyor';
      String osVersion = 'Bilinmiyor';

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceModel = webInfo.browserName.name;
        osVersion = webInfo.platform ?? 'Web';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        osVersion =
            'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine;
        osVersion = 'iOS ${iosInfo.systemVersion}';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceModel = 'Windows PC';
        osVersion =
            'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        deviceModel = macInfo.model;
        osVersion = 'macOS ${macInfo.osRelease}';
      }

      // Get User Info
      final authState = ref.read(authControllerProvider);
      final user = authState.value;
      final userInfo = user != null && !user.isGuestMode ? user.uid : 'Anonim';

      // Prepare Message
      final message = '''
<b>🔔 Yeni Geri Bildirim</b>

<b>Kullanıcı Mesajı:</b>
$text

<b>📱 Teknik Veriler:</b>
<code>Kullanıcı: $userInfo
Sayfa: ${widget.pageName}
Uygulama Sürümü: $appVersion
Cihaz Modeli: $deviceModel
OS Versiyonu: $osVersion</code>
''';

      // Send to Telegram
      final url = Uri.parse(
        'https://api.telegram.org/bot$_botToken/sendMessage',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _chatId,
          'text': message,
          'parse_mode': 'HTML',
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isSent = true;
          _isSending = false;
        });

        // Close after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        throw Exception('Failed to send feedback: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata oluştu: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ana sayfa temasına uyumlu renkler
    const backgroundColor = Color(0xFF1C1C1E);
    const accentColor = Color(0xFF2997FF);
    const borderColor = Color(0x1AFFFFFF); // white.withOpacity(0.1)

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            if (_isSent) ...[
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Teşekkürler!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Geri bildiriminiz başarıyla iletildi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              const Text(
                'Geri Bildirim',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Karşılaştığınız sorunu veya önerinizi bizimle paylaşın.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Mesajınızı buraya yazın...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: accentColor, width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _isSending ? null : _sendFeedback,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      _isSending
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                          : const Text(
                            'Gönder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
