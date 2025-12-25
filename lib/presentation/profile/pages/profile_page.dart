import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/components/app_button.dart';
import '../../../core/components/error_state.dart';
import '../../../core/components/loading_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_ext.dart';
import '../../auth/blocs/logout/logout_bloc.dart';
import '../../auth/pages/login_page.dart';
import '../blocs/profile/profile_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const ProfileEvent.getProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<LogoutBloc, LogoutState>(
            listener: (context, state) async {
              state.maybeWhen(
                success: (message) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('token');
                  if (context.mounted) {
                    context.showSuccess(message);
                    context.pushAndRemoveUntil(
                      const LoginPage(),
                      (_) => false,
                    );
                  }
                },
                error: (message) {
                  context.showError(message);
                },
                orElse: () {},
              );
            },
          ),
        ],
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            return state.maybeWhen(
              loading: () => const LoadingIndicator(),
              loaded: (user) => SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSizes.xl),

                    // Avatar
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Name
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),

                    // Email
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: AppSizes.fontLg,
                        color: AppColors.onBackground.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxl),

                    // Profile Info Cards
                    _ProfileInfoCard(
                      icon: Icons.person_outline,
                      title: 'Nama',
                      value: user.name,
                    ),
                    const SizedBox(height: AppSizes.md),
                    _ProfileInfoCard(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: user.email,
                    ),
                    const SizedBox(height: AppSizes.md),
                    _ProfileInfoCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Bergabung',
                      value: user.createdAt != null
                          ? _formatDate(user.createdAt!)
                          : '-',
                    ),
                    const SizedBox(height: AppSizes.xxl),

                    // Logout Button
                    BlocBuilder<LogoutBloc, LogoutState>(
                      builder: (context, state) {
                        final isLoading = state.maybeWhen(
                          loading: () => true,
                          orElse: () => false,
                        );
                        return AppButton(
                          text: 'Logout',
                          type: AppButtonType.outlined,
                          icon: Icons.logout,
                          isLoading: isLoading,
                          onPressed: () => _confirmLogout(context),
                        );
                      },
                    ),
                  ],
                ),
              ),
              error: (message) => ErrorState(
                message: message,
                onRetry: () {
                  context
                      .read<ProfileBloc>()
                      .add(const ProfileEvent.getProfile());
                },
              ),
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _confirmLogout(BuildContext context) async {
    final confirmed = await context.showConfirmDialog(
      title: 'Logout',
      message: 'Apakah Anda yakin ingin keluar?',
      confirmText: 'Logout',
      confirmColor: AppColors.error,
    );

    if (confirmed == true && mounted) {
      context.read<LogoutBloc>().add(const LogoutEvent.logout());
    }
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    color: AppColors.onBackground.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppSizes.fontLg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
