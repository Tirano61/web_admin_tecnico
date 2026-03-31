import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/clientes/data/clientes_repository_impl.dart';
import 'package:web_admin_tecnico/features/clientes/presentation/bloc/clientes_bloc.dart';

class ClientesPage extends StatelessWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClientesBloc>(
      create: (_) => ClientesBloc(ClientesRepositoryImpl())..add(ClientesRequested()),
      child: const _ClientesView(),
    );
  }
}

class _ClientesView extends StatelessWidget {
  const _ClientesView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: BlocBuilder<ClientesBloc, ClientesState>(
        builder: (context, state) {
          if (state is ClientesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ClientesFailure) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is ClientesLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Clientes', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.nombre),
                          subtitle: Text('ID: ${item.id}'),
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
