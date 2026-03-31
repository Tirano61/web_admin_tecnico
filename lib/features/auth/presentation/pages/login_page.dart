import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/auth/session_store.dart';
import 'package:web_admin_tecnico/core/routing/app_routes.dart';
import 'package:web_admin_tecnico/features/auth/data/auth_repository_impl.dart';
import 'package:web_admin_tecnico/features/auth/presentation/bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(AuthRepositoryImpl()),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFF07162A), Color(0xFF0A1D35), Color(0xFF081728)],
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(painter: _CircuitBackgroundPainter()),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: BlocListener<AuthBloc, AuthState>(
                    listener: (context, state) {
                      if (state is AuthAuthenticated) {
                        SessionStore.setSession(state.session);
                        Navigator.of(context).pushReplacementNamed(AppRoutes.servicios);
                      }

                      if (state is AuthFailureState) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.message)),
                        );
                      }
                    },
                    child: Column(
                      children: <Widget>[
                        const _TopBar(),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 520),
                                child: _LoginPanel(
                                  formKey: _formKey,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const _FooterBar(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 36),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: const Color(0xFF4EA6FF).withOpacity(0.25))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.memory_rounded, color: Color(0xFF5AA7FF), size: 34),
              const SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: 'Tech',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFFF4F9FF),
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                            letterSpacing: -0.2,
                            height: 1,
                          ),
                    ),
                    TextSpan(
                      text: 'Admin',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFFF4F9FF),
                            fontWeight: FontWeight.w400,
                            fontSize: 26,
                            letterSpacing: -0.2,
                            height: 1,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            '>- TERMINAL SEGURA',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF8DA4C0),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                  height: 1,
                ),
          ),
        ],
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B203C).withOpacity(0.52),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4EA6FF).withOpacity(0.24)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF08131F).withOpacity(0.55),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(36, 34, 36, 26),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Acceso Interno',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: const Color(0xFFF2F7FF),
                    fontWeight: FontWeight.w500,
                    fontSize: 46,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Portal de Excelencia Tecnica Administrativa. Por favor,\nidentifiquese para acceder al cluster de gestion.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF9AB1CC),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 28),
            _PanelFieldLabel(label: 'USUARIO'),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailController,
              style: const TextStyle(
                color: Color(0xFFDCE9FF),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                height: 1,
              ),
              decoration: _panelInputDecoration(hintText: 'ej. j.arquitecto'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un usuario';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _PanelFieldLabel(label: 'CONTRASENA'),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(
                color: Color(0xFFDCE9FF),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                height: 1,
              ),
              decoration: _panelInputDecoration(hintText: '••••••••'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa una contrasena';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0FA960),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            if (formKey.currentState?.validate() ?? false) {
                              context.read<AuthBloc>().add(
                                    AuthSubmitted(
                                      email: emailController.text,
                                      password: passwordController.text,
                                    ),
                                  );
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Iniciar sesion',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                              height: 1,
                            ),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
           
          ],
        ),
      ),
    );
  }

  InputDecoration _panelInputDecoration({required String hintText}) {
    const borderColor = Color(0xFF2E7BC8);
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF8199B7),
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFF122B4A),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF52B4FF), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF6A6A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF8585), width: 1.4),
      ),
    );
  }
}

class _PanelFieldLabel extends StatelessWidget {
  const _PanelFieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFFC5D3E7),
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 0.5,
            height: 1,
          ),
    );
  }
}

class _FooterBar extends StatelessWidget {
  const _FooterBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: const Color(0xFF4EA6FF).withOpacity(0.25))),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '© 2024 TechAdmin. Todos los derechos reservados. Politica de Privacidad.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8FA7C4),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'SISTEMA PROPIETARIO SOLO PARA PERSONAL AUTORIZADO',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8FA7C4),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                    height: 1,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircuitBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0x001E6DC2), Color(0x33226BBA), Color(0x001A5BA0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Offset.zero & size, glowPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF2F6FAE).withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final dotPaint = Paint()
      ..color = const Color(0xFF4EA6FF).withOpacity(0.22)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, size.height * 0.22)
      ..lineTo(size.width * 0.3, size.height * 0.22)
      ..lineTo(size.width * 0.35, size.height * 0.18)
      ..lineTo(size.width * 0.45, size.height * 0.18)
      ..lineTo(size.width * 0.48, size.height * 0.15)
      ..lineTo(size.width * 0.62, size.height * 0.15);

    final path2 = Path()
      ..moveTo(size.width * 0.72, size.height * 0.78)
      ..lineTo(size.width * 0.92, size.height * 0.78)
      ..lineTo(size.width * 0.92, size.height * 0.63)
      ..lineTo(size.width * 0.98, size.height * 0.63);

    final path3 = Path()
      ..moveTo(size.width * 0.05, size.height * 0.86)
      ..lineTo(size.width * 0.2, size.height * 0.86)
      ..lineTo(size.width * 0.24, size.height * 0.9)
      ..lineTo(size.width * 0.37, size.height * 0.9)
      ..lineTo(size.width * 0.4, size.height * 0.95);

    final path4 = Path()
      ..moveTo(size.width * 0.73, size.height * 0.18)
      ..lineTo(size.width * 0.88, size.height * 0.18)
      ..lineTo(size.width * 0.88, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.3);

    canvas.drawPath(path1, linePaint);
    canvas.drawPath(path2, linePaint);
    canvas.drawPath(path3, linePaint);
    canvas.drawPath(path4, linePaint);

    final dots = <Offset>[
      Offset(size.width * 0.35, size.height * 0.18),
      Offset(size.width * 0.48, size.height * 0.15),
      Offset(size.width * 0.24, size.height * 0.9),
      Offset(size.width * 0.92, size.height * 0.78),
      Offset(size.width * 0.88, size.height * 0.3),
    ];

    for (final dot in dots) {
      canvas.drawCircle(dot, 5.5, dotPaint);
      canvas.drawCircle(
        dot,
        1.8,
        Paint()..color = const Color(0xFF8FD0FF).withOpacity(0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
