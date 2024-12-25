import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:memoria/screens/login.dart';
import 'package:memoria/screens/password_reset.dart';
import 'package:memoria/screens/politique_conf.dart';
import 'package:memoria/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParametresPage extends StatefulWidget {
  const ParametresPage({Key? key}) : super(key: key);

  @override
  State<ParametresPage> createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage> {
  String email = '';
  bool modeHorsLigne = false;

  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final userInfo = await ApiService.getUserInfo();
    setState(() {
      email = userInfo['email'] ?? 'Pas d\'email trouvé';
      print('Email chargé: $email');
    });
  }

  Future<void> _logout() async {
    try {
      await ApiService.clearTokens();
      await SharedPreferences.getInstance().then((prefs) {
        prefs.clear();
      });

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => RegistrationScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la déconnexion')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D243D),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Paramètres',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0D243D),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSection('COMPTE'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoField('Email', email),
                _buildListTile(
                  'Changer le mot de passe',
                  Icons.lock_reset,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PasswordResetPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          _buildSection('SYNCHRONISATION'),
          ListTile(
            title: const Text(
              'Mode hors ligne',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              modeHorsLigne
                  ? 'Les données sont disponibles hors ligne'
                  : 'Synchronisation en temps réel activée',
              style: TextStyle(color: Colors.white70),
            ),
            leading: Icon(
              modeHorsLigne ? Icons.cloud_off : Icons.cloud_done,
              color: modeHorsLigne ? Colors.orange : Colors.green,
            ),
          ),
          const Divider(color: Colors.white24),
          _buildSection('ÉVALUATION'),
          _buildListTile(
            'Évaluer l\'application',
            Icons.star,
            Colors.yellow,
            _showRatingDialog,
          ),
          const Divider(color: Colors.white24),
          _buildSection('SESSION'),
          _buildListTile(
            'Déconnexion',
            Icons.logout,
            Colors.red,
            _showLogoutDialog,
            textColor: Colors.red,
          ),
          const Divider(color: Colors.white24),
          _buildSection('LÉGAL'),
          _buildListTile(
            'Politique de confidentialité',
            Icons.privacy_tip,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PolitiqueConfidentialitePage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const Divider(color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildListTile(
      String title, IconData icon, Color iconColor, VoidCallback onTap,
      {Color textColor = Colors.white}) {
    return ListTile(
      title: Text(title, style: TextStyle(color: textColor)),
      leading: Icon(icon, color: iconColor),
      onTap: onTap,
    );
  }

  void _showOfflineModeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E3551),
          title: const Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Mode Hors Ligne',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Le mode hors ligne vous permet de :',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '• Accéder à vos données sans connexion\n'
                '• Continuer à utiliser l\'application\n'
                '• Vos modifications seront synchronisées automatiquement lors de la reconnexion',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 15),
              Text(
                'Note : Certaines fonctionnalités peuvent être limitées en mode hors ligne.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Compris'),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mode hors ligne activé'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E3551),
        title: const Text(
          'Évaluer l\'application',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Aimez-vous notre application ?',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: const Icon(Icons.star, color: Colors.yellow),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Merci pour votre évaluation !'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E3551),
          title: const Text(
            'Déconnexion',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Déconnecter',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }
}
