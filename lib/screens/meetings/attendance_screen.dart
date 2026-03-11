import 'package:flutter/material.dart';
import '../../models/member.dart';

class AttendanceScreen extends StatefulWidget {
  final List<Member> members;
  final Map<String, dynamic> meetingData;

  const AttendanceScreen({
    super.key,
    required this.members,
    required this.meetingData,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late Map<String, bool> attendance;

  @override
  void initState() {
    super.initState();
    attendance = Map.from(widget.meetingData['attendance'] ?? {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'All members are marked present by default. Turn off switch for absent members.',
                  style: TextStyle(color: Colors.blue.shade800),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.members.length,
            itemBuilder: (context, index) {
              final member = widget.members[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      member.firstName[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(member.fullName),
                  subtitle: Text('UMVA: ${member.umvaId}'),
                  trailing: Switch(
                    value: attendance[member.id] ?? true,
                    onChanged: (value) {
                      setState(() {
                        attendance[member.id!] = value;
                        widget.meetingData['attendance'] = attendance;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
