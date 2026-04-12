import 'package:flutter/material.dart';

class ModulePageLayout extends StatelessWidget {
  const ModulePageLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 720 ? 14.0 : 22.0;
        final verticalPadding = constraints.maxWidth < 720 ? 14.0 : 22.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, verticalPadding, horizontalPadding, 18),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xAA0C2440),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x3357AAE5)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF030C17).withOpacity(0.38),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF63C7FF), Color(0xFF17B386)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, headerConstraints) {
                      final compactHeader = headerConstraints.maxWidth < 900;

                      final titleBlock = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF2F8FF),
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF9FB8D3),
                                  fontSize: 13,
                                ),
                          ),
                        ],
                      );

                      if (trailing == null) {
                        return titleBlock;
                      }

                      if (compactHeader) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            titleBlock,
                            const SizedBox(height: 12),
                            trailing!,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: titleBlock),
                          const SizedBox(width: 16),
                          trailing!,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0x334EA6FF), height: 1),
                  const SizedBox(height: 14),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ModuleStatusChip extends StatelessWidget {
  const ModuleStatusChip({
    super.key,
    required this.label,
    this.backgroundColor = const Color(0x1F4EA6FF),
    this.foregroundColor = const Color(0xFFCDE4FF),
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foregroundColor.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
