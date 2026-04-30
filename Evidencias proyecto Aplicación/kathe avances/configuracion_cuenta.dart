import 'package:flutter/material.dart';
import '../models/usuario_cuenta.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORES
// ─────────────────────────────────────────────────────────────────────────────
class _K {
  static const Color bg = Color(0xFFF0F4F8);
  static const Color white = Colors.white;
  static const Color textDark = Color(0xFF111827);
  static const Color textGray = Color(0xFF6B7280);
  static const Color textBlue = Color(0xFF2563EB);
  static const Color textOrange = Color(0xFFEA580C);
  static const Color borderGray = Color(0xFFE5E7EB);
  static const Color borderBlue = Color(0xFFBFDBFE);
  static const Color borderOrange = Color(0xFFFED7AA);
  static const Color cardBlueBg = Color(0xFFEFF6FF);
  static const Color cardOrangeBg = Color(0xFFFFF7ED);
  static const Color btnLogoutBorder = Color(0xFFFCA5A5);
  static const Color btnLogoutText = Color(0xFFDC2626);
  static const Color btnGrayBorder = Color(0xFFD1D5DB);
  static const Color btnGrayText = Color(0xFF374151);
  static const Color btnOrangeBg = Color(0xFFFB923C);
  static const Color dropdownBorder = Color(0xFFE5E7EB);
  static const Color iconWarningBlue = Color(0xFF3B82F6);
  static const Color iconWarningOrange = Color(0xFFF97316);
}

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA
// ─────────────────────────────────────────────────────────────────────────────
class ConfiguracionCuentaScreen extends StatefulWidget {
  const ConfiguracionCuentaScreen({super.key});

  @override
  State<ConfiguracionCuentaScreen> createState() =>
      _ConfiguracionCuentaScreenState();
}

class _ConfiguracionCuentaScreenState
    extends State<ConfiguracionCuentaScreen> {
  final UsuarioCuenta _usuario = const UsuarioCuenta(
    rut: '12.345.678-9',
    email: 'maria@email.com',
    edad: 47,
    aniaNacimiento: 1979,
    telefono: '+56 9 1234 5678',
  );

  int _tiempoResidencia = 3; // valor actual guardado
  int _tiempoSeleccionado = 3; // valor en el dropdown (antes de guardar)
  bool _dropdownOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _K.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: _K.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _divider(),

                  // Información personal
                  _buildInfoPersonalSection(),
                  _divider(),

                  // Tiempo en la residencia
                  _buildTiempoResidenciaSection(),
                  _divider(),

                  // Gestión de Cuenta
                  _buildGestionCuentaSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Encabezado ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: [
          const Icon(Icons.settings_outlined, size: 20, color: Color(0xFF374151)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Configuración de cuenta',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _K.textDark,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Gestiona tu cuenta y preferencias',
                style: TextStyle(fontSize: 12.5, color: _K.textGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Información Personal ───────────────────────────────────────────────────
  Widget _buildInfoPersonalSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información personal',
            style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: _K.textDark),
          ),
          const SizedBox(height: 10),

          // Card con los datos
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _K.white,
              border: Border.all(color: _K.borderGray),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('RUT:', _usuario.rut),
                const SizedBox(height: 7),
                _infoRow('Email:', _usuario.email),
                const SizedBox(height: 7),
                _infoRow('Edad:',
                    '${_usuario.edad} años (${_usuario.aniaNacimiento})'),
                const SizedBox(height: 7),
                _infoRow('Teléfono:', _usuario.telefono),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Botones: Editar teléfono + Cerrar sesión
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone_outlined, size: 15),
                label: const Text('Editar número de teléfono',
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _K.btnGrayText,
                  side: const BorderSide(color: _K.btnGrayBorder),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: _K.btnLogoutText,
                  side: const BorderSide(color: _K.btnLogoutBorder),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Cerrar sesión',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13.5, color: _K.textDark),
        children: [
          TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: ' $value'),
        ],
      ),
    );
  }

  // ── Tiempo en la Residencia ────────────────────────────────────────────────
  Widget _buildTiempoResidenciaSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiempo en la residencia',
            style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: _K.textDark),
          ),
          const SizedBox(height: 12),

          // Card azul con advertencia + dropdown
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _K.cardBlueBg,
              border: Border.all(color: _K.borderBlue),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Advertencia
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: _K.iconWarningBlue),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Cuando el tiempo en la residencia se agota, automáticamente se desvincula el grupo familiar de la residencia.',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: _K.textBlue,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Label
                const Text(
                  'Actualizar tiempo de permanencia',
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _K.textDark),
                ),
                const SizedBox(height: 8),

                // Selector custom (abre lista inline)
                _buildDropdownSelector(),

                // "Tiempo actual: X meses" — visible cuando el dropdown está cerrado
                if (!_dropdownOpen) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tiempo actual: $_tiempoResidencia meses',
                    style: const TextStyle(
                        fontSize: 12.5, color: _K.textBlue),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSelector() {
    return Column(
      children: [
        // Fila principal (selector cerrado)
        GestureDetector(
          onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _K.white,
              border: Border.all(color: _K.dropdownBorder),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(6),
                topRight: const Radius.circular(6),
                bottomLeft:
                    Radius.circular(_dropdownOpen ? 0 : 6),
                bottomRight:
                    Radius.circular(_dropdownOpen ? 0 : 6),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$_tiempoSeleccionado meses',
                    style: const TextStyle(
                        fontSize: 13.5, color: _K.textDark),
                  ),
                ),
                Icon(
                  _dropdownOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: _K.textGray,
                ),
              ],
            ),
          ),
        ),

        // Lista desplegable (visible cuando _dropdownOpen == true)
        if (_dropdownOpen)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _K.white,
              border: Border(
                left: BorderSide(color: _K.dropdownBorder),
                right: BorderSide(color: _K.dropdownBorder),
                bottom: BorderSide(color: _K.dropdownBorder),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: List.generate(6, (i) => i + 1).map((mes) {
                final isSelected = mes == _tiempoSeleccionado;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _tiempoSeleccionado = mes;
                      _tiempoResidencia = mes;
                      _dropdownOpen = false;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$mes ${mes == 1 ? 'mes' : 'meses'}',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: _K.textDark,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check,
                              size: 17, color: _K.textDark),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ── Gestión de Cuenta ──────────────────────────────────────────────────────
  Widget _buildGestionCuentaSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestión de Cuenta',
            style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: _K.textDark),
          ),
          const SizedBox(height: 12),

          // Card naranja — Desvincular domicilio
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _K.cardOrangeBg,
              border: Border.all(color: _K.borderOrange),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título con ícono
                Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded,
                        size: 17, color: _K.iconWarningOrange),
                    SizedBox(width: 6),
                    Text(
                      'Desvincular domicilio',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _K.textOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Si te has mudado o necesitas cambiar tu domicilio registrado, puedes desvincularte y registrar un nuevo domicilio.',
                  style: TextStyle(
                      fontSize: 12.5, color: _K.textGray, height: 1.4),
                ),
                const SizedBox(height: 14),

                // Botón naranja
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.home_outlined,
                        size: 16, color: _K.textOrange),
                    label: const Text(
                      'Desvincular y cambiar domicilio',
                      style: TextStyle(
                          fontSize: 13.5,
                          color: _K.textOrange,
                          fontWeight: FontWeight.w500),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: _K.btnOrangeBg, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB));
}
