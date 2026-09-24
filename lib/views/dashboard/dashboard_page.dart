import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_view_model.dart';
import '../auth/login_page.dart';

import '../../utils/app_colors.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/dashboard_view_model.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      DashboardViewModel()..loadDashboard(),
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,

        actions: [
          Consumer<DashboardViewModel>(
            builder: (
                context,
                viewModel,
                child,
                ) {
              return IconButton(
                tooltip: 'Refresh',
                onPressed: viewModel.isLoading
                    ? null
                    : viewModel.refreshDashboard,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
              );
            },
          ),
        ],
      ),

      drawer: const _AdminDrawer(),

      body: Consumer<DashboardViewModel>(
        builder: (
            context,
            viewModel,
            child,
            ) {
          // LOADING
          if (viewModel.isLoading &&
              viewModel.dashboard == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ERROR
          if (viewModel.errorMessage != null &&
              viewModel.dashboard == null) {
            return _ErrorView(
              message:
              viewModel.errorMessage!,
              onRetry: () {
                viewModel.loadDashboard();
              },
            );
          }

          final dashboard =
              viewModel.dashboard;

          // NO DATA
          if (dashboard == null) {
            return _ErrorView(
              message:
              'No dashboard data available.',
              onRetry: () {
                viewModel.loadDashboard();
              },
            );
          }

          return RefreshIndicator(
            onRefresh:
            viewModel.refreshDashboard,

            child: SingleChildScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),

              padding:
              const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  _buildHeader(),

                  const SizedBox(height: 20),

                  _DateCard(
                    date: dashboard.date,
                  ),

                  const SizedBox(height: 18),

                  LayoutBuilder(
                    builder:
                        (
                        context,
                        constraints,
                        ) {
                      final width =
                          constraints.maxWidth;

                      int columns = 2;

                      if (width >= 1100) {
                        columns = 4;
                      } else if (width >= 700) {
                        columns = 4;
                      }

                      return GridView.count(
                        crossAxisCount:
                        columns,

                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,

                        shrinkWrap: true,

                        physics:
                        const NeverScrollableScrollPhysics(),

                        childAspectRatio:
                        width >= 900
                            ? 1.55
                            : 1.25,

                        children: [
                          _DashboardCard(
                            title:
                            'Total Employees',
                            value: dashboard
                                .totalEmployees
                                .toString(),
                            icon:
                            Icons
                                .people_alt_outlined,
                            iconColor:
                            Colors.blue,
                          ),

                          _DashboardCard(
                            title:
                            'Checked In',
                            value: dashboard
                                .checkedIn
                                .toString(),
                            icon:
                            Icons
                                .login_rounded,
                            iconColor:
                            Colors.green,
                          ),

                          _DashboardCard(
                            title:
                            'Checked Out',
                            value: dashboard
                                .checkedOut
                                .toString(),
                            icon:
                            Icons
                                .logout_rounded,
                            iconColor:
                            Colors.orange,
                          ),

                          _DashboardCard(
                            title:
                            'Not Checked In',
                            value: dashboard
                                .notCheckedIn
                                .toString(),
                            icon:
                            Icons
                                .person_off_outlined,
                            iconColor:
                            Colors.red,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  _AttendanceSummary(
                    total:
                    dashboard.totalEmployees,
                    checkedIn:
                    dashboard.checkedIn,
                    notCheckedIn:
                    dashboard.notCheckedIn,
                  ),

                  const SizedBox(height: 20),

                  _QuickManagementMenu(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Staff Attendance',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: 5),

        Text(
          'Today attendance and system management',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   ADMIN DRAWER
   ============================================================ */

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer();

  @override
  Widget build(BuildContext context) {
    final auth =
    context.watch<AuthViewModel>();

    final user = auth.user;

    final name =
        user?['name']?.toString() ??
            'Administrator';

    final email =
        user?['email']?.toString() ??
            '';

    final employee =
    user?['employee'];

    final employeeNo =
        employee?['employee_no']
            ?.toString() ??
            'ADMIN';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              name: name,
              email: email,
              employeeNo: employeeNo,
            ),

            Expanded(
              child: ListView(
                padding:
                EdgeInsets.zero,
                children: [
                  _drawerItem(
                    context: context,
                    icon:
                    Icons.dashboard_outlined,
                    title: 'Dashboard',
                    selected: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  const _DrawerSectionTitle(
                    title: 'Staff Management',
                  ),

                  _drawerItem(
                    context: context,
                    icon:
                    Icons.people_alt_outlined,
                    title: 'Employees',
                    onTap: () {
                      Navigator.pop(context);

                      // TODO:
                      // EmployeesPage
                    },
                  ),

                  _drawerItem(
                    context: context,
                    icon:
                    Icons.business_outlined,
                    title: 'Departments',
                    onTap: () {
                      Navigator.pop(context);

                      // TODO:
                      // DepartmentsPage
                    },
                  ),

                  _drawerItem(
                    context: context,
                    icon:
                    Icons.account_tree_outlined,
                    title: 'Units',
                    onTap: () {
                      Navigator.pop(context);

                      // TODO:
                      // UnitsPage
                    },
                  ),

                  const _DrawerSectionTitle(
                    title: 'Attendance',
                  ),

                  _drawerItem(
                    context: context,
                    icon:
                    Icons.today_outlined,
                    title:
                    "Today's Attendance",
                    onTap: () {
                      Navigator.pop(context);

                      // TODO:
                      // TodayAttendancePage
                    },
                  ),

                  _drawerItem(
                    context: context,
                    icon:
                    Icons.history_rounded,
                    title:
                    'Attendance History',
                    onTap: () {
                      Navigator.pop(context);

                      // TODO:
                      // AttendanceHistoryPage
                    },
                  ),

                  _drawerItem(
                    context: context,
                    icon:
                    Icons.warning_amber_outlined,
                    title:
                    'Attendance Exceptions',
                    onTap: () {
                      Navigator.pop(context);

                      // TODO:
                      // AttendanceExceptionsPage
                    },
                  ),

                  const _DrawerSectionTitle(
                    title: 'Reports',
                  ),

                  _drawerItem(
                    context: context,
                    icon:
                    Icons.today_rounded,
                    title: 'Daily Report',
                    onTap: () {
                      Navigator.pop(context);

                      // TODO:
                      // DailyReportPage
                    },
                  ),

                  _drawerItem(
                    context: context,
                    icon:
                    Icons.date_range_rounded,
                    title: 'Weekly Report',
                    onTap: () {
                      Navigator.pop(context);

                      // TODO:
                      // WeeklyReportPage
                    },
                  ),

                  _drawerItem(
                    context: context,
                    icon:
                    Icons.calendar_month_rounded,
                    title: 'Monthly Report',
                    onTap: () {
                      Navigator.pop(context);

                      // TODO:
                      // MonthlyReportPage
                    },
                  ),

                  _drawerItem(
                    context: context,
                    icon:
                    Icons.filter_alt_outlined,
                    title: 'Custom Report',
                    onTap: () {
                      Navigator.pop(context);

                      // TODO:
                      // CustomReportPage
                    },
                  ),

                  const _DrawerSectionTitle(
                    title: 'System Administration',
                  ),

                  _drawerItem(
                    context: context,
                    icon:
                    Icons.manage_accounts_outlined,
                    title: 'Users',
                    onTap: () {
                      Navigator.pop(context);

                      // TODO:
                      // UsersPage
                    },
                  ),

                  _drawerItem(
                    context: context,
                    icon:
                    Icons.admin_panel_settings_outlined,
                    title:
                    'Roles & Permissions',
                    onTap: () {
                      Navigator.pop(context);

                      // TODO:
                      // RolesPermissionsPage
                    },
                  ),

                  _drawerItem(
                    context: context,
                    icon:
                    Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);

                      // TODO:
                      // SettingsPage
                    },
                  ),

                  const Divider(
                    height: 25,
                  ),

                  _drawerItem(
                    context: context,
                    icon:
                    Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);

                      // TODO:
                      // HelpPage
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            _buildLogout(
              context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required String name,
    required String email,
    required String employeeNo,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        25,
        20,
        22,
      ),
      color: AppColors.primary,

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          const CircleAvatar(
            radius: 31,
            backgroundColor:
            Colors.white,

            child: Icon(
              Icons
                  .admin_panel_settings_rounded,
              color:
              AppColors.primary,
              size: 34,
            ),
          ),

          const SizedBox(height: 13),

          Text(
            name,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          if (email.isNotEmpty) ...[
            const SizedBox(height: 3),

            Text(
              email,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,

              style: TextStyle(
                color: Colors.white
                    .withValues(
                  alpha: .85,
                ),
                fontSize: 11,
              ),
            ),
          ],

          const SizedBox(height: 3),

          Text(
            employeeNo,
            style: TextStyle(
              color: Colors.white
                  .withValues(
                alpha: .85,
              ),
              fontSize: 11,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return ListTile(
      dense: true,

      leading: Icon(
        icon,
        size: 22,
        color: selected
            ? AppColors.primary
            : Colors.grey.shade700,
      ),

      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected
              ? FontWeight.w700
              : FontWeight.w500,
          color: selected
              ? AppColors.primary
              : AppColors.textPrimary,
        ),
      ),

      selected: selected,

      selectedTileColor:
      AppColors.primary.withValues(
        alpha: .08,
      ),

      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          10,
        ),
      ),

      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 18,
      ),

      onTap: onTap,
    );
  }

  Widget _buildLogout(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.logout_rounded,
        color: Colors.red,
      ),
      title: const Text(
        'Logout',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Logout'),
              content: const Text(
                'Are you sure you want to logout?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            );
          },
        );

        if (shouldLogout != true || !context.mounted) {
          return;
        }

        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        try {
          await context.read<AuthViewModel>().logout();

          if (!context.mounted) {
            return;
          }

          // Close loading dialog
          Navigator.of(context).pop();

          // Go back to LoginPage and remove all previous pages
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const LoginPage(),
            ),
                (route) => false,
          );
        } catch (e) {
          if (!context.mounted) {
            return;
          }

          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Logout failed: ${e.toString()}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}

class _DrawerSectionTitle
    extends StatelessWidget {
  final String title;

  const _DrawerSectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        6,
      ),

      child: Text(
        title.toUpperCase(),

        style: TextStyle(
          fontSize: 10,
          fontWeight:
          FontWeight.w800,
          letterSpacing: .8,
          color:
          AppColors.primary
              .withValues(
            alpha: .75,
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   DATE CARD
   ============================================================ */

class _DateCard extends StatelessWidget {
  final String date;

  const _DateCard({
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius:
        BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          Container(
            padding:
            const EdgeInsets.all(11),

            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(
                alpha: 0.15,
              ),

              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),

            child: const Icon(
              Icons
                  .calendar_today_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),

          const SizedBox(width: 15),

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              const Text(
                'Attendance Date',

                style: TextStyle(
                  color:
                  Colors.white70,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                date,

                style:
                const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   DASHBOARD CARD
   ============================================================ */

class _DashboardCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,

      shadowColor:
      Colors.black.withValues(
        alpha: 0.08,
      ),

      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          17,
        ),
      ),

      child: Padding(
        padding:
        const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,

          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,

              children: [
                Container(
                  padding:
                  const EdgeInsets.all(
                    10,
                  ),

                  decoration:
                  BoxDecoration(
                    color: iconColor
                        .withValues(
                      alpha: 0.10,
                    ),

                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),

                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),

                Flexible(
                  child: Text(
                    value,
                    textAlign:
                    TextAlign.right,

                    style:
                    const TextStyle(
                      fontSize: 27,
                      fontWeight:
                      FontWeight.w800,
                      color: AppColors
                          .textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              title,
              maxLines: 2,

              style: TextStyle(
                fontSize: 13,
                color: AppColors
                    .textSecondary,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   ATTENDANCE SUMMARY
   ============================================================ */

class _AttendanceSummary
    extends StatelessWidget {
  final int total;
  final int checkedIn;
  final int notCheckedIn;

  const _AttendanceSummary({
    required this.total,
    required this.checkedIn,
    required this.notCheckedIn,
  });

  @override
  Widget build(BuildContext context) {
    final percentage =
    total == 0
        ? 0.0
        : checkedIn / total;

    return Card(
      elevation: 2,

      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          17,
        ),
      ),

      child: Padding(
        padding:
        const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            const Text(
              'Today Attendance',

              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w800,
                color: AppColors
                    .textPrimary,
              ),
            ),

            const SizedBox(height: 18),

            ClipRRect(
              borderRadius:
              BorderRadius.circular(
                20,
              ),

              child:
              LinearProgressIndicator(
                value: percentage,
                minHeight: 10,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,

              children: [
                Text(
                  '${(percentage * 100).toStringAsFixed(1)}% checked in',

                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                Text(
                  '$checkedIn / $total',

                  style: TextStyle(
                    color: AppColors
                        .textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Text(
              '$notCheckedIn employees have not checked in today.',

              style: TextStyle(
                color: AppColors
                    .textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   QUICK MANAGEMENT
   ============================================================ */

class _QuickManagementMenu
    extends StatelessWidget {
  const _QuickManagementMenu();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        const Text(
          'Quick Management',

          style: TextStyle(
            fontSize: 19,
            fontWeight:
            FontWeight.w800,
            color:
            AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 12),

        LayoutBuilder(
          builder:
              (
              context,
              constraints,
              ) {
            final columns =
            constraints.maxWidth >=
                850
                ? 4
                : 2;

            return GridView.count(
              crossAxisCount:
              columns,

              crossAxisSpacing: 12,
              mainAxisSpacing: 12,

              shrinkWrap: true,

              physics:
              const NeverScrollableScrollPhysics(),

              childAspectRatio: 1.7,

              children: [
                _QuickMenuCard(
                  icon:
                  Icons.people_alt_outlined,
                  title: 'Employees',
                  subtitle:
                  'Manage employees',
                  onTap: () {
                    // TODO
                  },
                ),

                _QuickMenuCard(
                  icon:
                  Icons.access_time_rounded,
                  title: 'Attendance',
                  subtitle:
                  'View attendance',
                  onTap: () {
                    // TODO
                  },
                ),

                _QuickMenuCard(
                  icon:
                  Icons.assessment_outlined,
                  title: 'Reports',
                  subtitle:
                  'Attendance reports',
                  onTap: () {
                    // TODO
                  },
                ),

                _QuickMenuCard(
                  icon:
                  Icons.manage_accounts_outlined,
                  title: 'Users',
                  subtitle:
                  'Manage system users',
                  onTap: () {
                    // TODO
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickMenuCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      borderRadius:
      BorderRadius.circular(
        16,
      ),

      child: Container(
        padding:
        const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
          BorderRadius.circular(
            16,
          ),

          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withValues(
                alpha: .04,
              ),

              blurRadius: 8,

              offset:
              const Offset(0, 3),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              padding:
              const EdgeInsets.all(
                10,
              ),

              decoration: BoxDecoration(
                color: AppColors
                    .primary
                    .withValues(
                  alpha: .08,
                ),

                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),

              child: Icon(
                icon,
                color:
                AppColors.primary,
                size: 25,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment
                    .center,

                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [
                  Text(
                    title,

                    maxLines: 1,

                    overflow:
                    TextOverflow
                        .ellipsis,

                    style:
                    const TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    subtitle,

                    maxLines: 1,

                    overflow:
                    TextOverflow
                        .ellipsis,

                    style:
                    const TextStyle(
                      fontSize: 10,
                      color:
                      AppColors
                          .textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   ERROR VIEW
   ============================================================ */

class _ErrorView
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(25),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            Icon(
              Icons
                  .cloud_off_rounded,

              size: 60,

              color: AppColors.danger
                  .withValues(
                alpha: 0.8,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to load dashboard',

              textAlign:
              TextAlign.center,

              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,

              textAlign:
              TextAlign.center,

              style: TextStyle(
                fontSize: 13,
                color: AppColors
                    .textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: onRetry,

              icon: const Icon(
                Icons.refresh_rounded,
              ),

              label: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }
}