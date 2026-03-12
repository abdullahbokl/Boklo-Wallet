import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/features/payment_requests/domain/entity/payment_request_entity.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_cubit.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_state.dart';
import 'package:boklo/features/payment_requests/presentation/widgets/payment_request_item.dart';
import 'package:boklo/shared/widgets/molecules/app_empty_state.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentRequestListPage extends StatelessWidget {
  const PaymentRequestListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PaymentRequestCubit>()..init(),
      child: DefaultTabController(
        length: 2,
        child: AppPageScaffold(
          title: 'Payment requests',
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => getIt<NavigationService>()
                  .push('/payment-requests/create'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Incoming'),
              Tab(text: 'Outgoing'),
            ],
          ),
          child: BlocBuilder<PaymentRequestCubit, BaseState<PaymentRequestState>>(
            builder: (context, state) {
              final data = state.data ?? const PaymentRequestState();
              return TabBarView(
                children: [
                  _RequestList(
                    requests: data.incomingRequests,
                    actingOnId: data.actingOnRequestId,
                  ),
                  _RequestList(
                    requests: data.outgoingRequests,
                    isOutgoing: true,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.requests,
    this.actingOnId,
    this.isOutgoing = false,
  });

  final List<PaymentRequestEntity> requests;
  final String? actingOnId;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return AppEmptyState(
        icon: isOutgoing ? Icons.outbox_outlined : Icons.move_to_inbox_outlined,
        title: 'No ${isOutgoing ? 'outgoing' : 'incoming'} requests',
        subtitle: isOutgoing
            ? 'Requests you send will appear here.'
            : 'Requests sent to you will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return PaymentRequestItem(
          request: request,
          isOutgoing: isOutgoing,
          isLoading: actingOnId == request.id,
        );
      },
    );
  }
}
