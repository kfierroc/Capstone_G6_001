import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../login/login_screen.dart';
import '../registro/registro_models.dart';
import '../services/gestion_residente_service.dart';
import '../services/registro_residente_service.dart';
import '../widgets/custom_widgets.dart';

/// Configuración de cuenta con datos de `grupofamiliar`, auth y `registro_v`.
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

  static const List<String> _etiquetasMeses = [
    '1 mes',
    '2 meses',
    '3 meses',
    '4 meses',
    '5 meses',
    '6 meses',
    '1 año',
    'Más de 1 año',
  ];

  CuentaConfigVista? _cuenta;
  int? _idRegistro;
  bool _loading = true;
  String? _error;
  String? _sinGrupo;

  String _tiempoPermanenciaSeleccion = '3 meses';

  static int _mesesDesdeEtiqueta(String etiqueta) {
    switch (etiqueta) {
      case '1 mes':
        return 1;
      case '2 meses':
        return 2;
      case '3 meses':
        return 3;
      case '4 meses':
        return 4;
      case '5 meses':
        return 5;
      case '6 meses':
        return 6;
      case '1 año':
        return 12;
      case 'Más de 1 año':
        return 18;
      default:
        return 3;
    }
  }

  static String _etiquetaDesdeMeses(int meses) {
    final m = meses.clamp(1, 24);
    if (m <= 6) return m == 1 ? '1 mes' : '$m meses';
    if (m <= 12) return '1 año';
    return 'Más de 1 año';
  }

  static int _inferirMeses(DateTime? a, DateTime? b) {
    if (a == null || b == null) return 3;
    final au = DateTime(a.year, a.month, a.day);
    final bu = DateTime(b.year, b.month, b.day);
    var months = (bu.year - au.year) * 12 + (bu.month - au.month);
    if (bu.day < au.day) months--;
    return months.clamp(1, 24);
  }

  /// Muestra solo 9 dígitos si el teléfono cumple el formato +56.
  static String _telefonoParaCampo(String guardado) {
    if (guardado.startsWith('+56') && guardado.length >= 12) {
      return guardado.substring(3);
    }
    return guardado.replaceAll(RegExp(r'\s'), '');
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
      _sinGrupo = null;
    });
    final client = Supabase.instance.client;
    final ges = GestionResidenteService(client);
    try {
      final cuenta = await ges.obtenerCuentaConfig();
      final ctx = await ges.contextoResidente();
      if (!mounted) return;
      setState(() {
        _cuenta = cuenta;
        _idRegistro = ctx?.idRegistro;
        _sinGrupo = cuenta == null ? 'No hay datos de cuenta. Completa el registro inicial.' : null;
        if (cuenta != null && cuenta.fechaUltConfirm != null && cuenta.fechaExpiracion != null) {
          _tiempoPermanenciaSeleccion = _etiquetaDesdeMeses(
            _inferirMeses(cuenta.fechaUltConfirm, cuenta.fechaExpiracion),
          );
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _snack(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _editarTelefono() async {
    final cuenta = _cuenta;
    if (cuenta == null) return;
    final ctrl = TextEditingController(text: _telefonoParaCampo(cuenta.telefonoTitular));
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar teléfono', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa 9 dígitos (móvil Chile, empieza por 9). Se guardará como +56…',
              style: TextStyle(fontSize: 12, color: _textoGris),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '912345678'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final norm = normalizarTelefonoSufijoChile(ctrl.text.trim());
              if (norm == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Teléfono inválido. Debe ser móvil de 9 dígitos (9xxxxxxxx).')),
                );
                return;
              }
              try {
                await GestionResidenteService(Supabase.instance.client).actualizarTelefonoTitular(
                  idGrupof: cuenta.idGrupof,
                  telefonoNormalizado: norm,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _bootstrap();
                if (!mounted) return;
                _snack('Teléfono actualizado.');
              } on RegistroResidenteException catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(e.message)));
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Future<void> _cerrarSesion() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar tu sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  Future<void> _desvincularDomicilio() async {
    final idReg = _idRegistro;
    if (idReg == null) {
      _snack('No hay registro de vivienda vigente.');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desvincular domicilio'),
        content: const Text(
          'Se marcará tu registro de vivienda como no vigente y se cerrará la sesión. '
          'Para volver a usar la app deberás iniciar sesión y completar un nuevo registro si corresponde.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              try {
                await GestionResidenteService(Supabase.instance.client).marcarRegistroNoVigente(idReg);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await Supabase.instance.client.auth.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              } on RegistroResidenteException catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(e.message)));
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Confirmar', style: TextStyle(color: Color(0xFFEA580C))),
          ),
        ],
      ),
    );
  }

  Future<void> _onCambioPermanencia(String? v) async {
    if (v == null || _idRegistro == null) return;
    final meses = _mesesDesdeEtiqueta(v);
    try {
      await GestionResidenteService(Supabase.instance.client).renovarPermanenciaMeses(
        idRegistro: _idRegistro!,
        meses: meses,
      );
      setState(() => _tiempoPermanenciaSeleccion = v);
      await _bootstrap();
      if (!mounted) return;
      _snack('Tiempo de permanencia actualizado.');
    } on RegistroResidenteException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('No se pudo actualizar: $e');
    }
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

  String _textoEdad(CuentaConfigVista c) {
    final anio = c.anioNacTitular;
    if (anio == null) return '—';
    final edad = DateTime.now().year - anio;
    return '$edad años';
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 13)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _bootstrap,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    final cuenta = _cuenta;
    if (_sinGrupo != null || cuenta == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_sinGrupo ?? 'Sin datos.', textAlign: TextAlign.center, style: const TextStyle(color: _textoGris)),
        ),
      );
    }

    final rutTxt = formatearRutMostrar(cuenta.rutTitularNum, cuenta.rutDv);

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
                  border: Border.all(color: Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _filaDato('RUT', rutTxt),
                    _filaDato('Email', cuenta.email.isEmpty ? '—' : cuenta.email),
                    _filaDato('Edad', _textoEdad(cuenta)),
                    _filaDato('Teléfono', cuenta.telefonoTitular),
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
                      onPressed: _cerrarSesion,
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
                      // ignore: deprecated_member_use
                      value: _tiempoPermanenciaSeleccion,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _etiquetasMeses.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: _idRegistro == null ? null : _onCambioPermanencia,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selección actual: $_tiempoPermanenciaSeleccion',
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
                      'Si te mudas o dejas de vivir en esta dirección, puedes desvincular tu registro de vivienda. '
                      'Se cerrará tu sesión; los datos históricos permanecen en el sistema según las políticas del servicio.',
                      style: TextStyle(fontSize: 12, color: Colors.brown.shade700, height: 1.35),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _idRegistro == null ? null : _desvincularDomicilio,
                        icon: const Icon(Icons.home_outlined, color: _naranjaTitulo),
                        label: const Text(
                          'Desvincular y cerrar sesión',
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
