flutter_screen_issue.md
import 'package:flutter/material.dart';

void main() {
  runApp(const GitDoItApp());
}

class GitDoItApp extends StatelessWidget {
  const GitDoItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Roboto', // Defaulting to Roboto, but fits the clean aesthetic
      ),
      home: const IssueDetailScreen(),
    );
  }
}

class IssueDetailScreen extends StatefulWidget {
  const IssueDetailScreen({super.key});

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  bool isDescExpanded = false;
  final Color orangeAccent = const Color(0xFFFF5E00);
  final Color secondaryText = const Color(0xFFA0A0A5);
  final Color surfaceColor = const Color(0xFF111111);
  final Color borderColor = const Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            // Sync Banner
            Container(
              width: double.infinity,
              color: orangeAccent,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CACHED – LAST SYNC 15M AGO',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                  Icon(Icons.refresh, size: 12, color: Colors.black),
                ],
              ),
            ),
            // Real AppBar
            AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {},
              ),
              title: const Text(
                'GitDoIt',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit, size: 16, color: Colors.black),
                      label: const Text('Edit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                )
              ],
            ),
            Divider(height: 1, color: borderColor),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Text(
              'berlogabob/ToDo > #187',
              style: TextStyle(color: orangeAccent, fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            // Title
            const Text(
              'Fix login crash on iOS 18',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.extrabold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            // Status and Metadata
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildStatusBadge('open', true),
                _buildIconText(Icons.access_time, 'Updated 2h ago'),
                _buildIconText(Icons.person_outline, '@you', color: orangeAccent, isBold: true),
                _buildIconText(Icons.visibility_outlined, '3'),
                _buildMilestoneBadge('v1.2'),
              ],
            ),
            const SizedBox(height: 24),
            // Labels
            Wrap(
              spacing: 8,
              children: [
                _buildLabelChip('bug', const Color(0xFFD73A4A)),
                _buildLabelChip('high-priority', const Color(0xFFF9D0C4)),
                _buildLabelChip('iOS', const Color(0xFF007AFF)),
              ],
            ),
            const SizedBox(height: 32),
            // Description Box
            _buildSectionHeader('Description'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: const Color(0xFF222222)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Steps to Reproduce:\n1. Open app on physical device...\n2. Navigate to login...\n3. App crashes immediately.",
                    maxLines: isDescExpanded ? 100 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.5, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => setState(() => isDescExpanded = !isDescExpanded),
                    child: Center(
                      child: Text(
                        isDescExpanded ? 'SHOW LESS' : 'READ MORE',
                        style: TextStyle(color: orangeAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Timeline
            _buildSectionHeader('Activity Timeline'),
            _buildTimelineItem('Created by @berlogabob', '5d ago', Icons.circle_outlined),
            _buildTimelineItem("Label 'bug' added", '2h ago', Icons.label_outline),
            _buildTimelineItem('Assigned to @you', '1h ago', Icons.person_add_alt, isAccent: true),
            const SizedBox(height: 32),
            // Comments
            _buildSectionHeader('Comments (2)'),
            _buildCommentTile('@user1', 'Confirmed on my device 👍', '45m ago'),
            _buildCommentTile('@user2', 'Possible fix in PR #192...', '10m ago'),
            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'CLOSE ISSUE',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.black, letterSpacing: 1.2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildSquareAction(Icons.person_outline),
            const SizedBox(width: 8),
            _buildSquareAction(Icons.label_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(color: secondaryText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: borderColor.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: orangeAccent),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: isOpen ? Colors.green : Colors.grey),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? secondaryText),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
              fontSize: 12,
              color: color ?? secondaryText,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            )),
      ],
    );
  }

  Widget _buildMilestoneBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLabelChip(String text, Color color) {
    return Chip(
      label: Text(text.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTimelineItem(String text, String time, IconData icon, {bool isAccent = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Column(
              children: [
                Icon(icon, size: 16, color: isAccent ? orangeAccent : secondaryText),
                Expanded(child: VerticalDivider(color: borderColor, thickness: 1)),
              ],
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: const TextStyle(fontSize: 14, color: Colors.white)),
                  Text(time, style: TextStyle(fontSize: 12, color: secondaryText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(String user, String text, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: const Color(0xFF222222)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: orangeAccent,
                child: Text(user[1].toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              Text(time, style: TextStyle(color: secondaryText, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildSquareAction(IconData icon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: secondaryText),
    );
  }
}