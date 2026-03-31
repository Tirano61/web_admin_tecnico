import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/precios/data/precios_repository_impl.dart';
import 'package:web_admin_tecnico/features/precios/presentation/bloc/precios_bloc.dart';

class PreciosPage extends StatelessWidget {
  const PreciosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PreciosBloc>(
      create: (_) => PreciosBloc(PreciosRepositoryImpl())..add(PreciosRequested()),
      child: const _PreciosView(),
    );
  }
}

class _PreciosView extends StatelessWidget {
  const _PreciosView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: BlocBuilder<PreciosBloc, PreciosState>(
        builder: (context, state) {
          if (state is PreciosLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PreciosFailure) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is PreciosLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Precios', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.descripcion),
                          subtitle: Text('Valor: ${item.valor} - ID: ${item.id}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
