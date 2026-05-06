import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

/// Maqueta: configuración de cuenta del residente.
class GestionConfiguracionScreen extends StatefulWidget {
  const GestionConfiguracionScreen({super.key});

  @override
  State<GestionConfiguracionScreen> createState() => _GestionConfiguracionScreenState();
}

class _GestionConfiguracionScreenState extends State<GestionConfiguracionScreen> {
  static const _verdeApp = Color(0xFF00A84E);
  static const _fondoPagina = Color(0xFFF2F4F7);
  static const _textoPrincipal = Color(0xFF1A1A2E);
  static const _textoGris = Color(0xFF6B7280);
  static const _azulInfo = Color(0xFF2C5BA9);
  static const _azulFondo = Color(0xFFF0F7FF);
  static const _azulBorde = Color(0xFFD0E3FF);
  static const _naranjaTitulo = Color(0xFFC2410C);
  static const _naranjaFondo = Color(0xFFFFF7ED);
  static const _naranjaBorde = Color(0xFFFDBA74);
  static const _cardInfoBg = Color(0xFFF9FAFB);
  static const _navConfigBg = Color(0xFFF3F4F6);
  static const _navConfigBorder = Color(0xFFD1D5DB);
  static const _navConfig = Color(0xFF4B5563);

  final String _rut = '12.345.678-9';
  final String _email = 'titular@ejemplo.cl';
  final String _edad = '47 años';
  String _telefono = '+56 9 1234 5678';
  String _tiempoPermanencia = '3 meses';

  void _snack(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
    );
  }

  void _editarTelefono() {
    final ctrl = TextEditingController(text: _telefono);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar teléfono', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '+56 9 ...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              setState(() => _telefono = ctrl.text.trim());
              Navigator.pop(ctx);
              _snack('Teléfono actualizado (maqueta).');
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ).then((_) => ctrl.dispose());
  }

  void _cerrarSesionMaqueta() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Cerrar sesión? (solo maqueta, no borra datos reales).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _snack('En la app final aquí irías al login.');
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _desvincularMaqueta() {
    _snack('Maqueta: flujo de desvincular domicilio pendiente de backend.');
  }

  void _onNavTap(int i) {
    switch (i) {
      case 0:
        Navigator.pushReplacementNamed(context, '/gestion-familia');
      case 1:
        Navigator.pushReplacementNamed(context, '/gestion-mascotas');
      case 2:
        Navigator.pushReplacementNamed(context, '/gestion-domicilio');
      case 3:
        Navigator.pushReplacementNamed(context, '/gestion-peligrosos');
      case 4:
        break;
    }
  }

  Widget _filaDato(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(etiqueta, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textoGris)),
          ),
          Expanded(child: Text(valor, style: const TextStyle(fontSize: 14, color: _textoPrincipal))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondoPagina,
      body: Column(
        children: [
          CustomAppBar(
            title: 'Mi Información Familiar',
            subtitle: 'Gestiona la información de tu domicilio',
            showBack: true,
            onBack: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            trailing: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _snack('Acción de ejemplo (sin integración).'),
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.notifications_none_rounded, color: _verdeApp, size: 22),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    return ColoredBox(
      color: _fondoPagina,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.settings_outlined, size: 24, color: _textoPrincipal),
                  SizedBox(width: 8),
                  Text(
                    'Configuración de cuenta',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textoPrincipal),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Gestiona tu cuenta y preferencias',
                style: TextStyle(fontSize: 13, color: _textoGris),
              ),
              const SizedBox(height: 22),
              const Text(
                'Información personal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textoPrincipal),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardInfoBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _filaDato('RUT', _rut),
                    _filaDato('Email', _email),
                    _filaDato('Edad', _edad),
                    _filaDato('Teléfono', _telefono),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editarTelefono,
                      icon: const Icon(Icons.phone_outlined, size: 18),
                      label: const Text('Editar número de teléfono', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textoPrincipal,
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cerrarSesionMaqueta,
                      icon: const Icon(Icons.logout, size: 18, color: Color(0xFFEF4444)),
                      label: const Text('Cerrar sesión', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFFFCDD2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Tiempo en la residencia',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textoPrincipal),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _azulFondo,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _azulBorde),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 20, color: _azulInfo),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cuando el tiempo en la residencia se agota, el grupo familiar puede desvincularse del domicilio. Actualiza tu permanencia para mantener los datos al día.',
                            style: TextStyle(fontSize: 12, color: _azulInfo, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Actualizar tiempo de permanencia',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _textoPrincipal),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _tiempoPermanencia,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: ['1 mes', '2 meses', '3 meses', '4 meses', '5 meses', '6 meses', '1 año', 'Más de 1 año']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _tiempoPermanencia = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tiempo actual: $_tiempoPermanencia',
                      style: const TextStyle(fontSize: 12, color: _azulInfo),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Gestión de cuenta',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textoPrincipal),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _naranjaFondo,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _naranjaBorde),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 22, color: _naranjaTitulo),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Desvincular domicilio',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _naranjaTitulo),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Si te mudas o dejas de vivir en esta dirección, puedes desvincular tu cuenta y registrar un nuevo domicilio. Esta acción debe confirmarse con el flujo oficial de la app.',
                      style: TextStyle(fontSize: 12, color: Colors.brown.shade700, height: 1.35),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _desvincularMaqueta,
                        icon: const Icon(Icons.home_outlined, color: _naranjaTitulo),
                        label: const Text(
                          'Desvincular y cambiar domicilio',
                          style: TextStyle(color: _naranjaTitulo, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _naranjaTitulo),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = <({IconData icon, IconData iconActive, String label})>[
      (icon: Icons.people_outline, iconActive: Icons.people, label: 'Familia'),
      (icon: Icons.favorite_border, iconActive: Icons.favorite, label: 'Mascotas'),
      (icon: Icons.home_outlined, iconActive: Icons.home, label: 'Domicilio'),
      (icon: Icons.warning_amber_outlined, iconActive: Icons.warning_amber, label: 'Peligrosos'),
      (icon: Icons.settings_outlined, iconActive: Icons.settings, label: 'Configuración'),
    ];

    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final it = items[i];
              final selected = i == 4;
              return Expanded(
                child: InkWell(
                  onTap: () => _onNavTap(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? _navConfigBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? _navConfigBorder : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            selected ? it.iconActive : it.icon,
                            size: 24,
                            color: selected ? _navConfig : _textoGris,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          it.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected ? _navConfig : _textoGris,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
