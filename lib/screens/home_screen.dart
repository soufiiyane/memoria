import 'package:flutter/material.dart';
import 'home_screen2.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF0D243D),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Image(
                  image: AssetImage("assets/c1.png"),
                  width: 241,
                  height: 257,
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(
                width: 296,
                child: Text(
                  'Commençons ton parcours\n d\'apprentissage amusant et\n facile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.41,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 319,
                child: Text(
                  'Oublie les cours ennuyeux avec l\'application Flash Card\n'
                  'tu peux apprendre n\'importe quel sujet que tu souhaites',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0x80FFFFFF),
                    fontSize: 10,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.41,
                  ),
                ),
              ),
              const SizedBox(height: 150),
              // Points de navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/degree (1).png"),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/degree (2).png"),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/degree (3).png"),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomeScreen2()),
                  );
                },
                child: Container(
                  width: 299,
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E82DB),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Lance-toi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
