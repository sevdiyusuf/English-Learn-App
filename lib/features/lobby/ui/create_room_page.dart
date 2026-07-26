import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/utils/input_validator.dart';
import '../logic/room_controller.dart';

class CreateRoomPage extends ConsumerStatefulWidget {
  const CreateRoomPage({super.key});

  static const routeName = 'create-room';

  @override
  ConsumerState<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends ConsumerState<CreateRoomPage> {
  double _turnDuration = 12;
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Load saved username from storage
    final savedUsername = StorageService.getUsername();
    if (savedUsername != null && savedUsername.isNotEmpty) {
      _usernameController.text = savedUsername;
    }
  }

  @override
  void dispose() {
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
        title: const Text('Oda oluştur'),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Kullanıcı adınız',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 20,
                          desktop: 22,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing * 2),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Kullanıcı adı',
                        hintText: 'Örn: Ahmet',
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
                    SizedBox(height: spacing * 3),
                    Text(
                      'Tur süresini seç',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 20,
                          desktop: 22,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing * 2),
                    Slider(
                      value: _turnDuration,
                      min: 8,
                      max: 45,
                      divisions: 37,
                      label: '${_turnDuration.round()} sn',
                      onChanged: (value) {
                        setState(() => _turnDuration = value);
                      },
                    ),
                    Text(
                      'Tur süresi: ${_turnDuration.round()} saniye',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
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
                                try {
                                  final username =
                                      _usernameController.text.trim();

                                  // Validate username
                                  final usernameError =
                                      InputValidator.validateUsername(username);
                                  if (usernameError != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(usernameError),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  // Save username to storage
                                  await StorageService.saveUsername(username);

                                  // createRoom now returns document ID, not roomCode
                                  final roomId = await ref
                                      .read(roomControllerProvider.notifier)
                                      .createRoom(
                                        username: username,
                                        turnDurationSeconds:
                                            _turnDuration.round(),
                                      );

                                  // Save room ID to storage
                                  await StorageService.saveRoomId(roomId);

                                  if (!mounted || !context.mounted) return;
                                  context.go('/room/$roomId');
                                } on Object catch (err) {
                                  if (!mounted || !context.mounted) return;
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('$err')),
                                  );
                                }
                              },
                      icon: const Icon(Icons.check_circle_outline),
                      label:
                          controllerState.isLoading
                              ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Oluştur ve devam et'),
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
