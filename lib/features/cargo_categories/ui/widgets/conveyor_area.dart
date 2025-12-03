import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/cargo_word.dart';
import 'word_box.dart';

class _AnimatingWordData {
  final String id;
  final CargoWord fullWord;

  _AnimatingWordData({required this.id, required this.fullWord});
}

class ConveyorArea extends StatefulWidget {
  const ConveyorArea({
    required this.currentWord,
    required this.travelDuration,
    required this.onTimeout,
    super.key,
  });

  final CargoWord? currentWord;
  final Duration travelDuration;
  final VoidCallback onTimeout;

  @override
  State<ConveyorArea> createState() => _ConveyorAreaState();
}

class _ConveyorAreaState extends State<ConveyorArea> {
  double? _screenWidth;
  double _currentX = 0;
  Timer? _animationTimer;
  _AnimatingWordData? _activeWordData;
  bool _isDropped = false;

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _startAnimation(CargoWord word, double width) {
    // 1. Zaten aynı kelime oynuyorsa DOKUNMA.
    // Controller sürekli aynı kelimeyi gönderse bile animasyonu resetleme.
    if (_activeWordData?.id == word.word && _animationTimer != null) {
      return;
    }

    // 2. Yeni kelime geldiyse eskisini temizle
    _stopAnimation();

    // 3. Veriyi yerel değişkene al (Controller'dan kopar)
    _activeWordData = _AnimatingWordData(id: word.word, fullWord: word);
    _isDropped = false; // Yeni kelime, henüz bırakılmadı.

    if (kDebugMode) {
      debugPrint('ConveyorArea: Starting animation for ${_activeWordData!.id}');
    }

    final boxWidth = 160.0;
    final beginX = width + 20;
    final endX = -boxWidth - 20;

    _currentX = beginX;

    final totalDistance = beginX - endX;
    final totalDurationMs = widget.travelDuration.inMilliseconds;
    final frameDuration = const Duration(milliseconds: 32);
    final totalFrames = (totalDurationMs / frameDuration.inMilliseconds).ceil();

    if (kDebugMode) {
      debugPrint(
        'ConveyorArea: Animasyon parametreleri - duration: ${totalDurationMs}ms, frames: $totalFrames, distance: ${totalDistance.toStringAsFixed(1)}',
      );
    }

    int frameCount = 0;

    _animationTimer = Timer.periodic(frameDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      frameCount++;
      final progress = frameCount / totalFrames;

      if (progress >= 1.0) {
        // --- BİTİŞ ---
        timer.cancel();
        _animationTimer = null;
        _currentX = endX;

        if (mounted) {
          setState(() {});

          // Animasyon bitti ve kullanıcı kelimeyi tutmadıysa Timeout çağır
          Future.microtask(() {
            if (mounted &&
                _activeWordData != null &&
                !_isDropped &&
                _animationTimer == null) {
              debugPrint(
                "ConveyorArea: Timeout triggered for ${_activeWordData!.id}",
              );
              widget.onTimeout();
            } else {
              if (kDebugMode) {
                debugPrint(
                  "ConveyorArea: Timeout atlandı - isDropped: $_isDropped, activeWordData: ${_activeWordData?.id}, timer: $_animationTimer",
                );
              }
            }
          });
        }
      } else {
        // --- DEVAM ---
        if (mounted) {
          setState(() {
            _currentX = beginX - (totalDistance * progress);
          });
        }
      }
    });
  }

  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    _activeWordData = null;
    _currentX = 0;
    _isDropped = false;
  }

  @override
  void didUpdateWidget(ConveyorArea oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newWord = widget.currentWord;
    final oldWordId = oldWidget.currentWord?.word;
    final newWordId = newWord?.word;

    // --- KRİTİK DÜZELTME BURADA ---

    // Sadece YENİ ve DOLU bir kelime gelirse animasyonu değiştir.
    if (newWord != null && newWordId != oldWordId) {
      if (_screenWidth != null) {
        debugPrint("ConveyorArea: New word detected: ${newWord.word}");
        _startAnimation(newWord, _screenWidth!);
      }
    }

    // DİKKAT: "else if (newWord == null)" BLOĞUNU TAMAMEN SİLDİM.
    // Controller null gönderirse, görmezden geliyoruz ve mevcut animasyon devam ediyor.
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final newWidth = constraints.maxWidth;

        // Ekran genişliği ilk kez hesaplanıyorsa veya değiştiyse
        if (_screenWidth == null || _screenWidth != newWidth) {
          _screenWidth = newWidth;

          // İlk açılış: Eğer ekranda kelime yoksa ve Controller'da kelime varsa başlat
          if (widget.currentWord != null &&
              _activeWordData == null &&
              newWidth > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _startAnimation(widget.currentWord!, newWidth);
            });
          }
        }

        return SizedBox(
          height: 120,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Bant Arka Planı
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade700, width: 1),
                  ),
                  child: CustomPaint(painter: _BeltPatternPainter()),
                ),
              ),

              // 2. Hareketli Kelime
              // _activeWordData olduğu sürece göster. Controller null olsa bile bu veri bizde saklı.
              if (_activeWordData != null && !_isDropped)
                Positioned(
                  left: _currentX,
                  bottom: 0,
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: Draggable<CargoWord>(
                      data: _activeWordData!.fullWord,

                      // Başarıyla bırakıldığında (CategoryDock veya SaveBar kabul ederse)
                      onDragCompleted: () {
                        if (mounted) {
                          debugPrint(
                            "ConveyorArea: Drag Completed (Dropped) - Timer iptal ediliyor",
                          );
                          // Timer'ı durdur - artık timeout çağrılmayacak
                          _animationTimer?.cancel();
                          _animationTimer = null;
                          setState(() {
                            _isDropped = true; // Kelimeyi ekrandan sil
                            _activeWordData = null; // Veriyi temizle
                          });
                        }
                      },
                      // Drag iptal edildiğinde (kelime hiçbir yere bırakılmadı)
                      onDragEnd: (details) {
                        // Eğer kelime hiçbir DragTarget'a bırakılmadıysa, animasyonu devam ettir
                        if (mounted && !_isDropped && _activeWordData != null) {
                          debugPrint(
                            "ConveyorArea: Drag End - Kelime bırakılmadı, animasyon devam ediyor",
                          );
                          // Animasyon devam edecek, timeout normal şekilde çalışacak
                        }
                      },

                      feedback: Material(
                        color: Colors.transparent,
                        child: WordBox(
                          english: _activeWordData!.fullWord.word,
                          turkish: _activeWordData!.fullWord.translate,
                        ),
                      ),

                      // Sürüklerken arkada boşluk bırak
                      childWhenDragging: const SizedBox(),

                      child: WordBox(
                        english: _activeWordData!.fullWord.word,
                        turkish: _activeWordData!.fullWord.translate,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BeltPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.shade700
          ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_BeltPatternPainter oldDelegate) => false;
}
