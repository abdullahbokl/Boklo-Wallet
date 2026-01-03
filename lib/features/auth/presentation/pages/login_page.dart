import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/auth/presentation/widgets/login_form.dart';
import 'package:boklo/features/auth/presentation/widgets/login_header.dart';
import 'package:boklo/shared/responsive/responsive_builder.dart';
import 'package:boklo/shared/theme/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, BaseState<User?>>(
      listener: (context, state) {
        state.whenOrNull(
          error: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.message)),
            );
          },
          success: (user) {
            if (user != null) {
              // TODO(Nav): Navigate to home
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome ${user.displayName ?? "User"}'),
                ),
              );
            }
          },
        );
      },
      child: Scaffold(
        body: ResponsiveBuilder(
          mobile: _buildMobileLayout,
          tablet: _buildTabletLayout,
          desktop: _buildDesktopLayout,
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, dynamic _) {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LoginHeader(),
            SizedBox(height: AppSpacing.xxl),
            LoginForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, dynamic info) {
    return Center(
      child: SizedBox(
        width: 500,
        child: _buildMobileLayout(context, info),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, dynamic info) {
    return Center(
      child: SizedBox(
        width: 400,
        child: _buildMobileLayout(context, info),
      ),
    );
  }
}
