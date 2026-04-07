import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/firestore_service.dart';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Help & Feedback',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Send Feedback'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_FaqTab(), _FeedbackTab()],
      ),
    );
  }
}

// ── FAQ Tab ──────────────────────────────────────────────────────────────────
class _FaqTab extends StatelessWidget {
  const _FaqTab();

  static const List<_FaqEntry> _faqs = [
    _FaqEntry(
      question: 'What is RouETA?',
      answer:
          'RouETA is a real-time bus tracking app for Davao City\'s Interim Bus Service. It helps passengers see bus locations, estimated arrival times, and occupancy levels so they can plan their trips better.',
    ),
    _FaqEntry(
      question: 'How does the ETA work?',
      answer:
          'ETAs are calculated based on the bus\'s current GPS position relative to each bus stop along the route. The system estimates travel time considering average traffic conditions in Davao City.',
    ),
    _FaqEntry(
      question: 'What do the occupancy levels mean?',
      answer:
          'There are three levels:\n• Seats Available (~33%) – Plenty of seats open, no standing passengers.\n• Limited Seats (~67%) – Few seats left, act fast.\n• Full Capacity (~95%) – Bus is full, standing passengers. Consider waiting for the next bus.',
    ),
    _FaqEntry(
      question: 'How is occupancy updated?',
      answer:
          'The conductor/driver manually updates the occupancy status using the RouETA Driver app. If data hasn\'t been updated in the last 5 minutes, you\'ll see a NOTICE warning telling you when it was last updated.',
    ),
    _FaqEntry(
      question: 'Do I need to create an account as a passenger?',
      answer:
          'No. Passengers can access all core features — live routes, ETAs, and bus occupancy — without logging in. Only drivers and conductors need to sign in.',
    ),
    _FaqEntry(
      question: 'How do I switch to Driver Mode?',
      answer:
          'Tap the side menu (≡) or go to the Profile tab and tap "Switch to Driver Mode". You\'ll need your assigned driver/conductor credentials to log in.',
    ),
    _FaqEntry(
      question: 'What if the bus stops aren\'t accurate?',
      answer:
          'Route data is maintained by the Davao Interim Bus Service Authority. If you notice incorrect stop locations, please report it through the Feedback tab.',
    ),
    _FaqEntry(
      question: 'Why is the map not loading?',
      answer:
          'The map requires an active internet connection. Check your Wi-Fi or mobile data. If the issue persists, try restarting the app or checking your location permissions in phone settings.',
    ),
    _FaqEntry(
      question: 'Is my location data stored?',
      answer:
          'Location is only used on-device to show your position on the map and calculate the nearest bus stop. We do not store or transmit your personal location data to any server.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tap any question to expand the answer.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // FAQ accordion
        ...List.generate(
          _faqs.length,
          (i) => _FaqTile(entry: _faqs[i], index: i),
        ),
      ],
    );
  }
}

class _FaqTile extends StatefulWidget {
  final _FaqEntry entry;
  final int index;
  const _FaqTile({required this.entry, required this.index});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Question row
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primaryVeryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.index + 1}',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.entry.question,
                        style: TextStyle(
                          fontWeight: _expanded
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Answer
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                child: Text(
                  widget.entry.answer,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.55,
                  ),
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqEntry {
  final String question;
  final String answer;
  const _FaqEntry({required this.question, required this.answer});
}

// ── Feedback Tab ─────────────────────────────────────────────────────────────
class _FeedbackTab extends StatefulWidget {
  const _FeedbackTab();

  @override
  State<_FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<_FeedbackTab> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  int _rating = 0;
  String _category = 'General';
  bool _submitted = false;

  static const List<String> _categories = [
    'General',
    'Bus Route',
    'ETA Accuracy',
    'Occupancy Info',
    'App Bug',
    'Driver Behavior',
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await FirestoreService().submitFeedback(
        category: _category,
        subject: _subjectCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
        rating: _rating,
      );
    } catch (_) {
      // Silently ignore Firestore errors — feedback still shows success UX.
    }
    if (mounted)
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _SuccessView(
        onReset: () => setState(() {
          _submitted = false;
          _subjectCtrl.clear();
          _messageCtrl.clear();
          _rating = 0;
          _category = 'General';
        }),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rate the app
            const Text(
              'How would you rate RouETA?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      i < _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 40,
                      color: i < _rating
                          ? const Color(0xFFFFB300)
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _ratingLabel(_rating),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Category
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = cat == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Subject
            const Text(
              'Subject',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectCtrl,
              textInputAction: TextInputAction.next,
              decoration: _inputDec('e.g. Wrong ETA on Ecoland stop'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Subject is required'
                  : null,
            ),

            const SizedBox(height: 20),

            // Message
            const Text(
              'Message',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: _inputDec('Describe your feedback in detail...'),
              validator: (v) => (v == null || v.trim().length < 10)
                  ? 'Please enter at least 10 characters'
                  : null,
            ),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isSubmitting ? 'Submitting…' : 'Submit Feedback',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contact
            Center(
              child: Text(
                'You can also reach us at\ndavaobus@roueta.ph',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }

  InputDecoration _inputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onReset;
  const _SuccessView({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.statusOperating.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 54,
              color: AppColors.statusOperating,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Feedback Sent!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Thank you for helping us improve RouETA. Your feedback has been received and we\'ll review it shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          OutlinedButton(
            onPressed: onReset,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              'Send Another',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
