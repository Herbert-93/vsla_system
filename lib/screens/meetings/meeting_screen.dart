import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/group.dart';
import '../../models/member.dart';
import '../../services/database_service.dart';
import 'attendance_screen.dart';
import 'social_fund_screen.dart';
import 'savings_screen.dart';
import 'loan_request_screen.dart';
import 'loan_repayment_screen.dart';
import 'penalties_screen.dart';
import 'end_meeting_screen.dart';

class MeetingScreen extends StatefulWidget {
  final Group group;
  final List<Member> members;

  const MeetingScreen({
    super.key,
    required this.group,
    required this.members,
  });

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  int _currentStep = 0;
  final _uuid = const Uuid();
  late Map<String, dynamic> _meetingData;
  bool _initialized = false;
  final _dbService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _initializeMeeting();
  }

  Future<void> _initializeMeeting() async {
    final attendance = <String, bool>{};
    for (final member in widget.members) {
      attendance[member.id!] = true;
    }

    _meetingData = {
      'id': _uuid.v4(),
      'groupId': widget.group.id,
      'meetingNumber': widget.group.currentMeeting + 1,
      'date': DateTime.now().toIso8601String(),
      'attendance': attendance,
      'socialFundCollections': <String, double>{},
      'socialFundDistributions': <String, double>{},
      'savings': <String, String>{},
      'loanRequests': <Map<String, dynamic>>[],
      'loanRepayments': <Map<String, dynamic>>[],
      'penalties': <Map<String, dynamic>>[],
      'totalSavings': 0.0,
      'totalSocialFund': 0.0,
      'totalLoans': 0.0,
      'totalPenalties': 0.0,
      'status': 'in_progress',
      'notes': '',
      'verifiedByPresident': 0,
      'verifiedByTreasurer': 0,
      'verifiedBySecretary': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _dbService.insertMeeting(_meetingData);

    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Attendance'),
        content: AttendanceScreen(
          members: widget.members,
          meetingData: _meetingData,
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Social Fund'),
        content: SocialFundScreen(
          members: widget.members,
          meetingData: _meetingData,
          groupId: widget.group.id!,
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Savings'),
        content: SavingsScreen(
          members: widget.members,
          meetingData: _meetingData,
          groupId: widget.group.id!,
        ),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Loan Requests'),
        content: LoanRequestScreen(
          members: widget.members,
          meetingData: _meetingData,
          groupId: widget.group.id!,
        ),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Loan Repayments'),
        content: LoanRepaymentScreen(
          members: widget.members,
          meetingData: _meetingData,
          groupId: widget.group.id!,
        ),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Penalties'),
        content: PenaltiesScreen(
          members: widget.members,
          meetingData: _meetingData,
          groupId: widget.group.id!,
        ),
        isActive: _currentStep >= 5,
        state: _currentStep > 5 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('End Meeting'),
        content: EndMeetingScreen(
          meetingData: _meetingData,
          group: widget.group,
          members: widget.members,
        ),
        isActive: _currentStep >= 6,
        state: _currentStep > 6 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final steps = _buildSteps();

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Meeting #${widget.group.currentMeeting + 1} – ${widget.group.name}'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () async {
              await _dbService.updateMeeting(_meetingData);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Save & Exit',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepTapped: (step) {
          setState(() => _currentStep = step);
        },
        onStepContinue: _currentStep < steps.length - 1
            ? () async {
                await _dbService.updateMeeting(_meetingData);
                setState(() => _currentStep++);
              }
            : null,
        onStepCancel: _currentStep > 0
            ? () => setState(() => _currentStep--)
            : null,
        steps: steps,
        controlsBuilder: (context, details) {
          return Container(
            margin: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (details.onStepContinue != null)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(
                        _currentStep == steps.length - 1
                            ? 'Finish'
                            : 'Continue'),
                  ),
                const SizedBox(width: 8),
                if (details.onStepCancel != null)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
