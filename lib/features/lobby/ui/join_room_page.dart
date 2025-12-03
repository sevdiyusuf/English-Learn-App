import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/utils/input_validator.dart';
import '../logic/room_controller.dart';

class JoinRoomPage extends ConsumerStatefulWidget {
  const JoinRoomPage({
    super.key,
    this.initialRoomId,
    this.initialTurnDurationSeconds,
  });

  static const routeName = 'join-room';

  final String? initialRoomId;
  final int? initialTurnDurationSeconds;

  @override
  ConsumerState<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends ConsumerState<JoinRoomPage> {
  late final TextEditingController _roomController;
  final TextEditingController _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Load saved data from storage
    final savedRoomCode = StorageService.getRoomCode();
    final savedUsername = StorageService.getUsername();
    
    _roomController = TextEditingController(
      text: widget.initialRoomId ?? savedRoomCode ?? '',
    );
    
    if (savedUsername != null && savedUsername.isNotEmpty) {
      _usernameController.text = savedUsername;
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(roomControllerProvider);

    final padding = ResponsiveUtils.responsivePadding(context);
    final spacing = ResponsiveUtils.responsiveSpacing(context);
    final maxWidth = ResponsiveUtils.responsive<double>(
      context: context,
      mobile: double.infinity,
      tablet: 500,
      desktop: 600,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
        title: const Text('Odaya katıl'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: AdaptiveContainer(
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Kullanıcı adı',
                        hintText: 'Örn: Mehmet',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      maxLength: 20,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Kullanıcı adı zorunlu';
                        }
                        if ((value ?? '').trim().length < 2) {
                          return 'Kullanıcı adı en az 2 karakter olmalı';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: spacing * 2),
                    TextFormField(
                      controller: _roomController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Oda kodu (5 haneli)',
                        hintText: 'Örn: 12345',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 5,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Oda kodu zorunlu';
                        }
                        if ((value ?? '').trim().length != 5) {
                          return 'Oda kodu 5 haneli olmalı';
                        }
                        if (int.tryParse(value ?? '') == null) {
                          return 'Oda kodu sadece sayılardan oluşmalı';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: spacing * 3),
                    FilledButton.icon(
                      onPressed:
                          controllerState.isLoading
                              ? null
                              : () async {
                                final isValid =
                                    _formKey.currentState?.validate() ?? false;
                                if (!isValid) return;
                                final roomCode = _roomController.text.trim();
                                final username = _usernameController.text.trim();
                                
                                // Validate inputs
                                final usernameError = InputValidator.validateUsername(username);
                                if (usernameError != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(usernameError),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                final roomCodeError = InputValidator.validateRoomCode(roomCode);
                                if (roomCodeError != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(roomCodeError),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                try {
                                  // Save username and room code to storage
                                  await StorageService.saveUsername(username);
                                  await StorageService.saveRoomCode(roomCode);
                                  
                                  await ref
                                      .read(roomControllerProvider.notifier)
                                      .joinRoom(
                                        roomCode: roomCode,
                                        username: username,
                                      );
                                  
                                  if (!mounted || !context.mounted) return;
                                  context.go('/room/$roomCode');
                                } on Object catch (err) {
                                  if (!mounted || !context.mounted) return;
                                  final messenger = ScaffoldMessenger.of(context);
                                  messenger.showSnackBar(SnackBar(content: Text('$err')));
                                }
                              },
                      icon:
                          controllerState.isLoading
                              ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                              : const Icon(Icons.login),
                      label: const Text('Katıl'),
                    ),
                    if (widget.initialTurnDurationSeconds != null) ...[
                      SizedBox(height: spacing * 2),
                      Text(
                        'Tur süresi: ${widget.initialTurnDurationSeconds} saniye',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
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
