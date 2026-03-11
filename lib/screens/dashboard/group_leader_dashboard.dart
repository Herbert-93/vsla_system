import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/group.dart';
import '../../models/member.dart';
import '../../providers/app_state_provider.dart';
import '../members/member_list_screen.dart';
import '../meetings/meeting_screen.dart';
import '../settings/group_settings_screen.dart';
import '../reports/reports_screen.dart';
// import '../end_cycle/end_cycle_screen.dart'; // moved into this file to avoid missing file error
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';

class GroupLeaderDashboard extends StatefulWidget {
  const GroupLeaderDashboard({super.key});

  @override
  State<GroupLeaderDashboard> createState() => _GroupLeaderDashboardState();
}

class _GroupLeaderDashboardState extends State<GroupLeaderDashboard> {
  Group? _group;
  List<Member> _members = [];
  bool _isLoading = true;
  bool _hasSettings = false;
  final DatabaseService _dbService = DatabaseService.instance;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final groupId = await _authService.getCurrentGroupId() ??
          Provider.of<AppStateProvider>(context, listen: false).currentGroupId;

      if (groupId != null && groupId.isNotEmpty) {
        _group = await _dbService.getGroup(groupId);
        _members = await _dbService.getGroupMembers(groupId);
        final settings = await _dbService.getGroupSettings(groupId);
        _hasSettings = settings != null;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Provider.of<AppStateProvider>(context, listen: false).clearState();
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_group?.name ?? 'VSLA Group Dashboard'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _group == null ? _buildNoGroupView() : _buildDashboard(),
              ),
            ),
    );
  }

  Widget _buildNoGroupView() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('No group found',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Please ensure your group is set up correctly.',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final maleCount =
        _members.where((m) => m.gender.toLowerCase() == 'male').length;
    final femaleCount =
        _members.where((m) => m.gender.toLowerCase() == 'female').length;
    final otherCount = _members.length - maleCount - femaleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Group Banner ───────────────────────────────────
        Card(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade900],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _group!.name,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text('Code: ${_group!.groupCode}  •  Bank: ${_group!.bankName}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                    'Meeting #${_group!.currentMeeting}  •  ${_members.length} Members',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Start Meeting / Settings Warning ───────────────
        if (_hasSettings)
          CustomButton(
            text: 'START MEETING',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeetingScreen(
                    group: _group!,
                    members: _members,
                  ),
                ),
              ).then((_) => _loadDashboardData());
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
              children: [
                const Text(
                  '⚠️ Please configure group settings before starting a meeting.',
                  style: TextStyle(color: Colors.orange),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GroupSettingsScreen()),
                  ).then((_) => _loadDashboardData()),
                  child: const Text('Configure Settings'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // ── Quick Actions ──────────────────────────────────
        Card(
          elevation: 0,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.4)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _quickAction(Icons.people, 'Members', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemberListScreen(
                            members: _members,
                            groupId: _group!.id ?? '',
                          ),
                        ),
                      ).then((_) => _loadDashboardData());
                    }),
                    _quickAction(Icons.settings, 'Settings', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const GroupSettingsScreen()),
                      ).then((_) => _loadDashboardData());
                    }),
                    _quickAction(Icons.bar_chart, 'Reports', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReportsScreen(groupId: _group!.id ?? ''),
                        ),
                      );
                    }),
                    _quickAction(Icons.loop, 'End Cycle', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EndCycleScreen(
                            group: _group!,
                            members: _members,
                          ),
                        ),
                      ).then((_) => _loadDashboardData());
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Members by Gender ──────────────────────────────
        Card(
          elevation: 0,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Members by Gender',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.4)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _genderChip(
                        Icons.male, 'Male', maleCount, Colors.blue.shade600),
                    const SizedBox(width: 8),
                    _genderChip(Icons.female, 'Female', femaleCount,
                        Colors.pink.shade400),
                    if (otherCount > 0) ...[
                      const SizedBox(width: 8),
                      _genderChip(Icons.person, 'Other', otherCount,
                          Colors.purple.shade400),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Stats Row ──────────────────────────────────────
        Text('Group Finances',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.4)),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.95,
          children: [
            _statCard('Savings', Helpers.formatCurrency(_group!.totalSavings),
                Icons.savings, Colors.blue),
            _statCard(
                'Loans',
                Helpers.formatCurrency(_group!.totalLoanOutstanding),
                Icons.credit_card,
                Colors.orange),
            _statCard(
                'Social Fund',
                Helpers.formatCurrency(_group!.socialFundBalance),
                Icons.volunteer_activism,
                Colors.green),
            _statCard('Members', '${_group!.totalMembers}', Icons.people,
                Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(title,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _genderChip(IconData icon, String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blue.shade800, size: 20),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

/// Minimal inline EndCycleScreen to replace the missing external file.
/// This provides a simple placeholder UI and prevents the "Target of URI doesn't exist" error.
/// You can expand this later with the actual end-cycle functionality.
class EndCycleScreen extends StatelessWidget {
  final Group group;
  final List<Member> members;

  const EndCycleScreen({
    Key? key,
    required this.group,
    required this.members,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('End Cycle - ${group.name}'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'End cycle operations go here.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
