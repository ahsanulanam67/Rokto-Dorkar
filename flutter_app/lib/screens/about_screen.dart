import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_state.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.volunteer_activism, size: 62),
              const SizedBox(height: 12),
              Text(
                'Our mission',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Connecting blood donors with recipients in emergencies to save lives across Bangladesh.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      const _AboutTile(
        icon: Icons.search,
        title: 'Search donors',
        text: 'Find eligible donors by blood group, location, or a distance radius you choose.',
      ),
      const _AboutTile(
        icon: Icons.phone,
        title: 'Connect quickly',
        text: 'Call an available donor directly when every minute matters.',
      ),
      const _AboutTile(
        icon: Icons.history,
        title: 'Donation transparency',
        text: 'See the last donation date and current eligibility status.',
      ),
      const _AboutTile(
        icon: Icons.emergency,
        title: 'Live requests',
        text: 'Post urgent blood needs and mark them fulfilled when help arrives.',
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => launchUrl(
          Uri.parse('https://ahsanulanam-saboj.vercel.app/'),
          mode: LaunchMode.externalApplication,
        ),
        icon: const Icon(Icons.code),
        label: const Text('Developed by Ahsanul Anam Saboj'),
      ),
      TextButton.icon(
        onPressed: () => context.read<AuthState>().logout(),
        icon: const Icon(Icons.logout),
        label: const Text('Log out'),
      ),
    ],
  );
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text),
      ),
    ),
  );
}
