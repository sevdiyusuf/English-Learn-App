import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../logic/arena_lobby_controller.dart';
import '../../../../core/widgets/gradient_background.dart';

class ArenaHomePage extends ConsumerStatefulWidget {
  const ArenaHomePage({super.key});

  @override
  ConsumerState<ArenaHomePage> createState() => _ArenaHomePageState();
}

class _ArenaHomePageState extends ConsumerState<ArenaHomePage> {
  final _joinCodeController = TextEditingController();
  String _selectedLevel = 'A1'; // Default

  @override
  Widget build(BuildContext context) {
    // Listen for navigation
    ref.listen(arenaLobbyControllerProvider, (prev, next) {
      if (next.hasValue && next.value != null) {
        // Navigate to Waiting Room with roomId
        // We need to clear the state so we don't navigate again if we come back?
        // But stateNotifier state persists.
        // We should probably rely on router parameters or check if we are already there.
        // For now, just push.
        context.push('/multiplayer/grammar-arena/room/${next.value}');
      } else if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.error}')),
        );
      }
    });

    final state = ref.watch(arenaLobbyControllerProvider);
    final isLoading = state.isLoading;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Grammar Arena'), backgroundColor: Colors.transparent),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CREATE ROOM SECTION
              _buildSectionHeader('Oda Oluştur'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        decoration: const InputDecoration(labelText: 'Seviye'),
                        items: ['A1', 'A2', 'B1', 'B2'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                        onChanged: (val) => setState(() => _selectedLevel = val!),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () {
                             ref.read(arenaLobbyControllerProvider.notifier).createRoom(level: _selectedLevel);
                          },
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          child: isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : const Text('Oluştur ve Arkadaşını Davet Et'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // JOIN ROOM SECTION
              _buildSectionHeader('Odaya Katıl'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _joinCodeController,
                        decoration: const InputDecoration(labelText: 'Oda Kodu (5 haneli)'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () {
                             if (_joinCodeController.text.length == 5) {
                                ref.read(arenaLobbyControllerProvider.notifier).joinRoom(_joinCodeController.text);
                             }
                          },
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          child: isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : const Text('Odaya Katıl'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}
