import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:detector_celular_app/features/analise_video/screens/tela_analise_video.dart';

class TelaAdicionarMomento extends StatefulWidget {
  final DocumentSnapshot? momentoParaEditar; // Recebe o momento para edição

  const TelaAdicionarMomento({super.key, this.momentoParaEditar});

  @override
  State<TelaAdicionarMomento> createState() => _EstadoTelaAdicionarMomento();
}

class _EstadoTelaAdicionarMomento extends State<TelaAdicionarMomento> {
  final _formKey = GlobalKey<FormState>();
  final _salaController = TextEditingController();
  final _dataController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  bool _estaSalvando = false;
  bool get _modoEdicao => widget.momentoParaEditar != null;

  // Lista de cores para o card
  final List<Color> _coresDisponiveis = [
    Colors.blue.shade700, Colors.orange.shade700, Colors.deepPurple.shade700,
    Colors.green.shade700, Colors.red.shade700, Colors.teal.shade700,
  ];
  int _corSelecionada = Colors.blue.shade700.value;

  @override
  void initState() {
    super.initState();
    if (_modoEdicao) {
      final dados = widget.momentoParaEditar!.data() as Map<String, dynamic>;
      _salaController.text = dados['sala'] ?? '';
      _dataController.text = dados['data'] ?? '';
      _descricaoController.text = dados['descricao'] ?? '';
      _corSelecionada = dados['cor'] ?? _coresDisponiveis[0].value;
    }
  }

  @override
  void dispose() {
    _salaController.dispose();
    _dataController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100),
    );
    if (dataSelecionada != null) {
      setState(() {
        _dataController.text = '${dataSelecionada.day.toString().padLeft(2, '0')}/${dataSelecionada.month.toString().padLeft(2, '0')}/${dataSelecionada.year}';
      });
    }
  }

  Future<void> _salvarMomento() async {
    if (_formKey.currentState!.validate() && !_estaSalvando) {
      setState(() { _estaSalvando = true; });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: Usuário não autenticado.')));
        setState(() { _estaSalvando = false; });
        return;
      }

      final dadosMomento = {
        'sala': _salaController.text,
        'data': _dataController.text,
        'descricao': _descricaoController.text,
        'cor': _corSelecionada, // Salva o valor da cor
        'userId': user.uid,
      };

      try {
        if (_modoEdicao) {
          // ATUALIZA um momento existente
          await FirebaseFirestore.instance.collection('momentos').doc(widget.momentoParaEditar!.id).update(dadosMomento);
          if (mounted) Navigator.of(context).pop(); // Volta para o dashboard
        } else {
          // CRIA um novo momento
          dadosMomento['dataCriacao'] = FieldValue.serverTimestamp();
          dadosMomento['status'] = 'Pendente';
          dadosMomento['imagensDetectadas'] = [];
          
          DocumentReference docRef = await FirebaseFirestore.instance.collection('momentos').add(dadosMomento);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TelaAnaliseVideo(
                momentoId: docRef.id,
                tituloMomento: '${_salaController.text} - ${_descricaoController.text}',
              )),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
        setState(() { _estaSalvando = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modoEdicao ? 'Editar Momento' : 'Adicionar Momento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _salaController, decoration: const InputDecoration(labelText: 'Sala', prefixIcon: Icon(Icons.meeting_room)), validator: (v) => v!.isEmpty ? 'Insira a sala.' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _dataController, decoration: InputDecoration(labelText: 'Data', prefixIcon: const Icon(Icons.calendar_today), suffixIcon: IconButton(icon: const Icon(Icons.calendar_month), onPressed: _selecionarData)), readOnly: true, validator: (v) => v!.isEmpty ? 'Selecione a data.' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _descricaoController, decoration: const InputDecoration(labelText: 'Descrição', prefixIcon: Icon(Icons.description)), maxLines: 3, validator: (v) => v!.isEmpty ? 'Insira a descrição.' : null),
              const SizedBox(height: 24),
              
              // Seletor de Cores
              const Text('Cor do Card:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _coresDisponiveis.map((cor) {
                  return InkWell(
                    onTap: () => setState(() => _corSelecionada = cor.value),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: cor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _corSelecionada == cor.value ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),
              if (_estaSalvando)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  icon: Icon(_modoEdicao ? Icons.save : Icons.video_library_outlined),
                  onPressed: _salvarMomento,
                  label: Text(_modoEdicao ? 'Salvar Alterações' : 'Salvar e Analisar Vídeo'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}