import 'package:flutter/material.dart';
import '../models/domicilio.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORES
// ─────────────────────────────────────────────────────────────────────────────
class _K {
  static const Color bg = Color(0xFFF0F4F8);
  static const Color white = Colors.white;
  static const Color textDark = Color(0xFF111827);
  static const Color textGray = Color(0xFF6B7280);
  static const Color textBlue = Color(0xFF2563EB);
  static const Color borderGray = Color(0xFFE5E7EB);
  static const Color borderBlue = Color(0xFFBFDBFE);
  static const Color cardBlueBg = Color(0xFFEFF6FF);
  static const Color iconGray = Color(0xFF6B7280);
  static const Color btnBorder = Color(0xFFD1D5DB);
  static const Color btnText = Color(0xFF374151);
}

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA
// ─────────────────────────────────────────────────────────────────────────────
class GestionDomicilioScreen extends StatefulWidget {
  const GestionDomicilioScreen({super.key});

  @override
  State<GestionDomicilioScreen> createState() => _GestionDomicilioScreenState();
}

class _GestionDomicilioScreenState extends State<GestionDomicilioScreen> {
  final Domicilio _domicilio = Domicilio(
    direccion: 'Av. Libertador 1234, Depto 5B, Las Condes, Santiago',
    depto: 'Depto 5B',
    casaInterior: 'A',
    comuna: 'Las Condes',
    latitud: -33.4489,
    longitud: -70.6693,
    tiempoResidencia: 3,
    tipoVivienda: 'Departamento',
    estadoVivienda: 'Bueno',
    materialConstruccion: 'Hormigón/Concreto',
    instruccionesEspeciales: 'Llave de emergencia con portero.',
  );

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
                  // ── Encabezado ─────────────────────────────────────────
                  _buildHeader(),
                  _divider(),

                  // ── Dirección ──────────────────────────────────────────
                  _buildDireccionSection(),
                  const SizedBox(height: 8),

                  // ── Detalles vivienda ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildDetallesCard(),
                  ),

                  // ── Instrucciones especiales ───────────────────────────
                  _divider(),
                  _buildInstruccionesSection(),
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
          const Icon(Icons.home_outlined, size: 20, color: _K.textDark),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Información del Domicilio',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _K.textDark,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Revisa y actualiza los datos de tu domicilio',
                style: TextStyle(fontSize: 12.5, color: _K.textGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sección Dirección ──────────────────────────────────────────────────────
  Widget _buildDireccionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + Editar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dirección',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _K.textDark,
                ),
              ),
              _editarButton(),
            ],
          ),
          const SizedBox(height: 10),

          // Dirección
          Text(
            _domicilio.direccion,
            style: const TextStyle(fontSize: 13.5, color: _K.textDark),
          ),
          const SizedBox(height: 3),
          Text(
            'Casa interior: ${_domicilio.casaInterior}',
            style: const TextStyle(fontSize: 13, color: _K.textGray),
          ),
          const SizedBox(height: 12),

          // Tarjeta Información de ubicación
          _buildUbicacionCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUbicacionCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _K.white,
        border: Border.all(color: _K.borderGray),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label superior con ícono
          Row(
            children: const [
              Icon(Icons.location_on_outlined, size: 15, color: _K.iconGray),
              SizedBox(width: 6),
              Text(
                'Información de ubicación',
                style: TextStyle(fontSize: 13, color: _K.textGray),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _latLonRow('Latitud:', _domicilio.latitud.toStringAsFixed(4)),
          const SizedBox(height: 5),
          _latLonRow('Longitud:', _domicilio.longitud.toStringAsFixed(4)),
          const SizedBox(height: 5),
          _latLonRow('Comuna:', _domicilio.comuna),
        ],
      ),
    );
  }

  Widget _latLonRow(String label, String value) {
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

  // ── Tarjeta Detalles de la Vivienda ────────────────────────────────────────
  Widget _buildDetallesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _K.cardBlueBg,
        border: Border.all(color: _K.borderBlue),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + Editar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detalles de la Vivienda',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _K.textBlue,
                ),
              ),
              _editarButton(),
            ],
          ),
          const SizedBox(height: 14),
          _detalleItem('Tiempo en la residencia',
              '${_domicilio.tiempoResidencia} meses'),
          const SizedBox(height: 12),
          _detalleItem('Tipo de vivienda', _domicilio.tipoVivienda),
          const SizedBox(height: 12),
          _detalleItem('Estado de la vivienda', _domicilio.estadoVivienda),
          const SizedBox(height: 12),
          _detalleItem(
              'Material del departamento', _domicilio.materialConstruccion),
        ],
      ),
    );
  }

  Widget _detalleItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _K.textDark)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 13.5, color: _K.textGray)),
      ],
    );
  }

  // ── Instrucciones especiales ───────────────────────────────────────────────
  Widget _buildInstruccionesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instrucciones especiales',
            style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: _K.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            _domicilio.instruccionesEspeciales,
            style: const TextStyle(fontSize: 13.5, color: _K.textGray),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _editarButton() {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.edit_outlined, size: 13),
      label:
          const Text('Editar', style: TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _K.btnText,
        side: const BorderSide(color: _K.btnBorder),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: _K.borderGray);
}
