import 'package:flutter/material.dart';
import 'package:web_admin_tecnico/core/widgets/tech_admin_background.dart';

/// Pantalla de espera mientras se lee la sesion persistida al arrancar.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TechAdminBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: const Color(0x194FC2FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x555FB7ED)),
                ),
                child: const Icon(
                  Icons.memory_rounded,
                  color: Color(0xFF9BD5FF),
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'TechAdmin Operativo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFFF2F8FF),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Restaurando sesion...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9FB9D5),
                    ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF69C3FF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
