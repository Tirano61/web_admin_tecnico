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

  static const double _scale = 0.8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
          (constraints.maxWidth < 720 ? 14.0 : 22.0) * _scale;
        final verticalPadding =
          (constraints.maxWidth < 720 ? 14.0 : 22.0) * _scale;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            18 * _scale,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xAA0C2440),
              borderRadius: BorderRadius.circular(18 * _scale),
              border: Border.all(color: const Color(0x3357AAE5)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF030C17).withValues(alpha: 0.38),
                  blurRadius: 24 * _scale,
                  offset: Offset(0, 10 * _scale),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20 * _scale,
                18 * _scale,
                20 * _scale,
                18 * _scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 3 * _scale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF63C7FF), Color(0xFF17B386)],
                      ),
                    ),
                  ),
                  SizedBox(height: 14 * _scale),
                  LayoutBuilder(
                    builder: (context, headerConstraints) {
                      final compactHeader = headerConstraints.maxWidth < 900;

                      final titleBlock = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: 26 * _scale,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF2F8FF),
                                ),
                          ),
                          SizedBox(height: 6 * _scale),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF9FB8D3),
                                  fontSize: 13 * _scale,
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
                            SizedBox(height: 12 * _scale),
                            SizedBox(
                              width: double.infinity,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: trailing!,
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: titleBlock),
                          SizedBox(width: 16 * _scale),
                          Flexible(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: trailing!,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 16 * _scale),
                  const Divider(color: Color(0x334EA6FF), height: 1),
                  SizedBox(height: 14 * _scale),
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

  static const double _scale = 0.8;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * _scale, vertical: 5 * _scale),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12 * _scale,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
