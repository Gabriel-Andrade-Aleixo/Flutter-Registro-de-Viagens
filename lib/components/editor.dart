import 'package:flutter/material.dart';

class Editor extends StatelessWidget {
  final TextEditingController? controlador;
  final String? rotulo;
  final String? dica;
  final IconData? icone;
  final TextInputType? teclado;
  final bool readOnly;
  final VoidCallback? onTap;

  const Editor({
    super.key,
    this.controlador,
    this.rotulo,
    this.dica,
    this.icone,
    this.teclado,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        prefixIcon: icone != null ? Icon(icone) : null,
        labelText: rotulo,
        hintText: dica,
        suffixIcon: readOnly ? const Icon(Icons.expand_more) : null,
      ),
      keyboardType: teclado,
    );
  }
}
