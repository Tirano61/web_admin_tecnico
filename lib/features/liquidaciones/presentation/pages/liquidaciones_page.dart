import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/liquidaciones/data/liquidaciones_repository_impl.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_bloc.dart';

class LiquidacionesPage extends StatelessWidget {
  const LiquidacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiquidacionesBloc>(
      create: (_) =>
          LiquidacionesBloc(LiquidacionesRepositoryImpl())..add(LiquidacionesRequested()),
      child: const _LiquidacionesView(),
    );
  }
}

class _LiquidacionesView extends StatelessWidget {
  const _LiquidacionesView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: BlocBuilder<LiquidacionesBloc, LiquidacionesState>(
        builder: (context, state) {
          if (state is LiquidacionesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LiquidacionesFailure) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is LiquidacionesLoaded) {
            return _LiquidacionesList(items: state.items);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LiquidacionesList extends StatelessWidget {
  const _LiquidacionesList({required this.items});

  final List<LiquidacionItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Liquidaciones', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  title: Text('Liquidacion ${item.id}'),
                  subtitle: Text(
                    'Servicio: ${item.servicioId} | USD: ${item.montoUsd} | Aprobada: ${item.aprobada}',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
