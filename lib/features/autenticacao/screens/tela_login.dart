import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import 'package:detector_celular_app/features/dashboard/screens/tela_dashboard.dart'; 
import 'package:detector_celular_app/features/autenticacao/screens/tela_cadastro.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _EstadoTelaLogin();
}

class _EstadoTelaLogin extends State<TelaLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();
  bool _estaCarregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    setState(() {
      _estaCarregando = true;
    });
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );
      _logger.i('Login bem-sucedido!');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TelaDashboard()), 
        );
      }
    } on FirebaseAuthException catch (e) {
      _logger.e('Erro de login: ${e.code} - ${e.message}');
      String mensagemErro;
      if (e.code == 'user-not-found') {
        mensagemErro = 'Nenhum usuário encontrado para esse e-mail.';
      } else if (e.code == 'wrong-password') {
        mensagemErro = 'Senha incorreta.';
      } else {
        mensagemErro = 'Erro de autenticação: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagemErro)));
      }
    } catch (e) {
      _logger.e('Erro inesperado durante o login: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ocorreu um erro inesperado.')));
      }
    } finally {
      setState(() {
        _estaCarregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _senhaController,
              decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock)),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _estaCarregando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _fazerLogin,
                    child: const Text('Entrar'),
                  ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaCadastro()),
                );
              },
              child: const Text('Não tem uma conta? Cadastre-se'),
            ),
          ],
        ),
      ),
    );
  }
}