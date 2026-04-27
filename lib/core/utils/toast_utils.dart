import 'package:flutter/material.dart';

/// Modern ve şık bir başarı bildirimi gösterir.
/// Kullanımı: showSuccessToast(context, "Link kopyalandı!");
void showSuccessToast(BuildContext context, String message) {
  // Varsa ekrandaki eski bildirimi temizle
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.greenAccent,
            ),
            child: const Icon(Icons.check, color: Colors.black87, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                fontFamily: 'Roboto', // Varsa uygulamanın fontunu yazabilirsin
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF2C2C2C), // Modern koyu gri arka plan
      behavior: SnackBarBehavior.floating, // Ekranın altında süzülen stil
      elevation: 6,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30), // Kenar boşlukları
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Yuvarlatılmış köşeler
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'GİZLE',
        textColor: Colors.grey,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}
