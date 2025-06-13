import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'tela_cadastro.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _EstadoTelaCadastro();
}

class _EstadoTelaCadastro extends State<TelaCadastro> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();
  bool _estaCarregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerCadastro() async {
    if (_senhaController.text.trim() != _confirmarSenhaController.text.trim()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('As senhas não coincidem.')));
      }
      return;
    }

    setState(() {
      _estaCarregando = true;
    });
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );
      _logger.i('Cadastro bem-sucedido!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastro realizado com sucesso! Faça login.')));
        Navigator.pop(context); // Volta para a tela de login
      }
    } on FirebaseAuthException catch (e) {
      _logger.e('Erro de cadastro: ${e.code} - ${e.message}');
      String mensagemErro;
      if (e.code == 'weak-password') {
        mensagemErro = 'A senha é muito fraca.';
      } else if (e.code == 'email-already-in-use') {
        mensagemErro = 'O e-mail já está em uso.';
      } else {
        mensagemErro = 'Erro de cadastro: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagemErro)));
      }
    } catch (e) {
      _logger.e('Erro inesperado durante o cadastro: $e');
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
      appBar: AppBar(title: const Text('Cadastro')),
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
            const SizedBox(height: 16),
            TextField(
              controller: _confirmarSenhaController,
              decoration: const InputDecoration(labelText: 'Confirmar Senha', prefixIcon: Icon(Icons.lock_reset)),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _estaCarregando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _fazerCadastro,
                    child: const Text('Cadastrar'),
                  ),
          ],
        ),
      ),
    );
  }
}