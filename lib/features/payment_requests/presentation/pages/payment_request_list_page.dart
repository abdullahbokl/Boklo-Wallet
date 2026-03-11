import 'package:boklo/config/theme/app_decorations.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/features/payment_requests/domain/entity/payment_request_entity.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_cubit.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_state.dart';
import 'package:boklo/features/payment_requests/presentation/widgets/payment_request_item.dart';
import 'package:boklo/shared/responsive/responsive_constraint.dart';
import 'package:boklo/shared/widgets/molecules/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentRequestListPage extends StatelessWidget {
  const PaymentRequestListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PaymentRequestCubit>()..init(),
      child: DefaultTabController(
        length: 2,
        child: Container(
          decoration: AppDecorations.mainGradient(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text('Payment Requests', style: AppTypography.headline),
              bottom: const TabBar(
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [Tab(text: 'Incoming'), Tab(text: 'Outgoing')],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: () => getIt<NavigationService>().push('/payment-requests/create'),
                ),
              ],
            ),
            body: ResponsiveConstraint(
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
        icon: isOutgoing ? Icons.outbox : Icons.move_to_inbox,
        title: 'No ${isOutgoing ? "Outgoing" : "Incoming"} Requests',
        subtitle: 'You are all caught up!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return PaymentRequestItem(
          request: req,
          isOutgoing: isOutgoing,
          isLoading: actingOnId == req.id,
        );
      },
    );
  }
}
