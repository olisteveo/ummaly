import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ummaly/features/pillars/pillar_content_service.dart';
import 'package:ummaly/features/pillars/widgets/daily_cards.dart';
import 'package:url_launcher/url_launcher.dart';

class ZakatTab extends StatefulWidget {
  const ZakatTab({super.key});

  @override
  State<ZakatTab> createState() => _ZakatTabState();
}

class _ZakatTabState extends State<ZakatTab>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF2E7D32);
  static const _accentLight = Color(0xFF43A047);
  static const _darkBg = Color(0xFF0F1A2E);
  static const _gold = Color(0xFFD4A574);

  // Calculator controllers
  final _cashController = TextEditingController();
  final _goldController = TextEditingController();
  final _silverController = TextEditingController();
  final _investmentsController = TextEditingController();
  final _propertyController = TextEditingController();
  final _businessController = TextEditingController();
  final _debtsController = TextEditingController();

  bool _showCalculator = false;
  bool _showResult = false;
  double _totalWealth = 0;
  double _zakatDue = 0;

  // Nisab thresholds (approx current values in GBP)
  // Gold: ~85g × £55/g ≈ £4,675 | Silver: ~612g × £0.60/g ≈ £367
  // Most scholars recommend using the lower (silver) nisab to be safe
  static const double _nisabGold = 4675.0;
  static const double _nisabSilver = 367.0;
  bool _useGoldNisab = false; // default to silver (more inclusive)

  late AnimationController _resultAnimController;
  late Animation<double> _resultAnim;

  @override
  void initState() {
    super.initState();
    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resultAnim = CurvedAnimation(
      parent: _resultAnimController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    _goldController.dispose();
    _silverController.dispose();
    _investmentsController.dispose();
    _propertyController.dispose();
    _businessController.dispose();
    _debtsController.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  void _calculateZakat() {
    final cash = double.tryParse(_cashController.text) ?? 0;
    final gold = double.tryParse(_goldController.text) ?? 0;
    final silver = double.tryParse(_silverController.text) ?? 0;
    final investments = double.tryParse(_investmentsController.text) ?? 0;
    final property = double.tryParse(_propertyController.text) ?? 0;
    final business = double.tryParse(_businessController.text) ?? 0;
    final debts = double.tryParse(_debtsController.text) ?? 0;

    setState(() {
      _totalWealth =
          cash + gold + silver + investments + property + business - debts;
      if (_totalWealth < 0) _totalWealth = 0;
      _zakatDue = _totalWealth * 0.025;
      _showResult = true;
    });

    _resultAnimController.forward(from: 0);
  }

  void _resetCalculator() {
    _cashController.clear();
    _goldController.clear();
    _silverController.clear();
    _investmentsController.clear();
    _propertyController.clear();
    _businessController.clear();
    _debtsController.clear();
    setState(() {
      _showResult = false;
      _totalWealth = 0;
      _zakatDue = 0;
    });
  }

  double get _nisab => _useGoldNisab ? _nisabGold : _nisabSilver;
  bool get _meetsNisab => _totalWealth >= _nisab;

  @override
  Widget build(BuildContext context) {
    final svc = PillarContentService.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          // ── Dynamic daily content ──
          DailyWisdomCard(accent: _accent),
          const SizedBox(height: 16),
          DidYouKnowCard(accent: _accent, fact: svc.zakatFact()),
          const SizedBox(height: 16),
          DailyReflectionCard(accent: _accent, prompt: svc.zakatReflection()),
          const SizedBox(height: 24),

          // Header card
          _buildHeaderCard(),
          const SizedBox(height: 24),

          // About Zakat
          _buildInfoCard(
            title: 'What is Zakat?',
            body:
                'Zakat is the third pillar of Islam. It is an obligatory act of '
                'worship that requires every eligible Muslim to donate a portion '
                'of their wealth (typically 2.5% of savings) to those in need.\n\n'
                'Zakat purifies the soul from greed and attachment to material '
                'possessions, while helping to reduce inequality and support '
                'the most vulnerable in society.',
          ),
          const SizedBox(height: 16),

          // ── Zakat Calculator ──
          _buildCalculatorCard(),
          const SizedBox(height: 24),

          // Donation causes header
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Donate to a Cause',
              style: TextStyle(
                color: _accent,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),

          _buildDonationCard(
            title: 'Donate to Gaza',
            subtitle: 'Emergency humanitarian relief',
            description:
                'Support families in Gaza with food, medicine, shelter, '
                'and essential supplies during this time of great need.',
            icon: Icons.favorite,
            url: 'https://www.islamic-relief.org.uk/giving/appeals/palestine/',
          ),
          const SizedBox(height: 12),
          _buildDonationCard(
            title: 'Donate to Sudan',
            subtitle: 'Crisis relief and recovery',
            description:
                'Help displaced Sudanese families with clean water, food, '
                'medical care, and temporary shelter.',
            icon: Icons.handshake,
            url: 'https://www.islamic-relief.org.uk/giving/appeals/sudan-emergency-appeal/',
          ),
          const SizedBox(height: 12),
          _buildDonationCard(
            title: 'Sadaqah Jariyah',
            subtitle: 'Ongoing charitable giving',
            description:
                'Contribute to projects that provide lasting benefit: wells, '
                'schools, mosques, and orphan sponsorship.',
            icon: Icons.water_drop,
            url: 'https://www.islamic-relief.org.uk/giving/sadaqah-jariyah/',
          ),
          const SizedBox(height: 24),

          // Nisab info
          _buildInfoCard(
            title: 'Understanding Nisab',
            body:
                'Nisab is the minimum threshold of wealth a Muslim must possess '
                'before Zakat becomes obligatory. It is calculated based on the '
                'current value of:\n\n'
                '• Gold Nisab: 87.48g of gold (~£4,675)\n'
                '• Silver Nisab: 612.36g of silver (~£367)\n\n'
                'Most scholars recommend using the silver nisab (the lower value) '
                'to be more inclusive and benefit more people.\n\n'
                'If your total qualifying assets exceed the Nisab threshold for '
                'a full lunar year (hawl), you pay 2.5% as Zakat.',
          ),

          const SizedBox(height: 16),

          // 8 recipients info
          _buildInfoCard(
            title: 'Who Receives Zakat?',
            body:
                'The Quran (9:60) specifies eight categories:\n\n'
                '1. Al-Fuqara — The poor\n'
                '2. Al-Masakin — The needy\n'
                '3. Al-Amilina Alayha — Zakat administrators\n'
                '4. Al-Mu\'allafati Qulubuhum — New Muslims & allies\n'
                '5. Fir-Riqab — Freeing captives\n'
                '6. Al-Gharimin — Those in debt\n'
                '7. Fi Sabilillah — In the cause of Allah\n'
                '8. Ibn as-Sabil — Stranded travelers',
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _darkBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accent.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Icon(Icons.volunteer_activism, size: 48, color: _accent),
          const SizedBox(height: 12),
          Text(
            'الزكاة',
            style: TextStyle(
              color: _accent,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ZAKAT',
            style: TextStyle(
              color: _accent.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Obligatory Charitable Giving',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withValues(alpha: 0.2)),
            ),
            child: Text(
              '"Take from their wealth a charity by which you purify '
              'them and cause them increase."\n— Quran 9:103',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _darkBg.withValues(alpha: 0.7),
            _darkBg.withValues(alpha: 0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Calculator header — always visible, tappable to expand
          GestureDetector(
            onTap: () => setState(() => _showCalculator = !_showCalculator),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, _accentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: _showCalculator
                    ? const BorderRadius.vertical(top: Radius.circular(19))
                    : BorderRadius.circular(19),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.calculate_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Zakat Calculator',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _showCalculator
                              ? 'Enter your assets below'
                              : 'Tap to calculate your Zakat',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showCalculator ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Calculator body — expandable
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: _buildCalculatorBody(),
            crossFadeState: _showCalculator
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nisab toggle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: _accent.withValues(alpha: 0.6), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Using ${_useGoldNisab ? "Gold" : "Silver"} Nisab: £${_nisab.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _useGoldNisab = !_useGoldNisab),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Switch',
                      style: TextStyle(
                          color: _accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Asset input fields ──
          Text(
            'YOUR ASSETS',
            style: TextStyle(
              color: _accent.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),

          _buildInputField(
            controller: _cashController,
            label: 'Cash & Bank Savings',
            icon: Icons.account_balance_wallet_outlined,
            hint: 'Total cash in all accounts',
          ),
          const SizedBox(height: 10),
          _buildInputField(
            controller: _goldController,
            label: 'Gold (value in £)',
            icon: Icons.diamond_outlined,
            hint: 'Market value of gold owned',
          ),
          const SizedBox(height: 10),
          _buildInputField(
            controller: _silverController,
            label: 'Silver (value in £)',
            icon: Icons.circle_outlined,
            hint: 'Market value of silver owned',
          ),
          const SizedBox(height: 10),
          _buildInputField(
            controller: _investmentsController,
            label: 'Investments & Stocks',
            icon: Icons.trending_up_rounded,
            hint: 'Shares, ISAs, crypto, etc.',
          ),
          const SizedBox(height: 10),
          _buildInputField(
            controller: _propertyController,
            label: 'Rental/Investment Property',
            icon: Icons.home_work_outlined,
            hint: 'Only property bought to sell/rent',
          ),
          const SizedBox(height: 10),
          _buildInputField(
            controller: _businessController,
            label: 'Business Assets & Stock',
            icon: Icons.store_outlined,
            hint: 'Trade goods, inventory value',
          ),

          const SizedBox(height: 20),
          Text(
            'DEDUCTIONS',
            style: TextStyle(
              color: Colors.red.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _debtsController,
            label: 'Outstanding Debts',
            icon: Icons.remove_circle_outline,
            hint: 'Loans, credit cards, mortgages due',
            isDeduction: true,
          ),

          const SizedBox(height: 24),

          // Calculate button
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _calculateZakat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accent, _accentLight],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calculate_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Calculate Zakat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showResult) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _resetCalculator,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Icon(Icons.refresh_rounded,
                        color: Colors.white.withValues(alpha: 0.6), size: 20),
                  ),
                ),
              ],
            ],
          ),

          // ── Result card ──
          if (_showResult) ...[
            const SizedBox(height: 20),
            ScaleTransition(
              scale: _resultAnim,
              child: _buildResultCard(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isDeduction = false,
  }) {
    final fieldColor = isDeduction
        ? Colors.red.withValues(alpha: 0.15)
        : _accent.withValues(alpha: 0.08);
    final borderColor = isDeduction
        ? Colors.red.withValues(alpha: 0.2)
        : _accent.withValues(alpha: 0.15);
    final iconColor = isDeduction
        ? Colors.red.withValues(alpha: 0.6)
        : _accent.withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: label,
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 12,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                prefixText: '£ ',
                prefixStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _meetsNisab
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [const Color(0xFF37474F), const Color(0xFF455A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (_meetsNisab ? _accent : Colors.grey)
                .withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _meetsNisab
                  ? Icons.volunteer_activism
                  : Icons.check_circle_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),

          // Total wealth
          Text(
            'Total Zakatable Wealth',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '£${_totalWealth.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nisab threshold: £${_nisab.toStringAsFixed(0)} (${_useGoldNisab ? "Gold" : "Silver"})',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 20),

          if (_meetsNisab) ...[
            Text(
              'YOUR ZAKAT DUE (2.5%)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '£${_zakatDue.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome,
                      color: _gold, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'May Allah accept your Zakat',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This is an estimate. Consult a scholar for specific rulings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ] else ...[
            Icon(
              Icons.check_circle_outline,
              color: Colors.white.withValues(alpha: 0.5),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Below Nisab Threshold',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your total wealth (£${_totalWealth.toStringAsFixed(2)}) is below '
              'the ${_useGoldNisab ? "gold" : "silver"} nisab of £${_nisab.toStringAsFixed(0)}. '
              'Zakat is not obligatory on you at this time.\n\n'
              'You can still give voluntary sadaqah (charity) for additional reward.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String body}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _darkBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _accent,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required String url,
  }) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _darkBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accent, _accentLight],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Donate Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
