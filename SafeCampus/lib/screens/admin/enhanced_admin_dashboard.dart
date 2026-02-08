import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../services/report_service.dart';
import '../../services/ai_service.dart';
import '../../models/user.dart' as models;
import '../auth/login_screen.dart';

class EnhancedAdminDashboard extends StatefulWidget {
  const EnhancedAdminDashboard({super.key});

  @override
  State<EnhancedAdminDashboard> createState() => _EnhancedAdminDashboardState();
}

class _EnhancedAdminDashboardState extends State<EnhancedAdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();
  final _adminService = AdminService();
  final _reportService = ReportService();
  final _aiService = AIService();

  // Data
  Map<String, dynamic> _kpis = {};
  List<models.User> _users = [];
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _recentActivity = [];
  Map<String, dynamic> _aiInsights = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _adminService.getDashboardKPIs(),
        _adminService.getAllUsers(),
        _adminService.getIncidentAnalytics(),
        _adminService.getRecentActivity(),
        _aiService.generateInsights(),
      ]);

      if (mounted) {
        setState(() {
          _kpis = results[0] as Map<String, dynamic>;
          _users = results[1] as List<models.User>;
          _analytics = results[2] as Map<String, dynamic>;
          _recentActivity = results[3] as List<Map<String, dynamic>>;
          _aiInsights = results[4] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading data: ${e.toString()}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.critical,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _showLogoutConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(color: AppColors.foregroundLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.foregroundLight),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.critical),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _handleLogout();
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildUsersTab(),
                  _buildAnalyticsTab(),
                  _buildReportsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'System Management & Analytics',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
            color: AppColors.surface,
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutConfirmation();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: AppColors.critical, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.critical,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.secondary,
        unselectedLabelColor: AppColors.foregroundLight,
        indicatorColor: AppColors.secondary,
        labelStyle:
        GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Users'),
          Tab(text: 'Analytics'),
          Tab(text: 'Reports'),
        ],
      ),
    );
  }

  // OVERVIEW TAB
  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.secondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKPICards(),
            const SizedBox(height: 24),
            _buildAIInsights(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
            const SizedBox(height: 24),
            _buildSystemHealth(),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    final totalUsers = _kpis['totalUsers'] ?? 0;
    final activeIncidents = _kpis['activeIncidents'] ?? 0;
    final avgResponseTime = _kpis['avgResponseTime'] ?? 'N/A';
    final activeStaff = (_kpis['securityCount'] ?? 0) + (_kpis['adminCount'] ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildKPICard('Total Users', '$totalUsers', Icons.people,
                AppColors.secondary, null),
            _buildKPICard(
                'Active Incidents', '$activeIncidents', Icons.warning, AppColors.warning, null),
            _buildKPICard('Response Time', avgResponseTime, Icons.timer,
                AppColors.success, null),
            _buildKPICard(
                'Active Staff', '$activeStaff', Icons.security, AppColors.accent, null),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(
      String title, String value, IconData icon, Color color, String? change) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              if (change != null)
                Builder(
                  builder: (context) {
                    final isPositive = change.startsWith('+');
                    return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.critical)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? AppColors.success : AppColors.critical,
                  ),
                ),
                    );
                  },
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.foregroundLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    if (_aiInsights.isEmpty) {
      return const SizedBox.shrink();
    }

    final recommendations = _aiInsights['recommendations'] as List<dynamic>? ?? [];
    final hotspots = _aiInsights['hotspots'] as Map<String, dynamic>?;
    final trends = _aiInsights['trends'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology, color: AppColors.accent, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'AI Insights',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recommendations
              if (recommendations.isNotEmpty) ...[
                Text(
                  'Recommendations',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ...recommendations.take(3).map((rec) {
                  final type = rec['type'] as String? ?? 'info';
                  final color = type == 'urgent' ? AppColors.critical :
                               type == 'warning' ? AppColors.warning :
                               AppColors.info;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          type == 'urgent' ? Icons.priority_high :
                          type == 'warning' ? Icons.warning :
                          Icons.info_outline,
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rec['title'] as String? ?? 'Recommendation',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rec['message'] as String? ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.foregroundLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
              ],

              // Hotspots
              if (hotspots != null) ...[
                Text(
                  'Top Incident Hotspots',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ...(hotspots['topHotspots'] as List<dynamic>? ?? []).map((hotspot) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            hotspot['location'] as String? ?? 'Unknown',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${hotspot['incidentCount']} incidents',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
              ],

              // Trends
              if (trends != null) ...[
                Row(
                  children: [
                    Text(
                      'Trend: ',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.foregroundLight,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (trends['trend'] == 'increasing' ? AppColors.critical :
                               trends['trend'] == 'decreasing' ? AppColors.success :
                               AppColors.info).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trends['trend'] == 'increasing' ? Icons.trending_up :
                            trends['trend'] == 'decreasing' ? Icons.trending_down :
                            Icons.trending_flat,
                            size: 16,
                            color: trends['trend'] == 'increasing' ? AppColors.critical :
                                  trends['trend'] == 'decreasing' ? AppColors.success :
                                  AppColors.info,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trends['trend'] as String? ?? 'stable',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: trends['trend'] == 'increasing' ? AppColors.critical :
                                    trends['trend'] == 'decreasing' ? AppColors.success :
                                    AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: _recentActivity.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.foregroundLight,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentActivity.length,
            separatorBuilder: (context, index) => const Divider(
              color: AppColors.border,
              height: 1,
            ),
            itemBuilder: (context, index) {
                    final activity = _recentActivity[index];
                    final timestamp = activity['timestamp'] as DateTime;
                    final timeAgo = _formatTimeAgo(timestamp);
                    
              return ListTile(
                      leading: Icon(_getActivityIcon(activity['icon'] as String),
                    color: AppColors.secondary, size: 24),
                title: Text(
                  activity['action'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                        activity['details'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.foregroundLight,
                  ),
                ),
                trailing: Text(
                        timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.foregroundLight,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon(String iconName) {
    switch (iconName) {
      case 'report':
        return Icons.report;
      case 'notifications':
        return Icons.notifications;
      case 'person_add':
        return Icons.person_add;
      case 'check_circle':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  Widget _buildSystemHealth() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Health',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildHealthIndicator(
                  'API Response Time', 0.85, AppColors.success),
              const SizedBox(height: 16),
              _buildHealthIndicator(
                  'Database Performance', 0.92, AppColors.success),
              const SizedBox(height: 16),
              _buildHealthIndicator('Server Load', 0.65, AppColors.warning),
              const SizedBox(height: 16),
              _buildHealthIndicator('Storage Usage', 0.45, AppColors.success),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthIndicator(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // USERS TAB
  Widget _buildUsersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.secondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserStats(),
            const SizedBox(height: 24),
            _buildUserList(),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserStats() {
    final studentCount = _kpis['studentCount'] ?? 0;
    final securityCount = _kpis['securityCount'] ?? 0;
    final adminCount = _kpis['adminCount'] ?? 0;

    return Row(
      children: [
        Expanded(
            child: _buildUserStatCard(
                'Students', '$studentCount', Icons.school, AppColors.secondary)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildUserStatCard(
                'Security', '$securityCount', Icons.security, AppColors.accent)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildUserStatCard(
                'Admins', '$adminCount', Icons.admin_panel_settings, AppColors.warning)),
      ],
    );
  }

  Widget _buildUserStatCard(
      String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.foregroundLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'User Management',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${_users.length} total users',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.foregroundLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: _users.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'No users found',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.foregroundLight,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
                  itemCount: _users.length > 20 ? 20 : _users.length,
            separatorBuilder: (context, index) =>
            const Divider(color: AppColors.border, height: 1),
            itemBuilder: (context, index) {
                    final user = _users[index];
                    final roleStr = user.role.name[0].toUpperCase() + user.role.name.substring(1);
                    
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                  child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                title: Text(
                        user.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                        user.email,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.foregroundLight,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                              color: _getRoleColor(roleStr).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                              roleStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                                color: _getRoleColor(roleStr),
                        ),
                      ),
                    ),
                    IconButton(
                            onPressed: () => _showUserActions(user),
                      icon: const Icon(Icons.more_vert,
                          color: AppColors.foregroundLight, size: 20),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showUserActions(models.User user) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user.name,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: AppColors.secondary),
              title: const Text('Change Role', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showChangeRoleDialog(user);
              },
            ),
            ListTile(
              leading: Icon(
                user.isActive ? Icons.block : Icons.check_circle,
                color: user.isActive ? AppColors.critical : AppColors.success,
              ),
              title: Text(
                user.isActive ? 'Deactivate User' : 'Activate User',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleUserStatus(user);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangeRoleDialog(models.User user) async {
    String selectedRole = user.role.name;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Change Role',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Student', style: TextStyle(color: Colors.white)),
              value: 'student',
              groupValue: selectedRole,
              activeColor: AppColors.secondary,
              onChanged: (value) {
                selectedRole = value!;
                Navigator.pop(context, value);
              },
            ),
            RadioListTile<String>(
              title: const Text('Security', style: TextStyle(color: Colors.white)),
              value: 'security',
              groupValue: selectedRole,
              activeColor: AppColors.secondary,
              onChanged: (value) {
                selectedRole = value!;
                Navigator.pop(context, value);
              },
            ),
            RadioListTile<String>(
              title: const Text('Admin', style: TextStyle(color: Colors.white)),
              value: 'admin',
              groupValue: selectedRole,
              activeColor: AppColors.secondary,
              onChanged: (value) {
                selectedRole = value!;
                Navigator.pop(context, value);
              },
            ),
          ],
        ),
      ),
    );

    if (result != null && result != user.role.name) {
      final success = await _adminService.updateUserRole(
        userId: user.id,
        role: result,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User role updated successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _refreshData();
      }
    }
  }

  Future<void> _toggleUserStatus(models.User user) async {
    final success = user.isActive
        ? await _adminService.deactivateUser(user.id)
        : await _adminService.activateUser(user.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isActive ? 'User deactivated' : 'User activated',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      _refreshData();
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return AppColors.warning;
      case 'Security':
        return AppColors.accent;
      case 'Student':
      default:
        return AppColors.secondary;
    }
  }

  // ANALYTICS TAB
  Widget _buildAnalyticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.secondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIncidentTrendChart(),
            const SizedBox(height: 24),
            _buildResponseTimeChart(),
            const SizedBox(height: 24),
            _buildCategoryBreakdown(),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentTrendChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incident Trends',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.foregroundLight,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ];
                      if (value.toInt() < days.length) {
                        return Text(
                          days[value.toInt()],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.foregroundLight,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _getWeeklyTrendSpots(),
                  isCurved: true,
                  color: AppColors.secondary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.secondary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseTimeChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Average Response Time',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 10,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}m',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.foregroundLight,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ];
                      if (value.toInt() < days.length) {
                        return Text(
                          days[value.toInt()],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.foregroundLight,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(x: 0, barRods: [
                  BarChartRodData(toY: 4.2, color: AppColors.success, width: 20)
                ]),
                BarChartGroupData(x: 1, barRods: [
                  BarChartRodData(toY: 3.8, color: AppColors.success, width: 20)
                ]),
                BarChartGroupData(x: 2, barRods: [
                  BarChartRodData(toY: 4.5, color: AppColors.success, width: 20)
                ]),
                BarChartGroupData(x: 3, barRods: [
                  BarChartRodData(toY: 3.9, color: AppColors.success, width: 20)
                ]),
                BarChartGroupData(x: 4, barRods: [
                  BarChartRodData(toY: 3.6, color: AppColors.success, width: 20)
                ]),
                BarChartGroupData(x: 5, barRods: [
                  BarChartRodData(toY: 4.1, color: AppColors.success, width: 20)
                ]),
                BarChartGroupData(x: 6, barRods: [
                  BarChartRodData(toY: 4.3, color: AppColors.success, width: 20)
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getWeeklyTrendSpots() {
    final weeklyTrend = _analytics['weeklyTrend'] as List<dynamic>? ?? [0, 0, 0, 0, 0, 0, 0];
    return List.generate(7, (index) {
      return FlSpot(index.toDouble(), (weeklyTrend[index] as int).toDouble());
    });
  }

  Widget _buildCategoryBreakdown() {
    final typeBreakdown = _analytics['typeBreakdown'] as Map<String, dynamic>? ?? {};
    final totalIncidents = _analytics['totalIncidents'] as int? ?? 1;
    
    final categories = typeBreakdown.entries.map((entry) {
      final count = entry.value as int;
      final percentage = totalIncidents > 0 ? count / totalIncidents : 0.0;
      return {
        'name': entry.key[0].toUpperCase() + entry.key.substring(1),
        'count': count,
        'percentage': percentage,
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incident Categories',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category['name'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${category['count']} (${((category['percentage'] as double) * 100).toInt()}%)',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: category['percentage'] as double,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.secondary),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // REPORTS TAB
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate Reports',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildReportCard(
                'Incident Summary Report',
                'Generate a comprehensive report of all incidents',
                Icons.summarize,
                'incident_summary'),
            const SizedBox(height: 12),
            _buildReportCard('User Activity Report',
                'Export user engagement and activity metrics', Icons.people,
                'user_activity'),
            const SizedBox(height: 12),
            _buildReportCard('Response Time Analysis',
                'Detailed analysis of emergency response times', Icons.timer,
                'response_time'),
            const SizedBox(height: 12),
            _buildReportCard('Security Staff Performance',
                'Staff performance and efficiency metrics', Icons.badge,
                'staff_performance'),
            const SizedBox(height: 24),
            Text(
              'Recent Reports',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentReportsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String description, IconData icon, String reportType) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.foregroundLight,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _generateReport(reportType, title),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(String reportType, String reportTitle) async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Generating $reportTitle...',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      Map<String, dynamic> report;
      switch (reportType) {
        case 'incident_summary':
          report = await _reportService.generateIncidentSummaryReport();
          break;
        case 'user_activity':
          report = await _reportService.generateUserActivityReport();
          break;
        case 'response_time':
          report = await _reportService.generateResponseTimeReport();
          break;
        case 'staff_performance':
          report = await _reportService.generateStaffPerformanceReport();
          break;
        default:
          throw Exception('Unknown report type');
      }

      if (mounted) {
        _showReportDetails(report, reportTitle);
      }
    } catch (e) {
      if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
              'Error generating report: ${e.toString()}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
            backgroundColor: AppColors.critical,
                ),
              );
      }
    }
  }

  Future<void> _showReportDetails(Map<String, dynamic> report, String title) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Generated ${_formatReportDate(report['generatedAt'] as String?)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.foregroundLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
            ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: _buildReportContent(report),
                ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(Map<String, dynamic> report) {
    final summary = report['summary'] as Map<String, dynamic>? ?? {};
    final breakdown = report['breakdown'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Section
        if (summary.isNotEmpty) ...[
          Text(
            'Summary',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: summary.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatKey(entry.key),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.foregroundLight,
                        ),
                      ),
                      Text(
                        entry.value.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Breakdown Section
        if (breakdown != null && breakdown.isNotEmpty) ...[
          Text(
            'Breakdown',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...breakdown.entries.map((entry) {
    return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatKey(entry.key),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(entry.value as Map<String, dynamic>).entries.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.key,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.foregroundLight,
                            ),
                          ),
                          Text(
                            item.value.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  String _formatKey(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatReportDate(String? dateString) {
    if (dateString == null) return 'Just now';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Just now';
    }
  }

  Widget _buildRecentReportsList() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: AppColors.foregroundLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Reports Generated On-Demand',
              style: GoogleFonts.inter(
              fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Click "Generate" on any report above to create and view it. Reports are generated in real-time from your database.',
            textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.foregroundLight,
              ),
            ),
        ],
      ),
    );
  }
}
