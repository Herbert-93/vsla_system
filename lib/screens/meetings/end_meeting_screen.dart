import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/member.dart';
import '../../services/database_service.dart';
import '../../utils/helpers.dart';

class EndMeetingScreen extends StatefulWidget {
  final Map<String, dynamic> meetingData;
  final Group group;
  final List<Member> members;

  const EndMeetingScreen({
    super.key,
    required this.meetingData,
    required this.group,
    required this.members,
  });

  @override
  State<EndMeetingScreen> createState() => _EndMeetingScreenState();
}

class _EndMeetingScreenState extends State<EndMeetingScreen> {
  final _presidentPasswordController = TextEditingController();
  final _treasurerPasswordController = TextEditingController();
  final _secretaryPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _meetingEnded = false;

  final _dbService = DatabaseService.instance;

  double get _totalSavings =>
      (widget.meetingData['totalSavings'] as num?)?.toDouble() ?? 0;
  double get _totalSocialFund =>
      (widget.meetingData['totalSocialFund'] as num?)?.toDouble() ?? 0;
  double get _totalLoans =>
      (widget.meetingData['totalLoans'] as num?)?.toDouble() ?? 0;
  double get _totalPenalties =>
      (widget.meetingData['totalPenalties'] as num?)?.toDouble() ?? 0;

  int get _attendanceCount {
    final att = widget.meetingData['attendance'];
    if (att is Map) {
      return att.values.where((v) => v == true).length;
    }
    return 0;
  }

  Future<void> _endMeeting() async {
    if (_presidentPasswordController.text.isEmpty ||
        _treasurerPasswordController.text.isEmpty ||
        _secretaryPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('All three signatories must enter their passwords'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Mark meeting as completed
      widget.meetingData['status'] = 'completed';
      widget.meetingData['verifiedByPresident'] = 1;
      widget.meetingData['verifiedByTreasurer'] = 1;
      widget.meetingData['verifiedBySecretary'] = 1;

      await _dbService.updateMeeting(widget.meetingData);

      // Update group stats
      widget.group.currentMeeting += 1;
      widget.group.totalSavings += _totalSavings;
      widget.group.totalLoanOutstanding += _totalLoans;
      widget.group.socialFundBalance += _totalSocialFund;

      await _dbService.updateGroup(widget.group);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _meetingEnded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending meeting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_meetingEnded) {
      return _buildSuccessView();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Meeting summary
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meeting #${widget.meetingData['meetingNumber']} Summary',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _summaryRow(
                      'Date',
                      Helpers.formatDate(
                          DateTime.parse(widget.meetingData['date']))),
                  _summaryRow(
                      'Attendance', '$_attendanceCount members present'),
                  const Divider(),
                  _summaryRow(
                      'Total Savings', Helpers.formatCurrency(_totalSavings),
                      valueColor: Colors.blue),
                  _summaryRow('Social Fund Collected',
                      Helpers.formatCurrency(_totalSocialFund),
                      valueColor: Colors.purple),
                  _summaryRow(
                      'Loans Disbursed', Helpers.formatCurrency(_totalLoans),
                      valueColor: Colors.orange),
                  _summaryRow(
                      'Penalties', Helpers.formatCurrency(_totalPenalties),
                      valueColor: Colors.red),
                  const Divider(),
                  _summaryRow(
                    'Net Cash In',
                    Helpers.formatCurrency(
                        _totalSavings + _totalSocialFund + _totalPenalties),
                    valueColor: Colors.green,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Signatory verification
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔐 Signatory Verification',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All three signatories must enter their passwords to end the meeting.',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _signatoryField(
                    'President/Chairperson Password',
                    _presidentPasswordController,
                    Icons.person,
                    Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _signatoryField(
                    'Treasurer Password',
                    _treasurerPasswordController,
                    Icons.account_balance,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _signatoryField(
                    'Secretary Password',
                    _secretaryPasswordController,
                    Icons.description,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _endMeeting,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(_isSubmitting ? 'Ending Meeting...' : 'END MEETING'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            Text(
              'Meeting #${widget.meetingData['meetingNumber']} Completed!',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The meeting has been saved and verified.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.home),
              label: const Text('Return to Dashboard'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _signatoryField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color color,
  ) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: color),
      ),
    );
  }

  @override
  void dispose() {
    _presidentPasswordController.dispose();
    _treasurerPasswordController.dispose();
    _secretaryPasswordController.dispose();
    super.dispose();
  }
}
