import 'package:flutter/material.dart';
import 'tabs/shahadah_tab.dart';
import 'tabs/salah_tab.dart';
import 'tabs/zakat_tab.dart';
import 'tabs/sawm_tab.dart';
import 'tabs/hajj_tab.dart';

class PillarsDashboard extends StatelessWidget {
  const PillarsDashboard({super.key});

  static const _darkBg = Color(0xFF0F1A2E);
  static const _emerald = Color(0xFF115E59);
  static const _gold = Color(0xFFD4A574);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_darkBg, _emerald],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Column(
              children: [
                Text(
                  'The Five Pillars',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'of Islam',
                  style: TextStyle(
                    color: _gold.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicatorColor: _gold,
              indicatorWeight: 3.0,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: _gold,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: const [
                Tab(
                  icon: Icon(Icons.brightness_7, size: 22),
                  text: 'Shahadah',
                ),
                Tab(
                  icon: Icon(Icons.access_time_rounded, size: 22),
                  text: 'Salah',
                ),
                Tab(
                  icon: Icon(Icons.volunteer_activism, size: 22),
                  text: 'Zakat',
                ),
                Tab(
                  icon: Icon(Icons.restaurant_menu, size: 22),
                  text: 'Sawm',
                ),
                Tab(
                  icon: Icon(Icons.mosque, size: 22),
                  text: 'Hajj',
                ),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              ShahadahTab(),
              SalahTab(),
              ZakatTab(),
              SawmTab(),
              HajjTab(),
            ],
          ),
        ),
      ),
    );
  }
}
